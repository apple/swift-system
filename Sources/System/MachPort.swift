/*
 This source file is part of the Swift System open source project

 Copyright (c) 2022 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if swift(>=5.9) && SYSTEM_PACKAGE_DARWIN

import Darwin.Mach

@available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
public protocol MachPortRight {}

@available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
@inlinable
internal func _machPrecondition(
  file: StaticString = #file,
  line: UInt = #line,
  _ body: @autoclosure () -> kern_return_t
) {
  let kr = body()
  let expected = KERN_SUCCESS
  precondition(kr == expected, file: file, line: line)
}

@available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
@frozen
public enum Mach {
  @available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  public struct Port<RightType: MachPortRight>: ~Copyable {
    @usableFromInline
    internal var _name: mach_port_name_t

    @usableFromInline
    internal var _context: mach_port_context_t

    /// Transfer ownership of an existing unmanaged Mach port right into a
    /// `Mach.Port` by name.
    ///
    /// This initializer traps if `name` is `MACH_PORT_NULL`, or if `name` is
    /// `MACH_PORT_DEAD` and the `RightType` is `Mach.ReceiveRight`.
    ///
    /// If the type of the right does not match the `RightType` of the 
    /// `Mach.Port` being constructed, behavior is undefined.
    ///
    /// The underlying port right will be automatically deallocated at the
    /// end of the `Mach.Port` instance's lifetime.
    ///
    /// This initializer makes a syscall to guard the right.
    public init(name: mach_port_name_t) {
      precondition(name != mach_port_name_t(MACH_PORT_NULL),
                   "Mach.Port cannot be initialized with MACH_PORT_NULL")
      self._name = name

      if RightType.self == ReceiveRight.self {
        precondition(
          _name != (0xFFFFFFFF as mach_port_name_t) /* MACH_PORT_DEAD */,
          "Receive rights cannot be dead names"
        )

        let secret = mach_port_context_t(arc4random())
        _machPrecondition(mach_port_guard(mach_task_self_, name, secret, 0))
        self._context = secret
      }
      else {
        self._context = 0
      }
    }

    /// Borrow access to the port name in a block that can perform
    /// non-consuming operations.
    ///
    /// Take care when using this function; many operations consume rights,
    /// and send-once rights are easily consumed.
    ///
    /// If the right is consumed, behavior is undefined.
    ///
    /// The body block may optionally return something, which will then be
    /// returned to the caller of withBorrowedName.
    @inlinable
    public func withBorrowedName<ReturnType>(
      body: (mach_port_name_t) -> ReturnType
    ) -> ReturnType {
      return body(_name)
    }

    deinit {
      if RightType.self == ReceiveRight.self {
        precondition(
          _name != (0xFFFFFFFF as mach_port_name_t) /* MACH_PORT_DEAD */,
          "Receive rights cannot be dead names"
        )
        _machPrecondition(
          mach_port_destruct(mach_task_self_, _name, 0, _context)
        )
      } else {
        assert(
          RightType.self == SendRight.self ||
          RightType.self == SendOnceRight.self
        )
        _machPrecondition(mach_port_deallocate(mach_task_self_, _name))
      }
    }
  }

  /// Possible errors that can be thrown by Mach.Port operations.
  public enum PortRightError : Error {
    /// Returned when an operation cannot be completed, because the Mach
    /// port right has become a dead name. This is caused by deallocation of the
    /// receive right on the other end.
    case deadName
  }

  /// The MachPortRight type used to manage a receive right.
  @frozen
  public struct ReceiveRight: MachPortRight {}

  /// The MachPortRight type used to manage a send right.
  @frozen
  public struct SendRight: MachPortRight {}

  /// The MachPortRight type used to manage a send-once right.
  ///
  /// Send-once rights are the most restrictive type of Mach port rights.
  /// They cannot create other rights, and are consumed upon use.
  ///
  /// Upon destruction a send-once notification will be sent to the
  /// receiving end.
  @frozen
  public struct SendOnceRight: MachPortRight {}
}

