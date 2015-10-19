//
//  ESLpod.m
//  英語学習
//
//  Created by 金子誠也 on 2015/03/13.
//  Copyright (c) 2015年 金子誠也. All rights reserved.
//

#import "ESLpod.h"


@implementation ESLpod
-(void)audioSession{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers
                        error:&setCategoryError]) {}
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                        error:&setCategoryError]) {}
    
    [session setMode:AVAudioSessionModeVoiceChat error:nil];
    
    [session setActive:YES error:nil];
}


-(void)feed{
    //フィードバック部分
    NewAUGraph(&_auGraph);
    AUGraphOpen(_auGraph);
    
    AudioComponentDescription remoteDescription;
    remoteDescription.componentType = kAudioUnitType_Output;
    remoteDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    remoteDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    remoteDescription.componentFlags = remoteDescription.componentFlagsMask = 0;
    
    AUGraphAddNode(_auGraph, &remoteDescription, &_remoteIONode);
    AUGraphNodeInfo(_auGraph, _remoteIONode, NULL, &_remoteIOUnit);
    
    AudioComponentDescription mixerDescription;
    mixerDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixerDescription.componentType = kAudioUnitType_Mixer;
    mixerDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    
    AUGraphAddNode(_auGraph, &mixerDescription, &_mixNode);
    AUGraphNodeInfo(_auGraph, _mixNode, NULL, &_mixUnit);
    
    
    UInt32 flag = 1;                    //マイク入力をオンにする
    AudioUnitSetProperty(_remoteIOUnit,
                         kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input, //RemoteIOのInput
                         1,
                         &flag,
                         sizeof(UInt32));
    
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate = 44100;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved | (kAudioUnitSampleFractionBits << kLinearPCMFormatFlagsSampleFractionShift);
    asbd.mBitsPerChannel = 32;  //8*4
    asbd.mBytesPerFrame = 4;    //4=sizeof(SInt32)
    asbd.mBytesPerPacket = 4;
    asbd.mFramesPerPacket = 1;
    asbd.mChannelsPerFrame = 1;
    
    AudioUnitSetProperty(_remoteIOUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         1,
                         &asbd,
                         sizeof(asbd)
                         );
    
    AUGraphConnectNodeInput(_auGraph,
                            _remoteIONode, 1, //Remote Inputと
                            _mixNode, 0  //mixerを接続
                            );
    
    AUGraphConnectNodeInput(_auGraph,
                            _mixNode,0, //effectと
                            _remoteIONode, 0  //Remote Outputを接続
                            );
    
    AUGraphInitialize(_auGraph);
    AUGraphStart(_auGraph);
    
}

-(void)bufferSet{   //フィードバックの早さ変更
   
    UInt32 size1=sizeof(Float32);
    
    Float32 byte=128;
    Float32 duration=byte/44100;
    
    size1=sizeof(Float32);
   
    AVAudioSession *session=[AVAudioSession sharedInstance];
    [session setPreferredIOBufferDuration:duration error:nil];
    
    
   }

-(void)mixUnitvol{
    AudioUnitSetParameter(_mixUnit,
                          kMultiChannelMixerParam_Volume,
                          kAudioUnitScope_Input,
                          0,
                          _feedVol,
                          0);
    
}

-(void)allsongSet{
    MPMediaQuery *allsongs=[MPMediaQuery songsQuery];
    _allsongsItem=allsongs.items;
   // NSLog(@"全曲%@",_allsongsItem);
}

-(void)matchCheck{
        self.songs=[[NSArray alloc]init];
    for (int i=0; i<self.nameData.count; i++) {
        
        NSString*str=[self.nameData objectAtIndex:i];
        self.playlist=[[MPMediaQuery alloc]init];
        MPMediaPropertyPredicate *predicate;
        predicate=[MPMediaPropertyPredicate predicateWithValue:str forProperty:MPMediaItemPropertyTitle comparisonType:MPMediaPredicateComparisonEqualTo];
        
        [self.playlist addFilterPredicate:predicate];
        
        self.songs=[self.songs arrayByAddingObjectsFromArray:self.playlist.items];
      
    }
    [self setsong:0];
    
    
    

}
-(void)setsong:(NSInteger)number{
    if (self.playlist!=nil) {
        if (number<self.songs.count) {
            
            self.titleitem=self.songs[number];
            
        
        
        
        _item = self.songs[number];
        _url = [_item valueForProperty:MPMediaItemPropertyAssetURL];
        _playerItem = [[AVPlayerItem alloc] initWithURL:_url];    //変換
            if (_playerItem!=nil) {
                
            
        
        _avPlayer = [[AVQueuePlayer alloc] initWithPlayerItem:_playerItem];
        
            }
        }
        //[_searchplayer play];
        
    }

    
}
@end
