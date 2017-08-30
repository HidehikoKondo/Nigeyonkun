//
//  ViewController.h
//  RanningAlarm
//
//  Created by Hidehiko Kondo on 2017/08/30.
//  Copyright © 2017年 UDONKONET. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<AVAudioPlayerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property(nonatomic) AVAudioPlayer *audioPlayer;

@end

