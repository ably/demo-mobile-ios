//
//  ChatViewController.swift
//  demo-ios
//
//  Created by Stan on 8/27/15.
//  Copyright (c) 2015 Ably. All rights reserved.
//

import Foundation
import ably
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    private var messages = [JSQMessage]();

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let clientOptions = ARTClientOptions(key: "xVLyHw.uLZGvg:KW-5NN-h0GYW0jqF")
        clientOptions.clientId = self.senderId
        
        let realtime = ARTRealtime(options: clientOptions)
        realtime.eventEmitter.on { (ARTRealtimeConnectionState state) -> Void in
            print(state.rawValue)
        }
        
        let channel = realtime.channel("mobile:chat")
        channel.subscribe { (ARTMessage msg) -> Void in
            let jsqMsg = JSQMessage(senderId: msg.clientId, displayName: msg.clientId, text: msg.payload.payload.description)
            self.messages.append(jsqMsg)
            self.collectionView.reloadData()
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
}