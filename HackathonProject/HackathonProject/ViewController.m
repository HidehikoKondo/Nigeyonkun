//
//  ViewController.m
//  HackathonProject
//
//  Created by UDONKONET on 2017/05/14.
//  Copyright © 2017年 UDONKONET. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#include <AVFoundation/AVFoundation.h>

@import MaBeeeSDK;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UISlider *powerSlider;
@property (weak, nonatomic) IBOutlet UILabel *distanseLabel;

@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;
@property (weak, nonatomic) IBOutlet UIButton *alermStopButton;
@property (weak, nonatomic) IBOutlet UILabel *nowLabel;

@end


@implementation ViewController

//効果音
SystemSoundID sound_1;

//タイマー
NSTimer *approachCheckTimer;
NSTimer *nowTimer;
NSTimer *alermTimer;

//ピッカーで設定した時刻
NSString *pickerTime;

int m_rssi = 0;

//フラグ
bool updateflg = NO;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    

    //現在時刻更新
    if([nowTimer isValid]){
        [nowTimer invalidate];
        nowTimer = nil;
        NSLog(@"nowTimer invalidated");

    }else{
        nowTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f
                                                      target: self
                                                    selector: @selector(nowTimeUpdate)
                                                    userInfo: nil
                                                     repeats: YES];

    }


    
    
    //端末のスリープを無効にする
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    

    //効果音ファイル読み込み
    NSError *error = nil;
    // 再生する audio ファイルのパスを取得
    NSString *path = [[NSBundle mainBundle] pathForResource:@"alerm" ofType:@"aif"];
    // パスから、再生するURLを作成する
    NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
    // auido を再生するプレイヤーを作成する
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    // エラーが起きたとき
    if ( error != nil )
    {
        NSLog(@"Error %@", [error localizedDescription]);
    }
    // 自分自身をデリゲートに設定
    [self.audioPlayer setDelegate:self];
    self.audioPlayer.numberOfLoops = -1;
}

//Mabeee delegate
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [MaBeeeApp.instance addObserver:self selector:@selector(receiveNotification:)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MaBeeeApp.instance removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//現在時刻の更新
//ステータス取f得
- (void)nowTimeUpdate{
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm:ss";
    NSString *date24 = [dateFormatter stringFromDate:date];

    int hh = [(NSString *)[date24 componentsSeparatedByString:@":"][0] intValue];
    int mm = [(NSString *)[date24 componentsSeparatedByString:@":"][1] intValue];
    int ss = [(NSString *)[date24 componentsSeparatedByString:@":"][2] intValue];

    NSString *timeStr = [NSString stringWithFormat:@"%d:%d:%d",hh,mm,ss];
    [_nowLabel setText: timeStr];
}




#pragma mark - MaBeee用
- (IBAction)maBeeeScanButtonPressed:(UIButton *)sender {
    MaBeeeScanViewController *vc = MaBeeeScanViewController.new;
    [vc show:self];
}



//アラーム停止
-(IBAction)button:(id)sender{
    [self.audioPlayer stop];
    
    //タイマー停止
    [approachCheckTimer invalidate];
    approachCheckTimer = nil;
    
    //モーター停止
    for (MaBeeeDevice *device in MaBeeeApp.instance.devices) {
        device.pwmDuty = 0;
    }
}

- (IBAction)sliderValueChanged:(UISlider *)slider {
    for (MaBeeeDevice *device in MaBeeeApp.instance.devices) {
        device.pwmDuty = (int)(slider.value * 100);
        NSLog(@"%d",(int)(slider.value * 100));
    }
}


//ステータス取f得
- (void)statusUpdate{
    NSLog(@"UPDATE!!");
    for (MaBeeeDevice *device in MaBeeeApp.instance.devices) {
        [device updateRssi];
        //[device updateBatteryVoltage];
    }
    

}

- (IBAction)updateButtonPressed:(UIButton *)sender {
    [self playSE];

    AVSpeechSynthesizer* speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    //NSString* speakingText = message;
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@"車を追いかけてください"];
    [speechSynthesizer speakUtterance:utterance];
    
    
    
    
    if (updateflg == true){
        NSLog(@"タイマー停止");
        updateflg = false;
        [approachCheckTimer invalidate];
        approachCheckTimer = nil;
    }else{
        NSLog(@"タイマー開始");
        updateflg = true;

        approachCheckTimer = [NSTimer scheduledTimerWithTimeInterval: 0.3f
                                                          target: self
                                                        selector: @selector(statusUpdate)
                                                        userInfo: nil
                                                         repeats: YES];
        
    }
}


