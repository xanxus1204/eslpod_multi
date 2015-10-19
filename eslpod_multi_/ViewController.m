#import "ViewController.h"

@implementation ViewController
float ipodVol=0.01;
float systemVol=0;
int songCount=0;
int second,minute,maxsecond,maxminute,playback;
///aaa

- (void)viewDidLoad
{
    [super viewDidLoad];
    //監視スレ
    
     self.playcontroller=[MPMusicPlayerController applicationMusicPlayer];
    
    myHost=[[MultipeerHost alloc]init];
    [myHost startClient];
    myHost.count=0;
    
    NSNotificationCenter *nc =
    [NSNotificationCenter defaultCenter];
    
    // 通知センターにオブザーバ（通知を受け取るオブジェクト）を追加
    [nc addObserver:self
           selector:@selector(receive:)
               name:@"recv"
             object:myHost];
    [nc addObserver:self
           selector:@selector(connect:)
               name:@"conn"
             object:myHost];
    [nc addObserver:self
           selector:@selector(sendbuff:)
               name:@"buff"
             object:_queue];

    UIImage *imageForThumb = [UIImage imageNamed:@"slider.png"];
    [autoseek setThumbImage:imageForThumb forState:UIControlStateNormal];
    [autoseek setThumbImage:imageForThumb forState:UIControlStateHighlighted];
    [self.view addSubview:autoseek];
    
    ttableView.delegate = self;
    ttableView.dataSource = self;
    
    mypod=[[ESLpod alloc]init];
    [mypod audioSession];

    
   [mypod feed];
    [mypod bufferSet];
    [mypod allsongSet];
    //音楽プレーヤー部分
    _player = [MPMusicPlayerController applicationMusicPlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeAudioSessionRoute:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(avPlayDidFinish:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_playerItem];

    
    ///前回のスラいだー値反映
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    
    ipodVol = [ud floatForKey:@"ipodvol"];
    mypod.avPlayer.volume=ipodVol;
    NSString *ipodVoltext = [NSString stringWithFormat:@"%.0f", ipodVol*2000];
    ipodVolLabel.text=ipodVoltext;
    _ipodvol.value=ipodVol;
    
    mypod.feedVol=[ud floatForKey:@"feedvol"];
    [mypod mixUnitvol];
    NSString *fbVoltext = [NSString stringWithFormat:@"%.0f", mypod.feedVol*100];
    fbVolLabel.text=fbVoltext;
    _feedvol.value=mypod.feedVol;
    mypod.avPlayer.volume=ipodVol;
    [self startTimer];


}




- (void)avPlayDidFinish:(NSNotification*)notification
{
    if(myHost.solo){
        if(_mediaItemCollection2.count != 0){               //１曲以上選ばれているか
            if (songCount==_mediaItemCollection2.count-1) {//最後なら1曲目へ
                
                songCount=0;
                [self saveCount];
               [self AutoScroll:songCount];
               
               
                [self nextandback];
                 [mypod.avPlayer play];
            }
            else{           //次の曲へ
                songCount++;
                [self AutoScroll:songCount];
                [self saveCount];
                [self nextandback];
                [mypod.avPlayer play];
                [self imagechangeto:@"pause"];
            }
            
        }

        
   
    }else{
        //[[NSNotificationCenter defaultCenter] removeObserver:self];
        if(mypod.songs.count != 0){               //１曲以上選ばれているか
            if (songCount==mypod.songs.count-1) {//最後なら1曲目へ
                
                songCount=0;
                [self AutoScroll:songCount];
                // 自動ループのため // [self imagechangeto:@"play"];
                [mypod setsong:0];
                
                
               
                [self songtext:mypod.titleitem];
                mypod.avPlayer.volume=ipodVol;
                [mypod.avPlayer play];
                
                
                
                
            }
            else{           //次の曲へ
                songCount++;
                [self AutoScroll:songCount];
                [mypod setsong:songCount];
                mypod.avPlayer.volume=ipodVol;
                [mypod.avPlayer play];
                
                [self songtext:mypod.titleitem];
                
            }
            
        }

    }
}


- (void)didChangeAudioSessionRoute:(NSNotification *)notification
{
    // ヘッドホンが刺さっていたか取得
    BOOL (^isJointHeadphone)(NSArray *) = ^(NSArray *outputs){
        for (AVAudioSessionPortDescription *desc in outputs) {
            if ([desc.portType isEqual:AVAudioSessionPortHeadphones]) {
                return YES;
            }
        }
        return NO;
    };
    
    // 直前の状態を取得
    AVAudioSessionRouteDescription *prevDesc = notification.userInfo[AVAudioSessionRouteChangePreviousRouteKey];
    
    if (isJointHeadphone([[[AVAudioSession sharedInstance] currentRoute] outputs])) {
        if (!isJointHeadphone(prevDesc.outputs)) {
            NSLog(@"ヘッドフォンが刺さった");
        }
    } else {
        if(isJointHeadphone(prevDesc.outputs)) {
            NSLog(@"ヘッドフォンが抜かれた");
            [mypod.avPlayer pause];
             [self imagechangeto:@"play"];
        }
    }
}

- (void)receive:(NSNotification *)center
{
    NSString*str=[myHost.recvStr lastPathComponent];
    NSInteger i=str.integerValue;
    
    if (i==-1) {
        
    }else{
        
    
    [mypod setsong:i];
       
       
        dispatch_sync(dispatch_get_main_queue(), ^{
             [self songtext:mypod.titleitem];
            
        });
    
    }
    
    
    if ([[myHost.recvStr pathExtension] isEqualToString:@"play"]) {
        mypod.avPlayer.volume=ipodVol;
        [mypod.avPlayer play];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self AutoScroll:i];
              [self imagechangeto:@"pause"];
        });
       
       
                
    }else if ([[myHost.recvStr pathExtension] isEqualToString:@"pause"]){
        [mypod.avPlayer pause];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self AutoScroll:i];
             [self imagechangeto:@"play"];
            
        });
        
        
    
        
    }else{
       
        NSData *data=[[NSData alloc]init];
        data = myHost.recvData;
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        mypod.nameData=array;
        [mypod matchCheck];
        
        [mypod setsong:songCount];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self CreateNewNametable];
            [ttableView reloadData];
            [self songtext:mypod.titleitem];

            
        });
        
        
        
    }
        
    
    //データとんできたときの通知が来た時に
    
    
}

