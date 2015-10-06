//
//  MultipeerHost.h
//  Multipeer0220
//
//  Created by 椛島優 on 2015/02/20.
//  Copyright (c) 2015年 椛島優. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <AVFoundation/AVFoundation.h>
@interface MultipeerHost : NSObject<MCSessionDelegate,MCNearbyServiceAdvertiserDelegate,MCNearbyServiceBrowserDelegate>
@property MCPeerID *mPeerID;
@property MCSession *mSession;
//@property MCPeerID *mPeerID2;
//@property MCSession *mSession2;
@property MCNearbyServiceAdvertiser *nearbyAd;
@property NSMutableArray *connectedpeer;
//@property NSMutableArray *connectedpeer2;
@property NSArray *invitationArr;
@property BOOL leadership;
//@property BOOL boss;
@property MCNearbyServiceBrowser *browser;
@property NSString *recvStr;
@property int nowinvitees;
@property NSData *recvData;
@property BOOL solo;
-(void)startHost;
-(void)startClient;
-(void)stopHost;
-(void)stopClient;
-(void)sendStr:(NSString *)str;
-(void)sendList:(NSArray *)arr;
-(void)postNotification;
-(void)postNotificationc;

@end
