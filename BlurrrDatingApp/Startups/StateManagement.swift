import Foundation
import WebRTC

protocol CustomStringConvertibleEnum {
    var description: String { get }
}

extension RTCIceConnectionState: CustomStringConvertibleEnum {
    private static let descriptions: [RTCIceConnectionState: String] = [
        .new: "new",
        .checking: "checking",
        .connected: "connected",
        .completed: "completed",
        .failed: "failed",
        .disconnected: "disconnected",
        .closed: "closed",
        .count: "count"
    ]
    
    public var description: String {
        return RTCIceConnectionState.descriptions[self] ?? "Unknown \(self.rawValue)"
    }
}

extension RTCSignalingState: CustomStringConvertibleEnum {
    private static let descriptions: [RTCSignalingState: String] = [
        .stable: "stable",
        .haveLocalOffer: "haveLocalOffer",
        .haveLocalPrAnswer: "haveLocalPrAnswer",
        .haveRemoteOffer: "haveRemoteOffer",
        .haveRemotePrAnswer: "haveRemotePrAnswer",
        .closed: "closed"
    ]
    
    public var description: String {
        return RTCSignalingState.descriptions[self] ?? "Unknown \(self.rawValue)"
    }
}

extension RTCIceGatheringState: CustomStringConvertibleEnum {
    private static let descriptions: [RTCIceGatheringState: String] = [
        .new: "new",
        .gathering: "gathering",
        .complete: "complete"
    ]
    
    public var description: String {
        return RTCIceGatheringState.descriptions[self] ?? "Unknown \(self.rawValue)"
    }
}

extension RTCDataChannelState: CustomStringConvertibleEnum {
    private static let descriptions: [RTCDataChannelState: String] = [
        .connecting: "connecting",
        .open: "open",
        .closing: "closing",
        .closed: "closed"
    ]
    
    public var description: String {
        return RTCDataChannelState.descriptions[self] ?? "Unknown \(self.rawValue)"
    }
}


enum SdpType: String, Codable {
    case offer, prAnswer, answer, rollback
    
    var rtcSdpType: RTCSdpType {
        switch self {
        case .offer: return .offer
        case .answer: return .answer
        case .prAnswer: return .prAnswer
        case .rollback: return .rollback
        }
    }
}

struct SessionDescription: Codable {
    let sdp: String
    let type: SdpType
    
    init(from rtcSessionDescription: RTCSessionDescription) {
        self.sdp = rtcSessionDescription.sdp
        self.type = SdpType(rtcSessionDescriptionType: rtcSessionDescription.type)
    }
    
    var rtcSessionDescription: RTCSessionDescription {
        return RTCSessionDescription(type: self.type.rtcSdpType, sdp: self.sdp)
    }
}

extension SdpType {
    init(rtcSessionDescriptionType: RTCSdpType) {
        switch rtcSessionDescriptionType {
        case .offer: self = .offer
        case .prAnswer: self = .prAnswer
        case .answer: self = .answer
        case .rollback: self = .rollback
        @unknown default:
            fatalError("Unknown RTCSessionDescription type: \(rtcSessionDescriptionType.rawValue)")
        }
    }
}

struct IceCandidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
    
    init(from iceCandidate: RTCIceCandidate) {
        self.sdpMLineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
        self.sdp = iceCandidate.sdp
    }
    
    var rtcIceCandidate: RTCIceCandidate {
        return RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMLineIndex, sdpMid: self.sdpMid)
    }
}