- (void)receiveNotification:(NSNotification *)notification {
    if ([MaBeeeDeviceRssiDidUpdateNotification isEqualToString:notification.name]) {
        NSUInteger identifier = [notification.userInfo[@"MaBeeeDeviceIdentifier"] unsignedIntegerValue];
        MaBeeeDevice *device = [MaBeeeApp.instance deviceWithIdentifier:identifier];
        NSString *line = [NSString stringWithFormat:@"%d", device.rssi];
        [self appendLine:line];
        
        int rssi = device.rssi;

        if(rssi < -70){
            //スピート0
            for (MaBeeeDevice *device in MaBeeeApp.instance.devices) {
                device.pwmDuty = 0;
                NSLog(@"%d",(int)device.pwmDuty);
                [_alermStopButton setEnabled:NO];
                
                AVSpeechSynthesizer* speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
                //NSString* speakingText = message;
                AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@"アラームは止められません"];
                [speechSynthesizer speakUtterance:utterance];
            }
        }else{
            //スピードマックス
            for (MaBeeeDevice *device in MaBeeeApp.instance.devices) {
                device.pwmDuty = 50;
                NSLog(@"%d",(int)device.pwmDuty);
                [_alermStopButton setEnabled:YES];
                
                AVSpeechSynthesizer* speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
                //NSString* speakingText = message;
                AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@"アラームは止められます"];
                [speechSynthesizer speakUtterance:utterance];

            }
        }
        return;
    }
    
//    if ([MaBeeeDeviceBatteryVoltageDidUpdateNotification isEqualToString:notification.name]) {
//        NSUInteger identifier = [notification.userInfo[@"MaBeeeDeviceIdentifier"] unsignedIntegerValue];
//        MaBeeeDevice *device = [MaBeeeApp.instance deviceWithIdentifier:identifier];
//        NSString *line = [NSString stringWithFormat:@"%@ Volgate: %f", device.name, device.batteryVoltage];
//        [self appendLine:line];
//        return;
//    }
}

- (void)appendLine:(NSString *)line {
    self.distanseLabel.text = [NSString stringWithFormat:@"🚗接近値：%@\n", line];
}


- (void)playSE{
    [self.audioPlayer play];
}




# pragma mark - アラート
//アラートを表示するだけ
- (void)showAlert:(NSString*)title message:(NSString*)message{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                      }]];
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self presentViewController:alertController animated:YES completion:nil];
    });
}


//ピッカー
- (IBAction)changeTimePicker:(id)sender {
    UIDatePicker *picker = (UIDatePicker *)sender;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    df.timeStyle = NSDateFormatterMediumStyle;
    df.dateFormat = @"HH:mm:59";
    
    // 選択日時の表示
    NSLog(@"%@",[df stringFromDate:picker.date]);
    
    pickerTime = [df stringFromDate:picker.date];
    
    
}

- (IBAction)alermTimeSetting:(id)sender{
    NSLog(@"alermtimersetting");
    

    if([alermTimer isValid]){
        [alermTimer invalidate];
        alermTimer = nil;
        NSLog(@"alermTimer invalidated");
        
    }else{
        alermTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f
                                                      target: self
                                                    selector: @selector(alermUpdate)
                                                    userInfo: nil
                                                     repeats: YES];

    }

}

- (void)alermUpdate{
    NSLog(@"alermTimer update");
    
    /* 24時間表記 */
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm:ss";
    NSString *date24 = [dateFormatter stringFromDate:date];
    
    int hh = [(NSString *)[date24 componentsSeparatedByString:@":"][0] intValue];
    int mm = [(NSString *)[date24 componentsSeparatedByString:@":"][1] intValue];
    int ss = [(NSString *)[date24 componentsSeparatedByString:@":"][2] intValue];
    
    //ピッカーの時刻
    int phh = [(NSString *)[pickerTime componentsSeparatedByString:@":"][0] intValue];
    int pmm = [(NSString *)[pickerTime componentsSeparatedByString:@":"][1] intValue];
    int pss = [(NSString *)[pickerTime componentsSeparatedByString:@":"][2] intValue];

    
    NSLog(@"%d:%d:%d",hh, mm, ss);
    NSLog(@"%d:%d:%d",phh, pmm, pss);
    
    NSLog(@"%d時間%d分%d秒後にアラームが鳴ります",phh-hh , pmm-mm, pss-ss );
    
}




@end