- (void)connect:(NSNotification *)center{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.inviteBtnTitle setTitle:[NSString stringWithFormat:@"%ld",(unsigned long)myHost.connectedpeer.count+1] forState:UIControlStateNormal];
        
    });

    
    
}


- (IBAction)pick:(id)sender {
    
    MPMediaPickerController *picker = [[MPMediaPickerController alloc]init];
    picker.delegate = self;
    picker.allowsPickingMultipleItems = NO;        // 複数選択可
    [self presentViewController:picker animated:YES completion:nil];    //Libraryを開く
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];     //キャンセルで曲選択を終わる
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection       //曲選択後
{
    
    MPMediaItem *item=[mediaItemCollection.items objectAtIndex:0];
    NSURL *url=[item valueForProperty:MPMediaItemPropertyAssetURL];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                           initWithAsset:urlAsset
                                           presetName:AVAssetExportPresetAppleM4A];
    
    exportSession.outputFileType = [[exportSession supportedFileTypes] objectAtIndex:0];
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [[docDir stringByAppendingPathComponent:[item valueForProperty:MPMediaItemPropertyTitle]] stringByAppendingPathExtension:@"aif"];
    NSLog(@"%@",filePath);
    exportSession.outputURL = [NSURL fileURLWithPath:filePath];
   
    [exportSession setTimeRange:CMTimeRangeMake(kCMTimeZero, [urlAsset duration])];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // ディレクトリを作成
    [fileManager createDirectoryAtPath:docDir
                         withIntermediateDirectories:YES
                                          attributes:nil
                                               error:nil];
   
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"export session completed");
            _queue= [[myaudioqueue alloc]initWithFilepath:[NSURL fileURLWithPath:filePath]];
            [_queue play];
        } else {
            NSLog(@"export session error");
           
        }
        
    }];
   
    
    
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
//    MPMediaItem *item=[mediaItemCollection.items objectAtIndex:0];
//    songCount=0;
//    [self imagechangeto:@"play"];
//    
//    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
//    mypod.nameData=[[NSArray alloc]init];
//    for (int i = 0;i < mediaItemCollection.count; i++) {
//        MPMediaItem *nameitem1=[mediaItemCollection.items objectAtIndex:i];
//        NSString *name1=[[NSString alloc]init];
//        name1=[nameitem1 valueForProperty:MPMediaItemPropertyTitle];
//        
//        mypod.nameData=[mypod.nameData arrayByAddingObject:name1];
//        
//    }
//
//    if (myHost.solo) {
//         [self saveCount];
//        _mediaItemCollection2=mediaItemCollection;
//        _mediaitemData = [NSKeyedArchiver archivedDataWithRootObject:_mediaItemCollection2];
//        NSUserDefaults *ud4=[NSUserDefaults standardUserDefaults];
//        [ud4 setObject:_mediaitemData forKey:@"_mediaitemData"];
//        [self songtext:item];
//        _url = [item valueForProperty:MPMediaItemPropertyAssetURL];
//        _playerItem = [[AVPlayerItem alloc] initWithURL:_url];    //変換
//        mypod.avPlayer = [[AVQueuePlayer alloc] initWithPlayerItem:_playerItem];
//        
//        mypod.avPlayer.volume=ipodVol;
//
//        NSUserDefaults *ud3=[NSUserDefaults standardUserDefaults];
//        [ud3 setObject:mypod.nameData forKey:@"nameData"];
//        
//        
//    }else{
//        [myHost stopClient];
//        [myHost stopHost];
//        titlelabel.text =[item valueForProperty:MPMediaItemPropertyTitle];
//        _url = [item valueForProperty:MPMediaItemPropertyAssetURL];
//        [myHost sendList:mypod.nameData];
//        [mypod matchCheck];
//
//        
//    }
//    [ttableView reloadData];
//    
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger dataCount;
    
    // テーブルに表示するデータ件数を返す
    dataCount = mypod.nameData.count;
    
    return dataCount;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"Cell";
    // 再利用できるセルがあれば再利用する
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        // 再利用できない場合は新規で作成
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = mypod.nameData[indexPath.row];
    
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
     songCount=(int)indexPath.row;
    [tableView reloadData];
    if (myHost.solo) {
        [self saveCount];
        [self nextandback];
        [mypod.avPlayer play];
        [self imagechangeto:@"pause"];
        [self AutoScroll:songCount];

        
    }else{
        [myHost sendStr:[NSString stringWithFormat:@"%d.play",songCount]];
        
        [self nextandback];
        
        
        [self AutoScroll:songCount];

        
    }
   
    
}


