import Foundation
import AblyRealtime
import UIKit
import IHKeyboardAvoiding

class ChatViewController: UIViewController {
    private var messages = [ARTBaseMessage]()
    private var realtime: ARTRealtime!
    private var channel: ARTRealtimeChannel!
    private var model: ChatModel!
    private var members: [ARTPresenceMessage] = [ARTPresenceMessage]()
    
    @IBOutlet weak var statusContainer: UIView!

    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var statusText: UILabel!
    @IBOutlet weak var statusIcon: UILabel!
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var membersCountLabel: UILabel?
    var clientId: String!
    
    @IBAction func userTyping(sender: AnyObject) {
        self.model.sendTypingNotification(true)
    }
    
    @IBAction func userDidSendMessage(sender: AnyObject) {
        if let messageTextField = sender as? UITextField, text = messageTextField.text{
            if text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).isEmpty {
                return
            }
            
            messageTextField.text = nil
            messageTextField.becomeFirstResponder()
            
            self.showNotice("sending", message: "Sending message")
            self.model.publishMessage(text)
            self.model.sendTypingNotification(false)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        IHKeyboardAvoiding.setAvoidingView(self.view)
        
        self.model = ChatModel(clientId: self.clientId)
        self.model.delegate = self
        self.model.connect()
    }
    
    func clearMessages() {
        self.messages.removeAll()
        self.messagesTableView.reloadData()
    }
    
    func showNotice(type: String, message: String?) {
        self.statusContainer.hidden = false
        self.statusText.text =  message
        self.statusIcon.text = "\u{E600}"
    }
    
    func hideNotice(type: String) {
        self.statusContainer.hidden = true
    }
    
    func prependHistoricalMessages(messages: [ARTBaseMessage]) {
        for msg in messages {
            if let presenceMsg = msg as? ARTPresenceMessage {
                if presenceMsg.action == .Enter || presenceMsg.action == .Leave {
                    self.messages.append(presenceMsg)
                }
            }
            
            if let chatMsg = msg as? ARTMessage {
                self.messages.append(chatMsg)
            }
        }
        
        self.messages.sortInPlace { (msg1, msg2) -> Bool in
            return msg1.timestamp!.compare(msg2.timestamp!) == .OrderedAscending
        }
        
        self.messagesTableView.reloadData()
    }
    
    func showError(error: String) {
        let alert = UIAlertController(title: "Alert", message: error, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func handleMembersContainerTap(sender: AnyObject) {
        let controller = UIAlertController(title: "Handles", message: nil, preferredStyle: .ActionSheet)
        for member in self.members {
            let action = UIAlertAction(title: member.clientId, style: .Default, handler: { action -> Void in
                self.messageTextField.text! += "@\(action.title!) "
            })
            controller.addAction(action)
        }
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    private func descriptionForPresenceAction(presenceAction: ARTPresenceAction) -> String {
        switch presenceAction {
        case .Enter:
            return "entered"
        case .Leave:
            return "left"
        default:
            return ""
        }
    }
    
    private func updateMembers(members: [ARTPresenceMessage]) {
        self.membersCountLabel?.text = "\(members.count)"
        // TODO: implement rest of logic
    }
}

extension ChatViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if self.messages[indexPath.row] is ARTMessage {
            return 85;
        }
        
        return 35;
    }
}

extension ChatViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let message = self.messages[indexPath.row] as? ARTMessage {
            if message.clientId == self.clientId {
                if let cell = tableView.dequeueReusableCellWithIdentifier("ChatMessageMe") as? ChatMessageMeCell {
                    cell.dateText?.text = message.timestamp!.formatAsShortDate()
                    cell.messageText?.text = message.data?.description
                    return cell
                }
            } else {
                if let cell = tableView.dequeueReusableCellWithIdentifier("ChatMessageNotMe") as? ChatMessageNotMeCell {
                    cell.messageText?.text = message.data?.description
                    cell.dateText?.text = message.timestamp!.formatAsShortDate()
                    cell.handleText?.text = message.clientId
                    return cell
                }
            }
        }

        if let presenceMessage = self.messages[indexPath.row] as? ARTPresenceMessage {
            if let cell = tableView.dequeueReusableCellWithIdentifier("PresenceMessage") as? PresenceMessageCell {
                let dateText = presenceMessage.timestamp!.formatAsShortDate()
                if(presenceMessage.action == ARTPresenceAction.Leave || presenceMessage.action == .Enter) {
                    cell.presenceText?.text = "\(presenceMessage.clientId!) \(self.descriptionForPresenceAction(presenceMessage.action)) the channel \(dateText)"
                    return cell
                }

                return cell
            }
        }
        
        return tableView.dequeueReusableCellWithIdentifier("")!
    }
    
    func scrollToBottom(tableView: UITableView) {
        let tableRows = tableView.numberOfRowsInSection(0)
        if tableRows > 0
        {
            let lastMessageIndex = tableRows - 1
            let lastMessageIndexPath = NSIndexPath(forRow: lastMessageIndex, inSection: 0)
            tableView.scrollToRowAtIndexPath(lastMessageIndexPath, atScrollPosition: .Bottom, animated: true)
        }
    }
}

class PresenceMessageCell: UITableViewCell {
    @IBOutlet weak var presenceText: UILabel!
}

class ChatMessageMeCell: UITableViewCell {
    @IBOutlet weak var dateText: UILabel!
    @IBOutlet weak var messageText: UILabel!
    @IBOutlet weak var background: UIImageView!
    
    func ChatMessageCell() {
        
    }
}

class ChatMessageNotMeCell: UITableViewCell {
    @IBOutlet weak var messageText: UILabel!
    @IBOutlet weak var dateText: UILabel!
    @IBOutlet weak var handleText: UILabel!
}

extension NSDate {
    func formatAsShortDate() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.dateStyle = .ShortStyle
        
        let dateText = dateFormatter.stringFromDate(self).lowercaseString
        return dateText
    }
}

extension ChatViewController: ChatModelDelegate {
    func chatModel(chatModel: ChatModel, connectionStateChanged: ARTConnectionStateChange) {
        
    }
    
    func chatModel(chatModel: ChatModel, didReceiveError error: ARTErrorInfo) {
        self.showError(error.message)
    }
    
    func chatModel(chatModel: ChatModel, didReceiveMessage message: ARTMessage) {
        self.messages.append(message)
        self.messagesTableView.reloadData()
        self.scrollToBottom(self.messagesTableView)
    }
    
    func chatModelDidFinishSendingMessage(chatModel: ChatModel) {
        self.hideNotice("sending")
    }
    
    func chatModelLoadingHistory(chatModel: ChatModel) {
        self.showNotice("loading", message: "Hang on a sec, loading the chat history...")
        self.clearMessages()
    }
    
    func chatModel(chatModel: ChatModel, historyDidLoadWithMessages messages: [ARTBaseMessage]) {
        self.hideNotice("loading")
        self.prependHistoricalMessages(messages)
        self.scrollToBottom(self.messagesTableView)
    }
    
    func chatModel(chatModel: ChatModel, membersDidUpdate members: [ARTPresenceMessage], presenceMessage: ARTPresenceMessage) {
        guard presenceMessage.action != .Update else { return }

        self.members = members
        
        self.messages.append(presenceMessage)
        self.messagesTableView.reloadData()
        self.updateMembers(members)
    }
}