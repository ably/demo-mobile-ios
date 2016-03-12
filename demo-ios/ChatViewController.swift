//
//  ChatViewController.swift
//  demo-ios
//
//  Created by Stan on 8/27/15.
//  Copyright (c) 2015 Ably. All rights reserved.
//

import Foundation
import JSQMessagesViewController
import Ably

class ChatViewController: JSQMessagesViewController {
    private var messages = [JSQMessage]()
    private var realtime: ARTRealtime!
    private var channel: ARTRealtimeChannel!
    private var model: ChatModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.model = ChatModel(clientId: self.senderId)
        self.model!.delegate = self
        self.model!.connect()
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
        return nil
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let jsqMsg = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        self.messages.append(jsqMsg)
        self.finishSendingMessageAnimated(true)
    }
    
    
    func clearMessages() {
        
    }
    
    func showNotice(type: String, b: String?) {
        
    }
    
    func hideNotice(type: String) {
        
    }
    
    func prependHistoricalMessages(messages: [ARTBaseMessage]) {
        
    }
    
    func showError(error: String) {
        let alert = UIAlertController(title: "Alert", message: error, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
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
        self.showNotice("loading", b: "'Hang on a sec, loading the chat history...")
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