- (IBAction)backSong:(id)sender {
    if (myHost.solo) {
        if(_mediaItemCollection2 != 0){                     //１曲以上選ばれているか
            if (CMTimeGetSeconds(mypod.avPlayer.currentTime)<2.9) {
                
                if (songCount==0) {                             //最初なら最後の曲へ
                    songCount=(int)_mediaItemCollection2.count-1;
                    [self AutoScroll:songCount];
                    [self saveCount];
                }
                else {
                    songCount--;
                    [self AutoScroll:songCount];//前の曲へ
                    [self saveCount];
                }
                
                if ([mypod.avPlayer rate]==0) {  //曲が停止中なら停止
                    [self nextandback];
                    [self AutoScroll:songCount];
                }else{  //曲が再生中なら停止
                    [self nextandback];
                    [self AutoScroll:songCount];
                    [mypod.avPlayer play];
                    [self imagechangeto:@"pause"];
                }
            }
            else{[mypod.avPlayer seekToTime:CMTimeMake(0, 600)];}
        }
        

    }else{
    if(mypod.songs.count != 0){                     //１曲以上選ばれているか
        if (CMTimeGetSeconds(mypod.avPlayer.currentTime)<2.9) {
            
            if (songCount==0) {                             //最初なら最後の曲へ
                songCount=(int)mypod.songs.count-1;
                 [self AutoScroll:songCount];
                if ([mypod.avPlayer rate]==0) {  //曲が停止中なら停止
                    [myHost sendStr:[NSString stringWithFormat:@"%d.pause",songCount]];
                    [mypod setsong:songCount];
                   
                    
                    [self songtext:mypod.titleitem];

                    
                    
                }else{
                    [myHost sendStr:[NSString stringWithFormat:@"%d.play",songCount]];
                    [mypod setsong:songCount];
                    
                    mypod.avPlayer.volume=ipodVol;
                    [mypod.avPlayer play];
                    
                    
                   [self songtext:mypod.titleitem];
                    
                }
                
            }
            else {
                
                songCount--;    //前の曲へ
                 [self AutoScroll:songCount];
                if ([mypod.avPlayer rate]==0) {  //曲が停止中なら停止
                    [myHost sendStr:[NSString stringWithFormat:@"%d.pause",songCount]];
                    [mypod setsong:songCount];
                   [self songtext:mypod.titleitem];
                    
                    
                }else{  //曲が再生中なら停止
                    [myHost sendStr:[NSString stringWithFormat:@"%d.play",songCount]];
                    [mypod setsong:songCount];
                    mypod.avPlayer.volume=ipodVol;
                    [mypod.avPlayer play];
                   [self songtext:mypod.titleitem];
                }
            }
        }
        else{
             [self AutoScroll:songCount];
            
            if ([mypod.avPlayer rate]==0) {  //曲が停止中なら停止
                [myHost sendStr:[NSString stringWithFormat:@"%d.pause",songCount]];
                [mypod setsong:songCount];
                
                
                [self songtext:mypod.titleitem];
                
                
            }else{  //曲が再生中なら停止
                [myHost sendStr:[NSString stringWithFormat:@"%d.play",songCount]];
                [mypod setsong:songCount];
                mypod.avPlayer.volume=ipodVol;
                [mypod.avPlayer play];
                
                
                [self songtext:mypod.titleitem];            }
            
            
            
            
        }
    }
    }
    
}

