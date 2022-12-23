/*
 This source file is part of the Swift System open source project

 Copyright (c) 2022 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if $MoveOnly && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))

import XCTest
import Darwin.Mach

final class MachPortTests: XCTestCase {
    func refCountForMachPortName(name:mach_port_name_t, kind:mach_port_right_t) -> mach_port_urefs_t {
        var refCount:mach_port_urefs_t = 0
        withUnsafeMutablePointer(to: &refCount) { refCount in
            let kr = mach_port_get_refs(mach_task_self_, name, kind, refCount)
            assert(kr == KERN_SUCCESS)
        }
        return refCount
    }

    func scopedReceiveRight(name:mach_port_name_t) -> mach_port_urefs_t {
        _ = Mach.Port<Mach.ReceiveRight>(name:name) // this should automatically deallocate when going out of scope
        return refCountForMachPortName(name:name, kind:MACH_PORT_RIGHT_RECEIVE)
    }

    func testRecieveRightDeallocation() throws {
        var name:mach_port_name_t = 0 // Never read
        withUnsafeMutablePointer(to:&name) { name in
            let kr = mach_port_allocate(mach_task_self_, MACH_PORT_RIGHT_RECEIVE, name)
            assert(kr == KERN_SUCCESS)
        }

        XCTAssert(name != 0xFFFFFFFF)

        let one = scopedReceiveRight(name:name)
        let zero = refCountForMachPortName(name:name, kind: MACH_PORT_RIGHT_RECEIVE)

        XCTAssert(one == 1);
        XCTAssert(zero == 0);
    }

    func consumeSendRightAutomatically(name:mach_port_name_t) -> mach_port_urefs_t {
        let send = Mach.Port<Mach.SendRight>(name:name) // this should automatically deallocate when going out of scope
        return send.withBorrowedName { name in
            // Get the ref count before automatic deallocation happens
            return refCountForMachPortName(name:name, kind:MACH_PORT_RIGHT_SEND)
        }
    }

    func testSendRightDeallocation() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()
        recv.withBorrowedName { name in
            let kr = mach_port_insert_right(mach_task_self_, name, name, mach_msg_type_name_t(MACH_MSG_TYPE_MAKE_SEND))
            XCTAssert(kr == KERN_SUCCESS)
            let one = consumeSendRightAutomatically(name:name)
            XCTAssert(one == 1);
            let zero = refCountForMachPortName(name:name, kind:MACH_PORT_RIGHT_SEND)
            XCTAssert(zero == 0);
        }
    }

    func testSendRightRelinquishment() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()

        let name = ({
            let send = recv.makeSendRight()
            let one = send.withBorrowedName { name in
                return self.refCountForMachPortName(name:name, kind:MACH_PORT_RIGHT_SEND)
            }
            XCTAssert(one == 1)

            return send.relinquish()
        })()

        let stillOne = refCountForMachPortName(name:name, kind:MACH_PORT_RIGHT_SEND)
        XCTAssert(stillOne == 1)
    }

    func testMakeSendCountSettable() throws {
        var recv = Mach.Port<Mach.ReceiveRight>()
        XCTAssert(recv.makeSendCount == 0)
        recv.makeSendCount = 7
        XCTAssert(recv.makeSendCount == 7)
    }

    func makeSendRight() throws -> Mach.Port<Mach.SendRight> {
        let recv = Mach.Port<Mach.ReceiveRight>()
        let zero = recv.makeSendCount
        XCTAssert(zero == 0)
        let send = recv.makeSendRight()
        let one = recv.makeSendCount
        XCTAssert(one == 1)
        return send
    }

    func testMakeSendCountIncrement() throws {
        _ = try makeSendRight()
    }

    func testMakeSendOnceDoesntIncrementMakeSendCount() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()
        let zero = recv.makeSendCount
        XCTAssert(zero == 0)
        _ = recv.makeSendOnceRight()
        let same = recv.makeSendCount
        XCTAssert(same == zero)
    }

    func testMakeSendOnceIsUnique() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()
        let once = recv.makeSendOnceRight()
        recv.withBorrowedName { rname in
            once.withBorrowedName { oname in
                print(oname, rname)
                XCTAssert(oname != rname)
            }
        }
    }

    func testMakePair() throws {
        let (recv, send) = Mach.allocatePortRightPair()
        XCTAssert(recv.makeSendCount == 1)
        recv.withBorrowedName { rName in
            send.withBorrowedName { sName in
                XCTAssert(rName != 0xFFFFFFFF)
                XCTAssert(rName != MACH_PORT_NULL)
                // send and recv port names coalesce
                XCTAssert(rName == sName)
            }
        }
    }

    func testCopySend() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()
        let zero = recv.makeSendCount
        XCTAssert(zero == 0)
        let send = recv.makeSendRight()
        let one = recv.makeSendCount
        XCTAssert(one == 1)
        _ = try send.copySendRight()
        let same = recv.makeSendCount
        XCTAssert(same == one)

    }
}

#endif
