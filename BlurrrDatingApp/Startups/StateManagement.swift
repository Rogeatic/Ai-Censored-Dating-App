import Foundation
import WebRTC

extension RTCIceConnectionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .new:          return "new"
        case .checking:     return "checking"
        case .connected:    return "connected"
        case .completed:    return "completed"
        case .failed:       return "failed"
        case .disconnected: return "disconnected"
        case .closed:       return "closed"
        case .count:        return "count"
        @unknown default:   return "Unknown \(self.rawValue)"
        }
    }
}

extension RTCSignalingState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .stable:               return "stable"
        case .haveLocalOffer:       return "haveLocalOffer"
        case .haveLocalPrAnswer:    return "haveLocalPrAnswer"
        case .haveRemoteOffer:      return "haveRemoteOffer"
        case .haveRemotePrAnswer:   return "haveRemotePrAnswer"
        case .closed:               return "closed"
        @unknown default:   return "Unknown \(self.rawValue)"
        }
    }
}

extension RTCIceGatheringState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .new:          return "new"
        case .gathering:    return "gathering"
        case .complete:     return "complete"
        @unknown default:   return "Unknown \(self.rawValue)"
        }
    }
}

extension RTCDataChannelState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connecting:   return "connecting"
        case .open:         return "open"
        case .closing:      return "closing"
        case .closed:       return "closed"
        @unknown default:   return "Unknown \(self.rawValue)"
        }
    }
}

/// This enum is a swift wrapper over `RTCSdpType` for easy encode and decode
enum SdpType: String, Codable {
    case offer, prAnswer, answer, rollback
    
    var rtcSdpType: RTCSdpType {
        switch self {
        case .offer:    return .offer
        case .answer:   return .answer
        case .prAnswer: return .prAnswer
        case .rollback: return .rollback
        }
    }
}

/// This struct is a swift wrapper over `RTCSessionDescription` for easy encode and decode
struct SessionDescription: Codable {
    let sdp: String
    let type: SdpType
    
    init(from rtcSessionDescription: RTCSessionDescription) {
        self.sdp = rtcSessionDescription.sdp
        
        switch rtcSessionDescription.type {
        case .offer:    self.type = .offer
        case .prAnswer: self.type = .prAnswer
        case .answer:   self.type = .answer
        case .rollback: self.type = .rollback
        @unknown default:
            fatalError("Unknown RTCSessionDescription type: \(rtcSessionDescription.type.rawValue)")
        }
    }
    
    var rtcSessionDescription: RTCSessionDescription {
        return RTCSessionDescription(type: self.type.rtcSdpType, sdp: self.sdp)
    }
}

/// This struct is a swift wrapper over `RTCIceCandidate` for easy encode and decode
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