- (IBAction)nextSong:(id)sender {
    if (myHost.solo) {
        if(_mediaItemCollection2.count != 0){               //１曲以上選ばれているか
            
            if (songCount==_mediaItemCollection2.count-1) {//最後なら1曲目へ
                songCount=0;
                [self AutoScroll:songCount];
                [self saveCount];
            }
            else{           //次の曲へ
                songCount++;
                [self AutoScroll:songCount];
                [self saveCount];
            }
            if ([mypod.avPlayer rate]==0) {  //曲が停止中なら停止
                [self nextandback];
                [self AutoScroll:songCount];
            }else{  //曲が再生中なら停止
                [self nextandback];
                [self AutoScroll:songCount];
                [mypod.avPlayer play];
                 [self imagechangeto:@"pause"];
            }
            
            
        }

    }else{
    
   
    if(mypod.songs.count != 0){               //１曲以上選ばれているか
        
        if ([mypod.avPlayer rate]==0) {  //曲が停止中なら停止
            if (songCount==mypod.songs.count-1) {//最後なら1曲目へ
                songCount=0;
                 [self AutoScroll:songCount];
                [myHost sendStr:@"0.pause"];
                [mypod setsong:0];
                
                
                [self songtext:mypod.titleitem];
                
            }
            else{           //次の曲へ
                songCount++;
                 [self AutoScroll:songCount];
                [mypod setsong:songCount];
                [myHost sendStr:[NSString stringWithFormat:@"%d.pause",songCount]];
                
                
               [self songtext:mypod.titleitem];
                 }
            
            
            
            
            
            
        }else{  //曲が再生中なら停止
            
            if (songCount==mypod.songs.count-1) {//最後なら1曲目へ
                songCount=0;
                 [self AutoScroll:songCount];
                [myHost sendStr:@"0.play"];
                [mypod setsong:0];
                
                
                
               [self songtext:mypod.titleitem];
            }
            else{           //次の曲へ
                songCount++;
                 [self AutoScroll:songCount];
                [mypod setsong:songCount];
                [myHost sendStr:[NSString stringWithFormat:@"%d.play",songCount]];
                
                
               [self songtext:mypod.titleitem];
                 }
            
            mypod.avPlayer.volume=ipodVol;
            [mypod.avPlayer play];
        }
        
        
       
        
    }
        
    }
}

