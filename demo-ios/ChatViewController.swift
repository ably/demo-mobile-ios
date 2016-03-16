import Foundation
import JSQMessagesViewController
import Ably

class ChatViewController: JSQMessagesViewController {
    private var messages = [JSQMessage]()
    private var realtime: ARTRealtime!
    private var channel: ARTRealtimeChannel!
    private var model: ChatModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.model = ChatModel(clientId: self.senderId)
        self.model.delegate = self
        self.model.connect()
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let msgCount = messages.count
        return msgCount
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        let item = indexPath.item
        let msg = messages[item]
        return msg
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.grayColor())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        return JSQMessagesAvatarImageFactory.avatarImageWithUserInitials("FF", backgroundColor: UIColor.blackColor(), textColor: UIColor.whiteColor(), font: UIFont.systemFontOfSize(10), diameter: 40)
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let jsqMsg = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        self.messages.append(jsqMsg)
        self.finishSendingMessageAnimated(true)
    }
    
    func clearMessages() {
        self.messages.removeAll()
        self.collectionView?.reloadData()
    }
    
    func showNotice(type: String, message: String?) {
        let controller = UIAlertController(title: type, message: message, preferredStyle: .ActionSheet)
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func hideNotice(type: String) {
        if let controller = self.presentedViewController {
            controller.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func prependHistoricalMessages(messages: [ARTBaseMessage]) {
        for msg in messages {
            if let presenceMsg = msg as? ARTPresenceMessage {
                let jsqMsg = JSQMessage(senderId: self.model.clientId,
                                        displayName: self.model.clientId,
                                        text: "\(presenceMsg.clientId!) \(presenceActionDescription(presenceMsg.action)) channel")
                self.messages.append(jsqMsg)
            }
        }
        
        self.collectionView?.reloadData()
    }
    
    func showError(error: String) {
        let alert = UIAlertController(title: "Alert", message: error, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func presenceActionDescription(presenceAction: ARTPresenceAction) -> String {
        switch presenceAction {
        case .Enter:
            return "entered"
        case .Leave:
            return "left"
        default:
            return ""
        }
    }
}

extension ChatViewController: ChatModelDelegate {
    func chatModel(chatModel: ChatModel, connectionStateChanged: ARTConnectionStateChange) {
        
    }
    
    func chatModel(chatModel: ChatModel, didReceiveError error: ARTErrorInfo) {
        self.showError(error.message)
    }
    
    func chatModel(chatModel: ChatModel, didReceiveMessage message: ARTMessage) {
        
    }
    
    func chatModelLoadingHistory(chatModel: ChatModel) {
        self.showNotice("loading", message: "'Hang on a sec, loading the chat history...")
        self.clearMessages()
    }
    
    func chatModel(chatModel: ChatModel, historyDidLoadWithMessages messages: [ARTBaseMessage]) {
        self.hideNotice("loading")
        self.prependHistoricalMessages(messages)
    }
    
    func chatModel(chatModel: ChatModel, membersDidUpdate: [ARTPresenceMessage], presenceMessage: ARTPresenceMessage) {
        /*
        addToMessageList(presencePartial(presenceMessage));
        updateMembers(members);
        */
    }
}