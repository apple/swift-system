# IORing, a Swift System API for io_uring

* Proposal: [SE-NNNN](NNNN-filename.md)
* Authors: [Lucy Satheesan](https://github.com/oxy), [David Smith](https://github.com/Catfish-Man/)
* Review Manager: TBD
* Status: **Awaiting implementation**
* Implementation: [apple/swift-system#208](https://github.com/apple/swift-system/pull/208)

## Introduction

`io_uring` is Linux's solution to asynchronous and batched syscalls, with a particular focus on IO. We propose a low-level Swift API for it in Swift System that could either be used directly by projects with unusual needs, or via intermediaries like Swift NIO, to address scalability and thread pool starvation issues.

## Motivation

Up until recently, the overwhelmingly dominant file IO syscalls on major Unix platforms have been synchronous, e.g. `read(2)`. This design is very simple and proved sufficient for many uses for decades, but is less than ideal for Swift's needs in a few major ways:

1. Requiring an entire OS thread for each concurrent operation imposes significant memory overhead
2. Requiring a separate syscall for each operation imposes significant CPU/time overhead to switch into and out of kernel mode repeatedly. This has been exacerbated in recent years by mitigations for the Meltdown family of security exploits increasing the cost of syscalls.
3. Swift's N:M coroutine-on-thread-pool concurrency model assumes that threads will not be blocked. Each thread waiting for a syscall means a CPU core being left idle. In practice systems like NIO that deal in highly concurrent IO have had to work around this by providing their own thread pools.

Non-file IO (network, pipes, etc…) has been in a somewhat better place with `epoll` and `kqueue` for asynchronously waiting for readability, but syscall overhead remains a significant issue for highly scalable systems.

With the introduction of `io_uring` in 2019, Linux now has the kernel level tools to address these three problems directly. However, `io_uring` is quite complex and maps poorly into Swift. We expect that by providing a Swift interface to it, we can enable Swift on Linux servers to scale better and be more efficient than it has been in the past.

## Proposed solution

We propose a *low level, unopinionated* Swift interface for io_uring on Linux (see Future Directions for discussion of possible more abstract interfaces).

`struct IORing: ~Copyable` provides facilities for

* Registering and unregistering resources (files and buffers), an `io_uring` specific variation on Unix file descriptors that improves their efficiency
* Registering and unregistering eventfds, which allow asynchronous waiting for completions
* Enqueueing IO requests
* Dequeueing IO completions

`struct IOResource<T>` represents, via its two typealiases `IORingFileSlot` and `IORingBuffer`, registered file descriptors and buffers.

`struct IORequest: ~Copyable` represents an IO operation that can be enqueued for the kernel to execute. It supports a wide variety of operations matching traditional unix file and socket operations.

IORequest operations are expressed as overloaded static methods on `IORequest`, e.g. `openat` is spelled

```swift
    public static func open(
        _ path: FilePath,
        in directory: FileDescriptor,
        into slot: IORingFileSlot,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        context: UInt64 = 0
    ) -> IORequest

    public static func open(
        _ path: FilePath,
        in directory: FileDescriptor,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        context: UInt64 = 0
    ) -> IORequest
```

which allows clients to decide whether they want to open the file into a slot on the ring, or have it return a file descriptor via a completion. Similarly, read operations have overloads for "use a buffer from the ring" or "read into this `UnsafeMutableBufferPointer`"

Multiple `IORequests` can be enqueued on a single `IORing` using the `prepare(…)` family of methods, and then submitted together using `submitPreparedRequests`, allowing for things like "open this file, read its contents, and then close it" to be a single syscall. Conveniences are provided for preparing and submitting requests in one call.

Since IO operations can execute in parallel or out of order by default, linked chains of operations can be established with `prepare(linkedRequests:…)` and related methods. Separate chains can still execute in parallel, and if an operation early in the chain fails, all subsequent operations will deliver cancellation errors as their completion.

Already-completed results can be retrieved from the ring using `tryConsumeCompletion`, which never waits but may return nil, or `blockingConsumeCompletion(timeout:)`, which synchronously waits (up to an optional timeout) until an operation completes. There's also a bulk version of `blockingConsumeCompletion`, which may reduce the number of syscalls issued. It takes a closure which will be called repeatedly as completions are available (see Future Directions for potential improvements to this API).

Since neither polling nor synchronously waiting is optimal in many cases, `IORing` also exposes the ability to register an eventfd (see `man eventfd(2)`), which will become readable when completions are available on the ring. This can then be monitored asynchronously with `epoll`, `kqueue`, or for clients who are linking libdispatch, `DispatchSource`.

`struct IOCompletion: ~Copyable` represents the result of an IO operation and provides

* Flags indicating various operation-specific metadata about the now-completed syscall
* The context associated with the operation when it was enqueued, as an `UnsafeRawPointer` or a `UInt64`
* The result of the operation, as an `Int32` with operation-specific meaning
* The error, if one occurred

Unfortunately the underlying kernel API makes it relatively difficult to determine which `IORequest` led to a given `IOCompletion`, so it's expected that users will need to create this association themselves via the context parameter.

`IORingError` represents failure of an operation.

`IORing.Features` describes the supported features of the underlying kernel `IORing` implementation, which can be used to provide graceful reduction in functionality when running on older systems.

## Detailed design 

```swift
public struct IOResource<T> { }
public typealias IORingFileSlot = IOResource<UInt32>
public typealias IORingBuffer = IOResource<iovec>

extension IORingBuffer {
    public var unsafeBuffer: UnsafeMutableRawBufferPointer
}

// IORing is intentionally not Sendable, to avoid internal locking overhead
public struct IORing: ~Copyable {

	public init(queueDepth: UInt32) throws(IORingError)
	
	public mutating func registerEventFD(_ descriptor: FileDescriptor) throws(IORingError)
	public mutating func unregisterEventFD(_ descriptor: FileDescriptor) throws(IORingError)
	
	// An IORing.RegisteredResources is a view into the buffers or files registered with the ring, if any
	public struct RegisteredResources<T>: RandomAccessCollection {
		public subscript(position: Int) -> IOResource<T>
		public subscript(position: UInt16) -> IOResource<T> // This is useful because io_uring likes to use UInt16s as indexes
	}
	
	public mutating func registerFileSlots(count: Int) throws(IORingError) -> RegisteredResources<IORingFileSlot.Resource>
	
	public func unregisterFiles()
	
	public var registeredFileSlots: RegisteredResources<IORingFileSlot.Resource>
	
	public mutating func registerBuffers(
		_ buffers: some Collection<UnsafeMutableRawBufferPointer>
	) throws(IORingError) -> RegisteredResources<IORingBuffer.Resource>
	
	public mutating func registerBuffers(
		_ buffers: UnsafeMutableRawBufferPointer...
	) throws(IORingError) -> RegisteredResources<IORingBuffer.Resource>
	
	public func unregisterBuffers()
	
	public var registeredBuffers: RegisteredResources<IORingBuffer.Resource>
	
	public func prepare(requests: IORequest...)
	public func prepare(linkedRequests: IORequest...)
	
	public func submitPreparedRequests(timeout: Duration? = nil) throws(IORingError)
	public func submit(requests: IORequest..., timeout: Duration? = nil) throws(IORingError)
	public func submit(linkedRequests: IORequest..., timeout: Duration? = nil) throws(IORingError)
	
	public func submitPreparedRequests() throws(IORingError)
	public func submitPreparedRequestsAndWait(timeout: Duration? = nil) throws(IORingError)
	
	public func submitPreparedRequestsAndConsumeCompletions(
        minimumCount: UInt32 = 1,
        timeout: Duration? = nil,
        consumer: (consuming IOCompletion?, IORingError?, Bool) throws(E) -> Void
   ) throws(E)
	
	public func blockingConsumeCompletion(
       timeout: Duration? = nil
	) throws(IORingError) -> IOCompletion
    
	public func blockingConsumeCompletions<E>(
       minimumCount: UInt32 = 1,
       timeout: Duration? = nil,
		consumer: (consuming IOCompletion?, IORingError?, Bool) throws(E) -> Void
	) throws(E)
    
	public func tryConsumeCompletion() -> IOCompletion?
	
	public struct Features: OptionSet {
		let rawValue: UInt32
		
		public init(rawValue: UInt32)
		
		//IORING_FEAT_SINGLE_MMAP is handled internally
		public static let nonDroppingCompletions: Bool //IORING_FEAT_NODROP
		public static let stableSubmissions: Bool //IORING_FEAT_SUBMIT_STABLE
		public static let currentFilePosition: Bool //IORING_FEAT_RW_CUR_POS
		public static let assumingTaskCredentials: Bool //IORING_FEAT_CUR_PERSONALITY
		public static let fastPolling: Bool //IORING_FEAT_FAST_POLL
		public static let epoll32BitFlags: Bool //IORING_FEAT_POLL_32BITS
		public static let pollNonFixedFiles: Bool //IORING_FEAT_SQPOLL_NONFIXED
		public static let extendedArguments: Bool //IORING_FEAT_EXT_ARG
		public static let nativeWorkers: Bool //IORING_FEAT_NATIVE_WORKERS
		public static let resourceTags: Bool //IORING_FEAT_RSRC_TAGS
		public static let allowsSkippingSuccessfulCompletions: Bool //IORING_FEAT_CQE_SKIP
		public static let improvedLinkedFiles: Bool //IORING_FEAT_LINKED_FILE
		public static let registerRegisteredRings: Bool //IORING_FEAT_REG_REG_RING
		public static let minimumTimeout: Bool //IORING_FEAT_MIN_TIMEOUT
		public static let bundledSendReceive: Bool //IORING_FEAT_RECVSEND_BUNDLE
	}
	public static var supportedFeatures: Features
}

public struct IORequest: ~Copyable {
    public static func nop(context: UInt64 = 0) -> IORequest
	
	// overloads for each combination of registered vs unregistered buffer/descriptor
	// Read
    public static func read(
        _ file: IORingFileSlot,
        into buffer: IORingBuffer,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORequest
	
    public static func read(
        _ file: FileDescriptor,
        into buffer: IORingBuffer,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORequest
    
    public static func read(
        _ file: IORingFileSlot,
        into buffer: UnsafeMutableRawBufferPointer,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORequest
    
    public static func read(
        _ file: FileDescriptor,
        into buffer: UnsafeMutableRawBufferPointer,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORequest
    
    // Write
    public static func write(
        _ buffer: IORingBuffer,
        into file: IORingFileSlot,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORequest
    
    public static func write(
        _ buffer: IORingBuffer,
        into file: FileDescriptor,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORequest 
    
    public static func write(
        _ buffer: UnsafeMutableRawBufferPointer,
        into file: IORingFileSlot,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORequest
    
    public static func write(
        _ buffer: UnsafeMutableRawBufferPointer,
        into file: FileDescriptor,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORequest
    
    // Close
    public static func close(
        _ file: FileDescriptor,
        context: UInt64 = 0
    ) -> IORequest 
    
    public static func close(
        _ file: IORingFileSlot,
        context: UInt64 = 0
    ) -> IORequest
    
    // Open At
    public static func open(
        _ path: FilePath,
        in directory: FileDescriptor,
        into slot: IORingFileSlot,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        context: UInt64 = 0
    ) -> IORequest
    
    public static func open(
        _ path: FilePath,
        in directory: FileDescriptor,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        context: UInt64 = 0
    ) -> IORequest 
    
    public static func unlink(
        _ path: FilePath,
        in directory: FileDescriptor,
        context: UInt64 = 0
    ) -> IORequest
    
    // Cancel
    
    public enum CancellationMatch {
    	case all
    	case first
    }
    
    public static func cancel(
    	_ matchAll: CancellationMatch,
    	matchingContext: UInt64,
    	context: UInt64
    ) -> IORequest
    
    public static func cancel(
    	_ matchAll: CancellationMatch,
    	matchingFileDescriptor: FileDescriptor,
    	context: UInt64
    ) -> IORequest
    
    public static func cancel(
    	_ matchAll: CancellationMatch,
    	matchingRegisteredFileDescriptorAtIndex: Int,
    	context: UInt64
    ) -> IORequest
    
    public static func cancel(
    	_ matchAll: CancellationMatch,
    	context: UInt64
    ) -> IORequest
    
    // Other operations follow in the same pattern
}

public struct IOCompletion {

	public struct Flags: OptionSet, Hashable, Codable {
        public let rawValue: UInt32

        public init(rawValue: UInt32)
        
        public static let moreCompletions: Flags
        public static let socketNotEmpty: Flags
        public static let isNotificationEvent: Flags
   }

	//These are both the same value, but having both eliminates some ugly casts in client code
	public var context: UInt64 
	public var contextPointer: UnsafeRawPointer
	
	public var result: Int32
	
	public var error: IORingError? // Convenience wrapper over `result`
	
	public var flags: Flags	
}

public struct IORingError: Error, Equatable {
    static var missingRequiredFeatures: IORingError
    static var operationCanceled: IORingError
    static var timedOut: IORingError
    static var resourceRegistrationFailed: IORingError
    // Other error values to be filled out as the set of supported operations expands in the future
    static var unknown: IORingError(errorCode: Int)
}
	
```

## Usage Examples

### Blocking

```swift
let ring = try IORing(queueDepth: 2)

//Make space on the ring for our file (this is optional, but improves performance with repeated use)
let file = ring.registerFiles(count: 1)[0]

var statInfo = Glibc.stat() // System doesn't have an abstraction for stat() right now
// Build our requests to open the file and find out how big it is
ring.prepare(linkedRequests:
	.open(path,
		in: parentDirectory,
		into: file,
		mode: mode,
   		options: openOptions,
		permissions: nil
	),
	.stat(file, 
		into: &statInfo
	)
)
//batch submit 2 syscalls in 1!
try ring.submitPreparedRequestsAndConsumeCompletions(minimumCount: 2) { (completion: consuming IOCompletion?, error, done) in
	if let error {
		throw error //or other error handling as desired
	}
} 

// We could register our buffer with the ring too, but we're only using it once
let buffer = UnsafeMutableRawBufferPointer.allocate(Int(statInfo.st_size))

// Build our requests to read the file and close it
ring.prepare(linkedRequests:
	 .read(file,
	 	into: buffer
	 ),
	 .close(file)
)

//batch submit 2 syscalls in 1!
try ring.submitPreparedRequestsAndConsumeCompletions(minimumCount: 2) { (completion: consuming IOCompletion?, error, done) in
	if let error {
		throw error //or other error handling as desired
	}
}

processBuffer(buffer)
```

### Using libdispatch to wait for the read asynchronously

```swift
//Initial setup as above up through creating buffer, omitted for brevity

//Make the read request with a context so we can get the buffer out of it in the completion handler
…
.read(file, into: buffer, context: UInt64(buffer.baseAddress!))
…

// Make an eventfd and register it with the ring
let eventfd = eventfd(0, 0)
ring.registerEventFD(eventfd)

// Make a read source to monitor the eventfd for readability
let readabilityMonitor = DispatchSource.makeReadSource(fileDescriptor: eventfd)
readabilityMonitor.setEventHandler {
	let completion = ring.blockingConsumeCompletion()
	if let error = completion.error {
		//handle failure to read the file
	}
	processBuffer(completion.contextPointer)
}
readabilityMonitor.activate()

ring.submitPreparedRequests //note, not "AndConsumeCompletions" this time
```

## Source compatibility

This is an all-new API in Swift System, so has no backwards compatibility implications. Of note, though, this API is only available on Linux.

## ABI compatibility

Swift on Linux does not have a stable ABI, and we will likely take advantage of this to evolve IORing as compiler support improves, as described in Future Directions.

## Implications on adoption

This feature is intrinsically linked to Linux kernel support, so constrains the deployment target of anything that adopts it to newer kernels. Exactly which features of the evolving io_uring syscall surface area we need is under consideration.

## Future directions

* While most Swift users on Darwin are not limited by IO scalability issues, the thread pool considerations still make introducing something similar to this appealing if and when the relevant OS support is available. We should attempt to the best of our ability to not design this in a way that's gratuitously incompatible with non-Linux OSs, although Swift System does not attempt to have an API that's identical on all platforms.
* The set of syscalls covered by `io_uring` has grown significantly and is still growing. We should leave room for supporting additional operations in the future.
* Once same-element requirements and pack counts as integer generic arguments are supported by the compiler, we should consider adding something along the lines of the following to allow preparing, submitting, and waiting for an entire set of operations at once:

```
func submitLinkedRequestsAndWait<each Request>(
  _ requests: repeat each Request
) where Request == IORequest 
  -> InlineArray<(repeat each Request).count, IOCompletion>
```
* Once mutable borrows are supported, we should consider replacing the closure-taking bulk completion APIs (e.g. `blockingConsumeCompletions(…)`) with ones that return a sequence of completions instead
* We should consider making more types noncopyable as compiler support improves
* liburing has a "peek next completion" operation that doesn't consume it, and then a "mark consumed" operation. We may want to add something similar
* liburing has support for operations allocating their own buffers and returning them via the completion, we may want to support this
* We may want to provide API for asynchronously waiting, rather than just exposing the eventfd to let people roll their own async waits. Doing this really well has *considerable* implications for the concurrency runtime though.
* We should almost certainly expose API for more of the configuration options in `io_uring_setup`
* Stronger safety guarantees around cancellation and resource lifetimes (e.g. as described in https://without.boats/blog/io-uring/) would be very welcome, but require an API that is much more strongly opinionated about how io_uring is used. A future higher level abstraction focused on the goal of being "an async IO API for Swift" rather than "a Swifty interface to io_uring" seems like a good place for that.

## Alternatives considered

* We could use a NIO-style separate thread pool, but we believe `io_uring` is likely a better option for scalability. We may still want to provide a thread-pool backed version as an option, because many Linux systems currently disable `io_uring` due to security concerns.
* We could multiplex all IO onto a single actor as `AsyncBytes` currently does, but this has a number of downsides that make it entirely unsuitable to server usage. Most notably, it eliminates IO parallelism entirely.
* Using POSIX AIO instead of or as well as io_uring would greatly increase our ability to support older kernels and other Unix systems, but it has well-documented performance and usability issues that have prevented its adoption elsewhere, and apply just as much to Swift.
* Earlier versions of this proposal had higher level "managed" abstractions over IORing. These have been removed due to lack of interest from clients, but could be added back later if needed.
* I considered making any or all of `IORingError`, `IOCompletion`, and `IORequest` nested struct declarations inside `IORing`. The main reason I haven't done so is I was a little concerned about the ambiguity of having a type called `Error`. I'd be particularly interested in feedback on this choice.
* IOResource<T> was originally a class in an attempt to manage the lifetime of the resource via language features. Changing to the current model of it being a copyable struct didn't make the lifetime management any less safe (the IORing still owns the actual resource), and reduces overhead. In the future it would be neat if we could express IOResources as being borrowed from the IORing so they can't be used after its lifetime.

## Acknowledgments

The NIO team, in particular Cory Benfield and Franz Busch, have provided invaluable feedback and direction on this project.
