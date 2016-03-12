import Foundation

public class ChatMessage {
    public var sender: String
    
    public init(sender: String) {
        self.sender = sender
    }
}

class PresenceMessage {
    
}

public class CombinedMessagesDataSource {
}

public protocol ChatModelDelegate {
    func chatModel(chatModel: ChatModel, connectionStateChanged: ARTConnectionStateChange)
    func chatModelLoadingHistory(chatModel: ChatModel)
    func chatModel(chatModel: ChatModel, didReceiveMessage message: ARTMessage)
    func chatModel(chatModel: ChatModel, didReceiveError error: ARTErrorInfo)
    func chatModel(chatModel: ChatModel, historyDidLoadWithMessages: [ARTBaseMessage])
}

public class ChatModel {
    private var ablyClientOptions: ARTClientOptions
    private var ablyRealtime: ARTRealtime?
    private var channel: ARTRealtimeChannel?
    
    public var clientId: String
    public var delegate: ChatModelDelegate?
    public var hasAppJoined = false
    
    public init(clientId: String) {
        self.clientId = clientId
        
        ablyClientOptions = ARTClientOptions()
        ablyClientOptions.authUrl = NSURL(string: "https://www.ably.io/ably-auth/token-details/demos")
        ablyClientOptions.clientId = clientId
        ablyClientOptions.logLevel = .Verbose
    }
    
    public func connect() {
        detachHandlers()
        
        self.ablyRealtime = ARTRealtime(options: self.ablyClientOptions)
        let realtime = self.ablyRealtime!
        
        realtime.connection.on { stateChange in
            if let stateChange = stateChange {
                self.delegate?.chatModel(self, connectionStateChanged: stateChange)
                
                switch stateChange.current {
                case .Disconnected:
                    self.attemptReconnect(5000)
                case .Suspended:
                    self.attemptReconnect(15000)
                default:
                    break
                }
            }
        }
        
        self.channel = realtime.channels.get("mobile:chat")
        self.joinChannel()
    }
    
    private func detachHandlers() {
        
    }
    
    private func attemptReconnect(delay: Double) {
        self.delay(delay) {
            self.ablyRealtime?.connect()
        }
    }
    
    private func joinChannel() {
        guard let channel = self.channel else { return }
        let presence = channel.presence

        self.delegate?.chatModelLoadingHistory(self)
        channel.attach()
        
        channel.subscribe { self.delegate?.chatModel(self, didReceiveMessage: $0) }
        presence.subscribe(self.membersChanged)
        
        presence.enter(nil) { error in
            guard error == nil else {
                self.signalError(error!)
                return
            }
            
            self.loadHistory()
        }
        
        channel.once(ARTChannelEvent.Detached, call: self.didChannelLoseState)
        channel.once(ARTChannelEvent.Failed, call: self.didChannelLoseState)
    }
    
    private func membersChanged(msg: ARTPresenceMessage) {
        
    }
    
    private func loadHistory() {
        var messageHistory: [ARTMessage]? = nil
        var presenceHistory: [ARTPresenceMessage]? = nil
        
        func displayIfReady() {
            guard messageHistory != nil && presenceHistory != nil else { return }

            var combinedMessageHistory = [ARTBaseMessage]()
            combinedMessageHistory.appendContentsOf(messageHistory! as [ARTBaseMessage])
            combinedMessageHistory.appendContentsOf(presenceHistory! as [ARTBaseMessage])
            combinedMessageHistory.sortInPlace({ (msg1, msg2) -> Bool in
                return msg1.timestamp.compare(msg2.timestamp) == .OrderedAscending
            })
            
            self.delegate?.chatModel(self, historyDidLoadWithMessages: combinedMessageHistory)
       };
        
        self.getMessagesHistory { messages in
            messageHistory = messages;
            displayIfReady();
        }
        
        self.getPresenceHistory { presenceMessages in
            presenceHistory = presenceMessages;
            displayIfReady();
        }
    }
    
    private func getMessagesHistory(callback: [ARTMessage] -> Void) {
    
    }
    
    private func getPresenceHistory(callback: [ARTPresenceMessage] -> Void) {
    
    }
    
    private func didChannelLoseState(error: ARTErrorInfo?) {
    
    }
    
    private func signalError(error: ARTErrorInfo) {
        self.delegate?.chatModel(self, didReceiveError: error)
    }
    
    private func delay(delay: Double, block: () -> Void) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), block)
    }
}