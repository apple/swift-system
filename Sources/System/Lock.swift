// TODO: write against kernel APIs directly?
import Glibc

@usableFromInline final class Mutex {
    @usableFromInline let mutex: UnsafeMutablePointer<pthread_mutex_t>

    @inlinable init() {
        self.mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        self.mutex.initialize(to: pthread_mutex_t())
        pthread_mutex_init(self.mutex, nil)
    }

    @inlinable deinit {
        defer { mutex.deallocate() }
        guard pthread_mutex_destroy(mutex) == 0 else {
            preconditionFailure("unable to destroy mutex")
        }
    }

    // XXX: this is because we need to lock the mutex in the context of a submit() function
    // and unlock *before* the UnsafeContinuation returns.
    // Code looks like: {
    //    // prepare request
    //    io_uring_get_sqe()
    //    io_uring_prep_foo(...)
    //    return await withUnsafeContinuation {
    //      sqe->user_data = ...; io_uring_submit(); unlock();
    //    }
    // }
    @inlinable @inline(__always) public func lock() {
        pthread_mutex_lock(mutex)
    }

    @inlinable @inline(__always) public func unlock() {
        pthread_mutex_unlock(mutex)
    }
}
