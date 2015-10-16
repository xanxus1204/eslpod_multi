//
//  MultipeerHost.m
//  Multipeer0220
//
//  Created by 椛島優 on 2015/02/20.
//  Copyright (c) 2015年 椛島優. All rights reserved.
//
//８人までに限定してつくる。

#import "MultipeerHost.h"


@implementation MultipeerHost

NSArray *invitationArr;
int leadercount;
-(void)startClient{
    if (self.connectedpeer.count==0) {
    self.connectedpeer=[[NSMutableArray alloc]init];
    self.mPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice]name]];
    //セッションを初期化
    self.mSession= [[MCSession alloc] initWithPeer:self.mPeerID];
    //デリゲートを設定
    self.mSession.delegate = self;
    
    self.nearbyAd=[[MCNearbyServiceAdvertiser alloc]initWithPeer:self.mPeerID discoveryInfo:nil serviceType:@"kurumecs"];
    self.nearbyAd.delegate=self;
    [self.nearbyAd startAdvertisingPeer];
        
        leadercount=0;
    }
   
    
}
-(void)startHost{
    self.nowinvitees=0;
    [self.nearbyAd stopAdvertisingPeer];
    if (self.browser==nil) {
    self.browser = [[MCNearbyServiceBrowser alloc]
                    initWithPeer:self.mPeerID
                    serviceType:@"kurumecs"];
    
    
    self.browser.delegate = self;
    }
    
    [self.browser startBrowsingForPeers];
    
   
    

}
-(id)init{
    if (self=[super init]){
        _leadership=NO;
        self.solo=YES;
       
    }
    return  self;
}
//Multipeer Connectivity delegate
// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    
    if (state==MCSessionStateConnected) {
        NSLog(@"接続完了");
        self.solo=NO;
        [self  stopClient];
        if (!([self.connectedpeer containsObject:peerID])) {
            
            [self.connectedpeer addObject:peerID];
            [self postNotificationc];

            
            
            self.nowinvitees--;
            
        }
    }
    if (state==MCSessionStateNotConnected) {
        NSLog(@"抜けた");
        [self.connectedpeer removeObject:peerID];
        if (self.connectedpeer.count==0) {
            self.solo=YES;
        }
        [self postNotificationc];
        
        
    }
    
}

// Received data from remote peer
-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSFileHandle *fileHandle ;
    if (self.count==0) {
        
        self.count++;
       
        // ディレクトリを作成
        [fileManager createDirectoryAtPath:docDir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
        docDir=[docDir stringByAppendingString:@"aaa.aif"];
       
        [self fileCreate:docDir andData:data];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:docDir];
        NSURL *url=[[NSURL alloc]initWithString:docDir];
        AVAudioPlayer *player=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
        [player play];
        
        // ファイルハンドルを作成する
        
    }
        else{
        [fileHandle writeData:data];
        
        // 効率化のためにすぐにファイルに書き込まれずキャッシュされることがある．
        // 「synchronizeFile」メソッドを使用することで
        // キャッシュされた情報を即座に書き込むことが可能．
        [fileHandle synchronizeFile];
        
        // ファイルを閉じる
        [fileHandle closeFile];
        }
   
}




-(void)sendStr:(NSString *)str{
    
    if ([str isEqualToString:@"leadus"]) {
        
        NSData*keyData=[str dataUsingEncoding:NSUTF8StringEncoding];
        NSArray*temparr=[[NSArray alloc]init];
        temparr=[temparr arrayByAddingObject:[self.connectedpeer objectAtIndex:leadercount]];
        leadercount++;
                    [self.mSession sendData:keyData
                                    toPeers:temparr
                                   withMode:MCSessionSendDataReliable
                                      error:nil];

    }else{
    NSData*keyData=[str dataUsingEncoding:NSUTF8StringEncoding];
    [self.mSession sendData:keyData
                   toPeers:self.connectedpeer
                  withMode:MCSessionSendDataReliable
                     error:nil];
      
    }
    
        

    
}
-(void)sendList:(NSArray *)arr{
    NSData*keyData=[NSKeyedArchiver archivedDataWithRootObject:arr];
    [self.mSession sendData:keyData toPeers:self.connectedpeer withMode:MCSessionSendDataReliable error:nil];
}

//MCNearByBrowser delegate
// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info{
    
    if (self.nowinvitees==7){
        
    }else{
        
    
        
    [browser invitePeer:peerID
              toSession:self.mSession //要変更か　インスタンスを新しく用意する手法に変更。
            withContext:nil
                timeout:0];//30s
    self.nowinvitees++;
    
    }
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
    
}

// Incoming invitation request.  Call the invitationHandler block with YES and a valid session to connect the inviting peer to the session.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler{
    
    invitationArr=[NSArray arrayWithObject:[invitationHandler copy]];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"同時再生"
                              message:@"参加しますか？"
                              delegate:self
                              cancelButtonTitle:@"拒否"
                              otherButtonTitles:@"参加", nil];
                              // present alert view
                              [alertView show];
    
    
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // retrieve the invitationHandler
    // get user decision
    BOOL accept = (buttonIndex != alertView.cancelButtonIndex) ? YES : NO;
    if(accept) {
        void (^invitationHandler)(BOOL, MCSession *) = [invitationArr objectAtIndex:0];
        invitationHandler(accept, self.mSession);
        NSLog(@"いいよ");
    }
    else
    {
        NSLog(@"Session disallowed");
        
    }

    // respond
    
}


-(void)postNotification
{
    //
    NSNotificationCenter *nc =
    [NSNotificationCenter defaultCenter];
    
    // 通知する
    [nc postNotificationName:@"recv"
                      object:self
                    userInfo:nil];
}



-(void)postNotificationc
{
    NSNotificationCenter *nc =
    [NSNotificationCenter defaultCenter];
    
    // 通知する
    [nc postNotificationName:@"conn"
                      object:self
                    userInfo:nil];

}

-(void)stopClient{
    [self.nearbyAd stopAdvertisingPeer];
    self.nearbyAd.delegate=nil;
    
}


-(void)stopHost{
     [self.browser stopBrowsingForPeers];
    self.browser.delegate=nil;
}






// require delegate method

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    
}
-(BOOL)fileCreate:(NSString *)path andData:(NSData *)data{
    NSFileManager *fm=[NSFileManager defaultManager];
    BOOL flag=[fm createFileAtPath:path contents:data attributes:nil];
    
    NSData*lastdata=[fm contentsAtPath:path];
    NSLog(@"ファイルおわり%ld",(unsigned long)lastdata.length);
    return flag;
}

@end