@available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
extension Mach.Port where RightType == Mach.ReceiveRight {
  /// Transfer ownership of an existing, unmanaged, but already guarded,
  /// Mach port right into a Mach.Port by name.
  ///
  /// This initializer aborts if name is MACH_PORT_NULL.
  ///
  /// If the type of the right does not match the type T of Mach.Port<T>
  /// being constructed, the behavior is undefined.
  ///
  /// The underlying port right will be automatically deallocated when
  /// the Mach.Port object is destroyed.
  public init(name: mach_port_name_t, context: mach_port_context_t) {
    precondition(name != mach_port_name_t(MACH_PORT_NULL),
                 "Mach.Port cannot be initialized with MACH_PORT_NULL")
    self._name = name
    self._context = context
  }

  /// Allocate a new Mach port with a receive right, creating a
  /// Mach.Port<Mach.ReceiveRight> to manage it.
  ///
  /// This initializer will abort if the right could not be created.
  /// Callers may assert that a valid right is always returned.
  @inlinable
  @available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  public init() {
    var storage: mach_port_name_t = mach_port_name_t(MACH_PORT_NULL)
    _machPrecondition(
      mach_port_allocate(mach_task_self_, MACH_PORT_RIGHT_RECEIVE, &storage)
    )

    // name-only init will guard ReceiveRights
    self.init(name: storage)
  }


  /// Transfer ownership of the underlying port right to the caller.
  ///
  /// Returns a tuple containing the Mach port name representing the right,
  /// and the context value used to guard the right.
  ///
  /// This operation liberates the right from management by the Mach.Port,
  /// and the underlying right will no longer be automatically deallocated.
  ///
  /// After this function completes, the Mach.Port is destroyed and no longer
  /// usable.
  @inlinable
  @available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  public consuming func relinquish(
  ) -> (name: mach_port_name_t, context: mach_port_context_t) {
    let destructured = (name: _name, context: _context)
    discard self
    return destructured
  }

  /// Remove guard and transfer ownership of the underlying port right to
  /// the caller.
  ///
  /// Returns the Mach port name representing the right.
  ///
  /// This operation liberates the right from management by the Mach.Port,
  /// and the underlying right will no longer be automatically deallocated.
  ///
  /// After this function completes, the Mach.Port is destroyed and no longer
  /// usable.
  ///
  /// This function makes a syscall to remove the guard from
  /// Mach.ReceiveRights. Use relinquish() to avoid the syscall and extract
  /// the context value along with the port name.
  @inlinable
  @available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  public consuming func unguardAndRelinquish() -> mach_port_name_t {
    let (name, context) = self.relinquish()
    _machPrecondition(mach_port_unguard(mach_task_self_, name, context))
    return name
  }

  /// Borrow access to the port name in a block that can perform
  /// non-consuming operations.
  ///
  /// Take care when using this function; many operations consume rights.
  ///
  /// If the right is consumed, behavior is undefined.
  ///
  /// The body block may optionally return something, which will then be
  /// returned to the caller of withBorrowedName.
  @inlinable
  @available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  public func withBorrowedName<ReturnType>(
    body: (mach_port_name_t, mach_port_context_t) -> ReturnType
  ) -> ReturnType {
    return body(_name, _context)
  }

  /// Create a send-once right for a given receive right.
  ///
  /// This does not affect the makeSendCount of the receive right.
  ///
  /// This function will abort if the right could not be created.
  /// Callers may assert that a valid right is always returned.
  @inlinable
  @available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  public func makeSendOnceRight() -> Mach.Port<Mach.SendOnceRight> {
    // send once rights do not coalesce
    var newRight: mach_port_name_t = mach_port_name_t(MACH_PORT_NULL)
    var newRightType: mach_port_type_t = MACH_PORT_TYPE_NONE

    _machPrecondition(
      mach_port_extract_right(
        mach_task_self_,
        _name,
        mach_msg_type_name_t(MACH_MSG_TYPE_MAKE_SEND_ONCE),
        &newRight,
        &newRightType
      )
    )

    // The value of newRight is validated by the Mach.Port initializer
    precondition(newRightType == MACH_MSG_TYPE_MOVE_SEND_ONCE)

    return Mach.Port(name: newRight)
  }

