/*
 This source file is part of the Swift System open source project

 Copyright (c) 2022 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if swift(>=5.9) && SYSTEM_PACKAGE_DARWIN

import XCTest
import Darwin.Mach

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

@available(/*System 1.4.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
final class MachPortTests: XCTestCase {
    func refCountForMachPortName(name:mach_port_name_t, kind:mach_port_right_t) -> mach_port_urefs_t {
        var refCount:mach_port_urefs_t = .max
        let kr = mach_port_get_refs(mach_task_self_, name, kind, &refCount)
        if kr == KERN_INVALID_NAME {
            refCount = 0
        } else {
            XCTAssertEqual(kr, KERN_SUCCESS)
        }
        return refCount
    }

    func scopedReceiveRight(name:mach_port_name_t) -> mach_port_urefs_t {
        let right = Mach.Port<Mach.ReceiveRight>(name:name) // this should automatically deallocate when going out of scope
        defer { _ = right }
        return refCountForMachPortName(name:name, kind:MACH_PORT_RIGHT_RECEIVE)
    }

    func testReceiveRightDeallocation() throws {
        var name: mach_port_name_t = 0xFFFFFFFF
        let kr = mach_port_allocate(mach_task_self_, MACH_PORT_RIGHT_RECEIVE, &name)
        XCTAssertEqual(kr, KERN_SUCCESS)

        XCTAssertNotEqual(name, 0xFFFFFFFF)

        let originalCount = refCountForMachPortName(name: name, kind: MACH_PORT_RIGHT_RECEIVE)
        XCTAssertEqual(originalCount, 1)

        let incrementedCount = scopedReceiveRight(name:name)
        XCTAssertEqual(incrementedCount, 1);

        let deallocated = refCountForMachPortName(name:name, kind: MACH_PORT_RIGHT_RECEIVE)
        XCTAssertEqual(deallocated, 0);
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
            XCTAssertEqual(kr, KERN_SUCCESS)
            let one = consumeSendRightAutomatically(name:name)
            XCTAssertEqual(one, 1);
            let zero = refCountForMachPortName(name:name, kind:MACH_PORT_RIGHT_SEND)
            XCTAssertEqual(zero, 0);
        }
    }

    func testSendRightRelinquishment() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()

        let name = ({
            let send = recv.makeSendRight()
            let one = send.withBorrowedName { name in
                return self.refCountForMachPortName(name:name, kind:MACH_PORT_RIGHT_SEND)
            }
            XCTAssertEqual(one, 1)

            return send.relinquish()
        })()

        let stillOne = refCountForMachPortName(name:name, kind:MACH_PORT_RIGHT_SEND)
        XCTAssertEqual(stillOne, 1)

        recv.withBorrowedName {
            let alsoOne = refCountForMachPortName(name: $0, kind: MACH_PORT_RIGHT_RECEIVE)
            XCTAssertEqual(alsoOne, 1)
        }
    }

    func testSendOnceRightRelinquishment() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()

        let name = ({
            let send = recv.makeSendOnceRight()
            let one = send.withBorrowedName { name in
                return self.refCountForMachPortName(name: name, kind: MACH_PORT_RIGHT_SEND_ONCE)
            }
            XCTAssertEqual(one, 1)

            return send.relinquish()
        })()

        let stillOne = refCountForMachPortName(name: name, kind: MACH_PORT_RIGHT_SEND_ONCE)
        XCTAssertEqual(stillOne, 1)

        recv.withBorrowedName {
            let alsoOne = refCountForMachPortName(name: $0, kind: MACH_PORT_RIGHT_RECEIVE)
            XCTAssertEqual(alsoOne, 1)
        }
    }

    func testReceiveRightRelinquishment() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()

        let one = recv.withBorrowedName {
            self.refCountForMachPortName(name: $0, kind: MACH_PORT_RIGHT_RECEIVE)
        }
        XCTAssertEqual(one, 1)

        let name = recv.unguardAndRelinquish()

        let stillOne = refCountForMachPortName(name: name, kind: MACH_PORT_RIGHT_RECEIVE)
        XCTAssertEqual(stillOne, 1)
    }

    func testMakeSendCountSettable() throws {
        var recv = Mach.Port<Mach.ReceiveRight>()
        XCTAssertEqual(recv.makeSendCount, 0)
        recv.makeSendCount = 7
        XCTAssertEqual(recv.makeSendCount, 7)
    }

    func makeSendRight() throws -> Mach.Port<Mach.SendRight> {
        let recv = Mach.Port<Mach.ReceiveRight>()
        let zero = recv.makeSendCount
        XCTAssertEqual(zero, 0)
        let send = recv.makeSendRight()
        let one = recv.makeSendCount
        XCTAssertEqual(one, 1)
        return send
    }

    func testMakeSendCountIncrement() throws {
        _ = try makeSendRight()
    }

    func testMakeSendOnceDoesntIncrementMakeSendCount() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()
        let zero = recv.makeSendCount
        XCTAssertEqual(zero, 0)
        _ = recv.makeSendOnceRight()
        let same = recv.makeSendCount
        XCTAssertEqual(same, zero)
    }

    func testMakeSendOnceIsUnique() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()
        let once = recv.makeSendOnceRight()
        recv.withBorrowedName { rname in
            once.withBorrowedName { oname in
                XCTAssertNotEqual(oname, rname)
            }
        }
    }

    func testCopySend() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()
        let zero = recv.makeSendCount
        XCTAssertEqual(zero, 0)
        let send = recv.makeSendRight()
        let one = recv.makeSendCount
        XCTAssertEqual(one, 1)
        _ = try send.copySendRight()
        let same = recv.makeSendCount
        XCTAssertEqual(same, one)

    }

    func testCopyDeadName() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()
        let send = recv.makeSendRight()
        _ = consume recv // and turn `send` into a dead name
        XCTAssertThrowsError(
          _ = try send.copySendRight(),
          "Copying a dead name should throw"
        ) { error in
            XCTAssertEqual(
              error as! Mach.PortRightError, Mach.PortRightError.deadName
            )
        }
    }

    func testCopyDeadName2() throws {
        let send = Mach.Port<Mach.SendRight>(name: 0xffffffff)
        XCTAssertThrowsError(
          _ = try send.copySendRight(),
          "Copying a dead name should throw"
        ) { error in
            XCTAssertEqual(
              error as! Mach.PortRightError, Mach.PortRightError.deadName
            )
        }
    }

    func testMakeReceiveRightFromExistingName() throws {
        var name = mach_port_name_t(MACH_PORT_NULL)
        var kr = mach_port_allocate(mach_task_self_, MACH_PORT_RIGHT_RECEIVE, &name)
        XCTAssertEqual(kr, KERN_SUCCESS)
        XCTAssertNotEqual(name, mach_port_name_t(MACH_PORT_NULL))
        let context = mach_port_context_t(arc4random())
        kr = mach_port_guard(mach_task_self_, name, context, 0)
        XCTAssertEqual(kr, KERN_SUCCESS)

        let right = Mach.Port<Mach.ReceiveRight>(name: name, context: context)
        right.withBorrowedName {
            XCTAssertEqual(name, $0)
            XCTAssertEqual(context, $1)
        }
    }

    func testDeinitDeadSendRights() throws {
        let recv = Mach.Port<Mach.ReceiveRight>()
        let send = recv.makeSendRight()
        let send1 = recv.makeSendOnceRight()

        _ = consume recv
        // `send` and `send1` have become dead names
        _ = consume send
        _ = consume send1
    }
}

#endif
