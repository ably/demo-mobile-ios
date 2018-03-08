import Foundation
import Ably

public protocol ChatModelDelegate {
    func chatModel(_ chatModel: ChatModel, connectionStateChanged: ARTConnectionStateChange)
    func chatModelLoadingHistory(_ chatModel: ChatModel)
    func chatModelDidFinishSendingMessage(_ chatModel: ChatModel)
    func chatModel(_ chatModel: ChatModel, didReceiveMessage message: ARTMessage)
    func chatModel(_ chatModel: ChatModel, didReceiveError error: ARTErrorInfo)
    func chatModel(_ chatModel: ChatModel, historyDidLoadWithMessages: [ARTBaseMessage])
    func chatModel(_ chatModel: ChatModel, membersDidUpdate: [ARTPresenceMessage], presenceMessage: ARTPresenceMessage)
}

open class ChatModel {
    fileprivate var ablyClientOptions: ARTClientOptions
    fileprivate var ablyRealtime: ARTRealtime?
    fileprivate var channel: ARTRealtimeChannel?
    fileprivate var isUserTyping = false
    
    open var clientId: String
    open var delegate: ChatModelDelegate?
    open var hasAppJoined = false
    
    public init(clientId: String) {
        self.clientId = clientId
        
        ablyClientOptions = ARTClientOptions()
        ablyClientOptions.authUrl = URL(string: "https://www.ably.io/ably-auth/token-details/demos")
        ablyClientOptions.clientId = clientId
        ablyClientOptions.logLevel = .verbose
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatModel.applicationWillResignActiveEventReceived(_:)),
                                                         name: NSNotification.Name(rawValue: "applicationWillResignActive"),
                                                         object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatModel.applicationWillEnterForegroundEventReceived(_:)),
                                                         name: NSNotification.Name(rawValue: "applicationWillEnterForeground"),
                                                         object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatModel.applicationWillEnterForegroundEventReceived(_:)),
                                                         name: NSNotification.Name(rawValue: "applicationDidBecomeActive"),
                                                         object: nil)
    }
    
    open func connect() {
        detachHandlers()
        
        self.ablyRealtime = ARTRealtime(options: self.ablyClientOptions)
        let realtime = self.ablyRealtime!
        
        realtime.connection.on { stateChange in
            if let stateChange = stateChange {
                self.delegate?.chatModel(self, connectionStateChanged: stateChange)
                
                switch stateChange.current {
                case .disconnected:
                    self.attemptReconnect(5000)
                case .suspended:
                    self.attemptReconnect(15000)
                default:
                    break
                }
            }
        }
        
        self.channel = realtime.channels.get("mobile:chat")
        self.joinChannel()
    }
    
    // Explicitly reconnect to Ably and joins channel
    open func reconnect() {
        self.connect()
    };
    
    // Leaves channel by disconnecting from Ably
    open func disconnect() {
        self.ablyRealtime?.connection.close()
    };

    open func publishMessage(_ message: String) {
        self.channel?.publish(self.clientId, data: message, clientId: self.clientId) { error in
            guard error == nil else {
                self.signalError(error!)
                return
            }
            
            self.delegate?.chatModelDidFinishSendingMessage(self)
        }
    }
    
    open func sendTypingNotification(_ typing: Bool) {
        // Don't send a 'is typing' notification if user is already typing
        if (self.isUserTyping && typing) {
            return;
        }
        
        self.channel?.presence.update(["isTyping": typing])
        self.isUserTyping = typing;
    }
    
    fileprivate func detachHandlers() {
        
    }
    
    fileprivate func attemptReconnect(_ delay: Double) {
        self.delay(delay) {
            self.ablyRealtime?.connect()
        }
    }
    
    fileprivate func joinChannel() {
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
        
        channel.once(.detached, callback: self.didChannelLoseState)
        channel.once(.failed, callback: self.didChannelLoseState)
    }
    
    fileprivate func membersChanged(_ msg: ARTPresenceMessage) {
        self.channel?.presence.get() { (result, error) in
            guard error == nil else {
                self.signalError(ARTErrorInfo.create(from: error!))
                return
            }
            
            let members = result ?? [ARTPresenceMessage]()
            self.delegate?.chatModel(self, membersDidUpdate: members, presenceMessage: msg)
        }
    }
    
    fileprivate func loadHistory() {
        var messageHistory: [ARTMessage]? = nil
        var presenceHistory: [ARTPresenceMessage]? = nil
        
        func displayIfReady() {
            guard messageHistory != nil && presenceHistory != nil else { return }

            var combinedMessageHistory = [ARTBaseMessage]()
            combinedMessageHistory.append(contentsOf: messageHistory! as [ARTBaseMessage])
            combinedMessageHistory.append(contentsOf: presenceHistory! as [ARTBaseMessage])
            combinedMessageHistory.sort(by: { (msg1, msg2) -> Bool in
                return msg1.timestamp!.compare(msg2.timestamp!) == .orderedAscending
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
    
    fileprivate func getMessagesHistory(_ callback: @escaping ([ARTMessage]) -> Void) {
        do {
            try self.channel!.history(self.createHistoryQueryOptions()) { (result, error) in
                guard error == nil else {
                    self.signalError(ARTErrorInfo.create(from: error!))
                    return
                }
                
                let items = result?.items ?? [ARTMessage]()
                callback(items)
            }
        }
        catch let error as NSError {
            self.signalError(ARTErrorInfo.create(from: error))
        }
    }
    
    fileprivate func getPresenceHistory(_ callback: @escaping ([ARTPresenceMessage]) -> Void) {
        do {
            try self.channel!.presence.history(self.createHistoryQueryOptions()) { (result, error) in
                guard error == nil else {
                    self.signalError(ARTErrorInfo.create(from: error!))
                    return
                }
                
                let items = result?.items ?? [ARTPresenceMessage]()
                callback(items)
            }
        }
        catch let error as NSError {
            self.signalError(ARTErrorInfo.create(from: error))
        }
    }

    fileprivate func createHistoryQueryOptions() -> ARTRealtimeHistoryQuery {
        let query = ARTRealtimeHistoryQuery()
        query.limit = 50
        query.direction = .backwards
        query.untilAttach = true
        return query
    }

    @objc func didChannelLoseState(_ stateChange: ARTChannelStateChange?) {
        self.channel?.unsubscribe()
        self.channel?.presence.unsubscribe()
        self.ablyRealtime?.connection.once(.connected) { state in
            self.joinChannel()
        }
    }
    
    fileprivate func signalError(_ error: ARTErrorInfo) {
        self.delegate?.chatModel(self, didReceiveError: error)
    }
    
    fileprivate func delay(_ delay: Double, block: @escaping () -> Void) {
        let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: block)
    }

    @objc fileprivate func applicationWillResignActiveEventReceived(_ notification: Notification) {
        self.disconnect()
    }
    
    @objc fileprivate func applicationWillEnterForegroundEventReceived(_ notification: Notification) {
        self.reconnect()
    }
}
