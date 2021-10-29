/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// POSIX Socket Address Family
@frozen
public struct SocketAddressFamily: RawRepresentable, Hashable, Codable {
    
  /// The raw socket address family identifier.
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  /// Creates a strongly-typed socket address family from a raw address family identifier.
  @_alwaysEmitIntoClient
  public init(rawValue: CInt) { self.rawValue = rawValue }
  
  @_alwaysEmitIntoClient
  private init(_ raw: CInt) { self.init(rawValue: raw) }
}

public extension SocketAddressFamily {
    
    /// Local communication
    @_alwaysEmitIntoClient
    static var unix: SocketAddressFamily { SocketAddressFamily(_AF_UNIX) }
    
    /// IPv4 Internet protocol
    @_alwaysEmitIntoClient
    static var ipv4: SocketAddressFamily { SocketAddressFamily(_AF_INET) }
    
    /// IPv6 Internet protocol
    @_alwaysEmitIntoClient
    static var ipv6: SocketAddressFamily { SocketAddressFamily(_AF_INET6) }
    
    /// IPX - Novell protocol
    @_alwaysEmitIntoClient
    static var ipx: SocketAddressFamily { SocketAddressFamily(_AF_IPX) }
    
    /// AppleTalk protocol
    @_alwaysEmitIntoClient
    static var appleTalk: SocketAddressFamily { SocketAddressFamily(_AF_APPLETALK) }
}

#if !os(Windows)
public extension SocketAddressFamily {
    
    /// DECet protocol sockets
    @_alwaysEmitIntoClient
    static var decnet: SocketAddressFamily { SocketAddressFamily(_AF_DECnet) }
    
    /// VSOCK (originally "VMWare VSockets") protocol for hypervisor-guest communication
    @_alwaysEmitIntoClient
    static var vsock: SocketAddressFamily { SocketAddressFamily(_AF_VSOCK) }
    
    /// Integrated Services Digital Network protocol
    @_alwaysEmitIntoClient
    static var isdn: SocketAddressFamily { SocketAddressFamily(_AF_ISDN) }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
public extension SocketAddressFamily {
    
    /// NetBIOS protocol
    @_alwaysEmitIntoClient
    static var netbios: SocketAddressFamily { SocketAddressFamily(_AF_NETBIOS) }
    
    ///
    @_alwaysEmitIntoClient
    static var implink: SocketAddressFamily { SocketAddressFamily(_AF_IMPLINK) }
    
    ///
    @_alwaysEmitIntoClient
    static var pup: SocketAddressFamily { SocketAddressFamily(_AF_PUP) }
    
    ///
    @_alwaysEmitIntoClient
    static var chaos: SocketAddressFamily { SocketAddressFamily(_AF_CHAOS) }
    
    ///
    @_alwaysEmitIntoClient
    static var ns: SocketAddressFamily { SocketAddressFamily(_AF_NS) }
    
    ///
    @_alwaysEmitIntoClient
    static var iso: SocketAddressFamily { SocketAddressFamily(_AF_ISO) }
    
    /// Generic PPP transport layer, for setting up L2 tunnels (L2TP and PPPoE).
    @_alwaysEmitIntoClient
    static var ppp: SocketAddressFamily { SocketAddressFamily(_AF_PPP) }
    
    ///
    @_alwaysEmitIntoClient
    static var link: SocketAddressFamily { SocketAddressFamily(_AF_LINK) }
}
#endif

#if os(Linux)
public extension SocketAddressFamily {
    
    /// Amateur radio AX.25 protocol
    @_alwaysEmitIntoClient
    static var ax25: SocketAddressFamily { SocketAddressFamily(_AF_AX25) }
    
    /// ITU-T X.25 / ISO-8208 protocol
    @_alwaysEmitIntoClient
    static var x25: SocketAddressFamily { SocketAddressFamily(_AF_X25) }
    
    /// Key management protocol
    @_alwaysEmitIntoClient
    static var key: SocketAddressFamily { SocketAddressFamily(_AF_KEY) }
    
    /// Kernel user interface device
    @_alwaysEmitIntoClient
    static var netlink: SocketAddressFamily { SocketAddressFamily(_AF_NETLINK) }
    
    /// Low-level packet interface
    @_alwaysEmitIntoClient
    static var packet: SocketAddressFamily { SocketAddressFamily(_AF_PACKET) }
    
    /// Access to ATM Switched Virtual Circuits
    @_alwaysEmitIntoClient
    static var atm: SocketAddressFamily { SocketAddressFamily(_AF_ATMSVC) }
    
