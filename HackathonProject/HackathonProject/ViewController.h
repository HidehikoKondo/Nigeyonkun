//
//  ViewController.h
//  HackathonProject
//
//  Created by UDONKONET on 2017/05/14.
//  Copyright © 2017年 UDONKONET. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

//MEME
#import <MEMELib/MEMELib.h>



@interface ViewController : UIViewController<MEMELibDelegate, UIApplicationDelegate, AVAudioPlayerDelegate, UITableViewDataSource, UITableViewDelegate, WCSessionDelegate, AVAudioPlayerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property(nonatomic) AVAudioPlayer *audioPlayer;


@end

