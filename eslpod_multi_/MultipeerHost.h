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
@property MCNearbyServiceAdvertiser *nearbyAd;
@property NSMutableArray *connectedpeer;
@property NSArray *invitationArr;
@property BOOL leadership;
@property MCNearbyServiceBrowser *browser;
@property NSString *recvStr;
@property int nowinvitees;
@property NSMutableData *recvData;
@property BOOL solo;
@property int count;

@property NSString * musicPath;
-(void)startHost;
-(void)startClient;
-(void)stopHost;
-(void)stopClient;
-(void)sendStr:(NSString *)str;
-(void)sendList:(NSArray *)arr;
-(void)postNotification;
-(void)postNotificationc;
-(BOOL)fileCreate:(NSString *)path andData:(NSData*)data;

@end
