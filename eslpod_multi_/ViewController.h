#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ESLpod.h"
#import "MultipeerHost.h"
#import "myaudioqueue.h"
@interface ViewController : UIViewController<MPMediaPickerControllerDelegate,UITableViewDelegate,UITableViewDataSource>
{
     IBOutlet UITableView *ttableView;

    __weak IBOutlet UILabel *titlelabel;

    __weak IBOutlet UILabel *ipodVolLabel;
    __weak IBOutlet UILabel *fbVolLabel;
    
    
    __weak IBOutlet UILabel *albumlabel;
    __weak IBOutlet UILabel *timelabel;
    __weak IBOutlet UILabel *maxtimelabel;
    
    __weak IBOutlet UISlider *autoseek;
    
    
   // __weak IBOutlet UIButton *playImage;
    ESLpod *mypod;
    MultipeerHost *myHost;
}
- (IBAction)inviteBtn:(id)sender;


@property (nonatomic) IBOutlet UIButton *playImage;

@property (weak, nonatomic) IBOutlet UIButton *inviteBtnTitle;


@property MPMusicPlayerController *player;

@property NSURL *url;
@property AVPlayerItem *playerItem;
@property MPMediaItemCollection *mediaItemCollection2;
@property NSNotificationCenter *notification;
@property NSData *mediaitemData;
@property NSTimer *timer;
@property NSString *maxtimelabelstr;
@property NSString *timestr;
@property (weak, nonatomic) IBOutlet UISlider *ipodvol;
@property (weak, nonatomic) IBOutlet UISlider *feedvol;

@property myaudioqueue *queue;
@property MPMusicPlayerController*playcontroller;

- (IBAction)ipodSliderChanged:(UISlider*)sender;
- (IBAction)feedSliderChanged:(UISlider*)sender;


@end