  /// Create a send right for a given receive right.
  ///
  /// This increments the makeSendCount of the receive right.
  ///
  /// This function will abort if the right could not be created.
  /// Callers may assert that a valid right is always returned.
  @inlinable
  @available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  public func makeSendRight() -> Mach.Port<Mach.SendRight> {
    let how = MACH_MSG_TYPE_MAKE_SEND

    // name is the same because send and recv rights are coalesced
    _machPrecondition(
      mach_port_insert_right(
        mach_task_self_, _name, _name, mach_msg_type_name_t(how)
      )
    )

    return Mach.Port(name: _name)
  }

  /// Access the make-send count.
  ///
  /// Each get/set of this property makes a syscall.
  @inlinable
  @available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  public var makeSendCount: mach_port_mscount_t {
    get {
      var status: mach_port_status = mach_port_status()
      var size = mach_msg_type_number_t(
        MemoryLayout<mach_port_status>.size / MemoryLayout<natural_t>.size
      )

      withUnsafeMutablePointer(to: &status) {
        [ _name = self._name ] in
        let status = UnsafeMutableBufferPointer(start: $0, count: 1)
        status.withMemoryRebound(to: integer_t.self) {
          let info = $0.baseAddress
          _machPrecondition(
            mach_port_get_attributes(
              mach_task_self_, _name, MACH_PORT_RECEIVE_STATUS, info, &size
            )
          )
        }
      }
      return status.mps_mscount
    }

    set {
      _machPrecondition(mach_port_set_mscount(mach_task_self_, _name, newValue))
    }
  }
}

@available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
extension Mach.Port where RightType == Mach.SendRight {
  /// Transfer ownership of the underlying port right to the caller.
  ///
  /// Returns the Mach port name representing the right.
  ///
  /// This operation liberates the right from management by the Mach.Port,
  /// and the underlying right will no longer be automatically deallocated.
  ///
  /// After this function completes, the Mach.Port is destroyed and no longer
  /// usable.
  @inlinable
  public consuming func relinquish() -> mach_port_name_t {
    let name = _name
    discard self
    return name
  }

  /// Create another send right from a given send right.
  ///
  /// This does not affect the makeSendCount of the receive right.
  ///
  /// If the send right being copied has become a dead name, meaning the
  /// receiving side has been deallocated, then copySendRight() will throw
  /// a Mach.PortRightError.deadName error.
  @inlinable
  @available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  public func copySendRight() throws -> Mach.Port<Mach.SendRight> {
    let how = MACH_MSG_TYPE_COPY_SEND

    // name is the same because send rights are coalesced
    let kr = mach_port_insert_right(
      mach_task_self_, _name, _name, mach_msg_type_name_t(how)
    )
    if kr == KERN_INVALID_NAME || kr == KERN_INVALID_CAPABILITY {
      throw Mach.PortRightError.deadName
    }
    _machPrecondition(kr)

    return Mach.Port(name: _name)
  }
}

@available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
extension Mach.Port where RightType == Mach.SendOnceRight {
  /// Transfer ownership of the underlying port right to the caller.
  ///
  /// Returns the Mach port name representing the right.
  ///
  /// This operation liberates the right from management by the Mach.Port,
  /// and the underlying right will no longer be automatically deallocated.
  ///
  /// After this function completes, the Mach.Port is destroyed and no longer
  /// usable.
  @inlinable
  @available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  public consuming func relinquish() -> mach_port_name_t {
    let name = _name
    discard self
    return name
  }
}

#endif