    /// Reliable Datagram Sockets (RDS) protocol
    @_alwaysEmitIntoClient
    static var rds: SocketAddressFamily { SocketAddressFamily(_AF_RDS) }
    
    /// Generic PPP transport layer, for setting up L2 tunnels (L2TP and PPPoE).
    @_alwaysEmitIntoClient
    static var ppp: SocketAddressFamily { SocketAddressFamily(_AF_PPPOX) }
    
    /// Legacy protocol for wide area network (WAN) connectivity that was used by Sangoma WAN cards.
    @_alwaysEmitIntoClient
    static var wanpipe: SocketAddressFamily { SocketAddressFamily(_AF_WANPIPE) }
    
    /// Logical link control (IEEE 802.2 LLC) protocol, upper part of data link layer of ISO/OSI networking protocol stack.
    @_alwaysEmitIntoClient
    static var link: SocketAddressFamily { SocketAddressFamily(_AF_LLC) }
    
    /// InfiniBand native addressing.
    @_alwaysEmitIntoClient
    static var ib: SocketAddressFamily { SocketAddressFamily(_AF_IB) }
    
    /// Multiprotocol Label Switching
    @_alwaysEmitIntoClient
    static var mpls: SocketAddressFamily { SocketAddressFamily(_AF_MPLS) }
    
    /// Controller Area Network automotive bus protocol
    @_alwaysEmitIntoClient
    static var can: SocketAddressFamily { SocketAddressFamily(_AF_CAN) }
    
    /// TIPC, "cluster domain sockets" protocol
    @_alwaysEmitIntoClient
    static var tipc: SocketAddressFamily { SocketAddressFamily(_AF_TIPC) }
    
    /// Bluetooth protocol
    @_alwaysEmitIntoClient
    static var bluetooth: SocketAddressFamily { SocketAddressFamily(_AF_BLUETOOTH) }
    
    /// IUCV (inter-user communication vehicle) z/VM protocol for hypervisor-guest interaction
    @_alwaysEmitIntoClient
    static var iucv: SocketAddressFamily { SocketAddressFamily(_AF_IUCV) }
    
    /// Rx, Andrew File System remote procedure call protocol
    @_alwaysEmitIntoClient
    static var rxrpc: SocketAddressFamily { SocketAddressFamily(_AF_RXRPC) }
    
    /// Nokia cellular modem IPC/RPC interface
    @_alwaysEmitIntoClient
    static var phonet: SocketAddressFamily { SocketAddressFamily(_AF_PHONET) }
    
    /// IEEE 802.15.4 WPAN (wireless personal area network) raw packet protocol
    @_alwaysEmitIntoClient
    static var ieee802154: SocketAddressFamily { SocketAddressFamily(_AF_IEEE802154) }
    
    /// Ericsson's Communication CPU to Application CPU interface (CAIF) protocol
    @_alwaysEmitIntoClient
    static var caif: SocketAddressFamily { SocketAddressFamily(_AF_CAIF) }
    
    /// Interface to kernel crypto API
    @_alwaysEmitIntoClient
    static var crypto: SocketAddressFamily { SocketAddressFamily(_AF_ALG) }
    
    /// KCM (kernel connection multiplexer) interface
    @_alwaysEmitIntoClient
    static var kcm: SocketAddressFamily { SocketAddressFamily(_AF_KCM) }
    
    /// Qualcomm IPC router interface protocol
    @_alwaysEmitIntoClient
    static var qipcrtr: SocketAddressFamily { SocketAddressFamily(_AF_QIPCRTR) }
    
    /// SMC-R (shared memory communications over RDMA) protocol
    /// and SMC-D (shared memory communications, direct memory access) protocol for intra-node z/VM quest interaction.
    @_alwaysEmitIntoClient
    static var smc: SocketAddressFamily { SocketAddressFamily(_AF_SMC) }
    
    /// XDP (express data path) interface.
    @_alwaysEmitIntoClient
    static var xdp: SocketAddressFamily { SocketAddressFamily(_AF_XDP) }
}
#endif

#if os(Windows)
public extension SocketAddressFamily {
    
    /// NetBIOS protocol
    @_alwaysEmitIntoClient
    static var netbios: SocketAddressFamily { SocketAddressFamily(_AF_NETBIOS) }
    
    /// IrDA protocol
    @_alwaysEmitIntoClient
    static var irda: SocketAddressFamily { SocketAddressFamily(_AF_IRDA) }
    
    /// Bluetooth protocol
    @_alwaysEmitIntoClient
    static var bluetooth: SocketAddressFamily { SocketAddressFamily(_AF_BTH) }
}
#endif
