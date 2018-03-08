import Foundation
import Ably
import UIKit
import IHKeyboardAvoiding

class ChatViewController: UIViewController {
    fileprivate var messages = [ARTBaseMessage]()
    fileprivate var realtime: ARTRealtime!
    fileprivate var channel: ARTRealtimeChannel!
    fileprivate var model: ChatModel!
    fileprivate var members: [ARTPresenceMessage] = [ARTPresenceMessage]()
    
    @IBOutlet weak var statusContainer: UIView!

    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var statusText: UILabel!
    @IBOutlet weak var statusIcon: UILabel!
    @IBOutlet weak var messagesTableView: UITableView!
    @IBOutlet weak var membersCountLabel: UILabel?
    var clientId: String!
    
    @IBAction func userTyping(_ sender: AnyObject) {
        self.model.sendTypingNotification(true)
    }
    
    @IBAction func userDidSendMessage(_ sender: AnyObject) {
        if let messageTextField = sender as? UITextField, let text = messageTextField.text{
            if text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
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
        
        KeyboardAvoiding.avoidingView = self.view
        
        self.model = ChatModel(clientId: self.clientId)
        self.model.delegate = self
        self.model.connect()
    }
    
    func clearMessages() {
        self.messages.removeAll()
        self.messagesTableView.reloadData()
    }
    
    func showNotice(_ type: String, message: String?) {
        self.statusContainer.isHidden = false
        self.statusText.text =  message
        self.statusIcon.text = "\u{E600}"
    }
    
    func hideNotice(_ type: String) {
        self.statusContainer.isHidden = true
    }
    
    func prependHistoricalMessages(_ messages: [ARTBaseMessage]) {
        for msg in messages {
            if let presenceMsg = msg as? ARTPresenceMessage {
                if presenceMsg.action == .enter || presenceMsg.action == .leave {
                    self.messages.append(presenceMsg)
                }
            }
            
            if let chatMsg = msg as? ARTMessage {
                self.messages.append(chatMsg)
            }
        }
        
        self.messages.sort { (msg1, msg2) -> Bool in
            return msg1.timestamp!.compare(msg2.timestamp!) == .orderedAscending
        }
        
        self.messagesTableView.reloadData()
    }
    
    func showError(_ error: String) {
        let alert = UIAlertController(title: "Alert", message: error, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func handleMembersContainerTap(_ sender: AnyObject) {
        let controller = UIAlertController(title: "Handles", message: nil, preferredStyle: .actionSheet)
        for member in self.members {
            let action = UIAlertAction(title: member.clientId, style: .default, handler: { action -> Void in
                self.messageTextField.text! += "@\(action.title!) "
            })
            controller.addAction(action)
        }
        self.present(controller, animated: true, completion: nil)
    }
    
    fileprivate func descriptionForPresenceAction(_ presenceAction: ARTPresenceAction) -> String {
        switch presenceAction {
        case .enter:
            return "entered"
        case .leave:
            return "left"
        default:
            return ""
        }
    }
    
    fileprivate func updateMembers(_ members: [ARTPresenceMessage]) {
        self.membersCountLabel?.text = "\(members.count)"
        // TODO: implement rest of logic
    }
}

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.messages[indexPath.row] is ARTMessage {
            return 85;
        }
        
        return 35;
    }
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let message = self.messages[indexPath.row] as? ARTMessage {
            if message.clientId == self.clientId {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageMe") as? ChatMessageMeCell {
                    cell.dateText?.text = message.timestamp!.formatAsShortDate()
                    cell.messageText?.text = message.data as? String
                    return cell
                }
            } else {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageNotMe") as? ChatMessageNotMeCell {
                    cell.messageText?.text = message.data as? String
                    cell.dateText?.text = message.timestamp!.formatAsShortDate()
                    cell.handleText?.text = message.clientId
                    return cell
                }
            }
        }

        if let presenceMessage = self.messages[indexPath.row] as? ARTPresenceMessage {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PresenceMessage") as? PresenceMessageCell {
                let dateText = presenceMessage.timestamp!.formatAsShortDate()
                if(presenceMessage.action == .leave || presenceMessage.action == .enter) {
                    cell.presenceText?.text = "\(presenceMessage.clientId!) \(self.descriptionForPresenceAction(presenceMessage.action)) the channel \(dateText)"
                    return cell
                }

                return cell
            }
        }
        
        return tableView.dequeueReusableCell(withIdentifier: "")!
    }
    
    func scrollToBottom(_ tableView: UITableView) {
        let tableRows = tableView.numberOfRows(inSection: 0)
        if tableRows > 0
        {
            let lastMessageIndex = tableRows - 1
            let lastMessageIndexPath = IndexPath(row: lastMessageIndex, section: 0)
            tableView.scrollToRow(at: lastMessageIndexPath, at: .bottom, animated: true)
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

extension Date {
    func formatAsShortDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        
        let dateText = dateFormatter.string(from: self).lowercased()
        return dateText
    }
}

extension ChatViewController: ChatModelDelegate {
    func chatModel(_ chatModel: ChatModel, connectionStateChanged: ARTConnectionStateChange) {
        
    }
    
    func chatModel(_ chatModel: ChatModel, didReceiveError error: ARTErrorInfo) {
        self.showError(error.message)
    }
    
    func chatModel(_ chatModel: ChatModel, didReceiveMessage message: ARTMessage) {
        self.messages.append(message)
        self.messagesTableView.reloadData()
        self.scrollToBottom(self.messagesTableView)
    }
    
    func chatModelDidFinishSendingMessage(_ chatModel: ChatModel) {
        self.hideNotice("sending")
    }
    
    func chatModelLoadingHistory(_ chatModel: ChatModel) {
        self.showNotice("loading", message: "Hang on a sec, loading the chat history...")
        self.clearMessages()
    }
    
    func chatModel(_ chatModel: ChatModel, historyDidLoadWithMessages messages: [ARTBaseMessage]) {
        self.hideNotice("loading")
        self.prependHistoricalMessages(messages)
        self.scrollToBottom(self.messagesTableView)
    }
    
    func chatModel(_ chatModel: ChatModel, membersDidUpdate members: [ARTPresenceMessage], presenceMessage: ARTPresenceMessage) {
        guard presenceMessage.action != .update else { return }

        self.members = members
        
        self.messages.append(presenceMessage)
        self.messagesTableView.reloadData()
        self.updateMembers(members)
    }
}