-(void)nextandback{
    if (myHost.solo) {
        MPMediaItem *item = [_mediaItemCollection2.items objectAtIndex:songCount];
        [self songtext:item];
        _url = [item valueForProperty:MPMediaItemPropertyAssetURL];
        
        _playerItem = [[AVPlayerItem alloc] initWithURL:_url];
        mypod.avPlayer = [[AVQueuePlayer alloc] initWithPlayerItem:_playerItem];
        
        mypod.avPlayer.volume=ipodVol;

    }else{
  [mypod setsong:songCount];
    
    
    
   [self songtext:mypod.titleitem];    //曲タイトル表示
    
    mypod.avPlayer.volume=ipodVol;
    [mypod.avPlayer play];
      [self imagechangeto:@"pause"];
        
    }
    
}



- (IBAction)pushPlay:(id)sender {
    if (mypod.avPlayer!=nil){
        if (myHost.solo) {
            if ([mypod.avPlayer rate]==0) {  //曲が停止中なら再生
                [_playImage setImage : [ UIImage imageNamed : @"pauseClear.png" ] forState : UIControlStateNormal];
                [mypod.avPlayer play];
            }else{  //曲が再生中なら停止
                [_playImage setImage : [ UIImage imageNamed : @"playClear.png" ] forState : UIControlStateNormal];
                [mypod.avPlayer pause];
            }

        }else{
        [self AutoScroll:songCount];
        if ([mypod.avPlayer rate]==0) {  //曲が停止中なら再生
            [self imagechangeto:@"pause"];
            mypod.avPlayer.volume=ipodVol;
            [mypod.avPlayer play];
            [myHost sendStr:@"-1.play"];
        }else{  //曲が再生中なら停止
            [self imagechangeto:@"play"];
            [mypod.avPlayer pause];
            [myHost sendStr:@"-1.pause"];
           // NSLog(@"second:%f", CMTimeGetSeconds(mypod.avPlayer.currentTime));

        }
    }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (IBAction)ipodSliderChanged:(UISlider*)sender {   //曲のボリューム変更スライダー
    ipodVol = sender.value;
    mypod.avPlayer.volume=ipodVol;
    
    NSString *ipodVoltext = [NSString stringWithFormat:@"%.0f", ipodVol*2000];
    ipodVolLabel.text=ipodVoltext;
    NSUserDefaults *ud1=[NSUserDefaults standardUserDefaults];
    [ud1 setFloat:ipodVol forKey:@"ipodvol"];
}

- (IBAction)feedSliderChanged:(UISlider*)sender {   //フィードバック音のボリューム変更スライダー
    mypod.feedVol=sender.value;
    [mypod mixUnitvol];
    NSString *fbVoltext = [NSString stringWithFormat:@"%.0f", mypod.feedVol*100];
    fbVolLabel.text=fbVoltext;
    
    //スライダーんの値保持
    NSUserDefaults *ud2=[NSUserDefaults standardUserDefaults];
    
    [ud2 setFloat:mypod.feedVol forKey:@"feedvol"];
}

-(void)imagechangeto:(NSString *)icon{
    if ([icon isEqualToString:@"play"]) {
         [_playImage setImage : [ UIImage imageNamed : @"playClear.png" ] forState : UIControlStateNormal];
        
        
    }
    if ([icon isEqualToString:@"pause"]) {
         [_playImage setImage : [ UIImage imageNamed : @"pauseClear.png" ] forState : UIControlStateNormal];
        
    }
}



- (IBAction)inviteBtn:(id)sender {
    
    [myHost startHost];
    [self.inviteBtnTitle setTitle:[NSString stringWithFormat:@"%d",1] forState:UIControlStateNormal];

    //探索開始
}
-(void)CreateNewNametable{
    NSString *str=[[NSString alloc]init];
   mypod.nameData=[[NSArray alloc]init];
    for (int i=0; i<mypod.songs.count; i++) {
        
        str=[mypod.songs[i] valueForProperty:MPMediaItemPropertyTitle];
        mypod.nameData=[mypod.nameData arrayByAddingObject:str];
        
    }
    
    
    
}
-(void)AutoScroll:(NSInteger )num{
    if (num<mypod.nameData.count) {
        
    
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:num inSection:0];
    
    [ttableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    }
}

/////////////////////////////////////////////////////
-(void)saveCount{
    NSUserDefaults *ud5=[NSUserDefaults standardUserDefaults];
    [ud5 setFloat:songCount forKey:@"songCount"];
}

-(void)startTimer{
    _timer=[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(timertext) userInfo:nil repeats:YES];
    
}
-(void)timertext{
    second=fmodf(CMTimeGetSeconds(mypod.avPlayer.currentTime),60);
    minute=CMTimeGetSeconds(mypod.avPlayer.currentTime)/60;
    _timestr=[NSString stringWithFormat:@"%02d:%02d",minute,second];
    timelabel.text=_timestr;
    
    int maxback;
    maxback=playback-CMTimeGetSeconds(mypod.avPlayer.currentTime);
    maxsecond=maxback%60;
    maxminute=maxback/60;
    _maxtimelabelstr=[NSString stringWithFormat:@"-%02d:%02d",maxminute,maxsecond];
    maxtimelabel.text=_maxtimelabelstr;
    autoseek.value=CMTimeGetSeconds(mypod.avPlayer.currentTime);
}
-(void)songtext:(MPMediaItem *)textitem{

   
    titlelabel.text =[textitem valueForProperty:MPMediaItemPropertyTitle];
    albumlabel.text =[textitem valueForProperty:MPMediaItemPropertyAlbumTitle];
    
    NSString *playbackstr=[textitem valueForProperty:MPMediaItemPropertyPlaybackDuration];
    playback=playbackstr.intValue;
    autoseek.maximumValue=playback;
}
- (IBAction)seekslider:(UISlider *)sender {
    if (myHost.solo) {
        
    
    int senderval;
    senderval=sender.value;
    second=senderval%60;
    minute=sender.value/60;
    _timestr=[NSString stringWithFormat:@"%02d:%02d",minute,second];
    timelabel.text=_timestr;
    maxsecond=playback%60-second;
    maxminute=playback/60-minute;
    _maxtimelabelstr=[NSString stringWithFormat:@"-%02d:%02d",maxminute,maxsecond];
    maxtimelabel.text=_maxtimelabelstr;
    CMTime tm = CMTimeMakeWithSeconds(sender.value, NSEC_PER_SEC);
    
    [mypod.avPlayer seekToTime:tm];
    }
    
}
- (IBAction)feeddown:(id)sender {
    if (myHost.solo) {
        
    
    [_timer invalidate];
}
    
}

- (IBAction)feedup:(id)sender {
    if (myHost.solo) {
        
    
        if (![_timer isValid]) {
        [self startTimer];
        
    }
}
}
- (IBAction)btn:(id)sender {
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
           docDir=[docDir stringByAppendingString:@"aaa.aif"];
    

    [myHost fileCreate:docDir andData:myHost.recvData];
    NSURL * url=[[NSURL alloc]initWithString:docDir];
    AVAudioPlayer * player =[[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
    [player prepareToPlay];
    [player play];
}

- (void)sendbuff:(NSNotification *)center{
    [myHost.mSession sendData:_queue.data toPeers:myHost.connectedpeer withMode:MCSessionSendDataReliable error:nil];
}
@end
