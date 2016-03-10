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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let clientOptions = ARTClientOptions()
        clientOptions.authUrl = NSURL(string: "https://www.ably.io/ably-auth/token-request/demos")
        clientOptions.clientId = self.senderId
        clientOptions.logLevel = .Verbose
        
        self.realtime = ARTRealtime(options: clientOptions)
        self.channel = realtime.channels.get("mobile:chat")
        self.realtime.connection.on { stateChange in
            if stateChange?.current == .Connected {
                self.getHistory();
            }
            
            if stateChange?.current == .Failed {
                self.showError(stateChange!.reason!.description())
            }
        }
        
        channel.subscribe { msg in
            let jsqMsg = JSQMessage(senderId: msg.clientId, displayName: msg.clientId, text: msg.data?.description)
            self.messages.append(jsqMsg)
            self.collectionView!.reloadData()
        }
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
    
    func getHistory() {
        self.channel.history { (result, errorArg) in
            if let error = errorArg {
                self.showError(error.description)
            }
            else {
                print(result)
            }
        }
    }
    
    func showError(error: String) {
        let alert = UIAlertController(title: "Alert", message: error, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}