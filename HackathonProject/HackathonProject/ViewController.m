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


//窓いろいろ
@property (weak, nonatomic) IBOutlet UIView *timerSetView;
@property (weak, nonatomic) IBOutlet UIView *timerRunningView;
@property (weak, nonatomic) IBOutlet UIView *timerOnView;
@property (weak, nonatomic) IBOutlet UIView *timerOffView;

@property (weak, nonatomic) IBOutlet UIButton *timerSetButton;


@end


@implementation ViewController

//効果音
SystemSoundID sound_1;

//タイマー
NSTimer *approachCheckTimer;
NSTimer *nowTimer;

NSTimer *rssiTimer;


//NSTimer *alermTimer;

//現在時刻
int hh = 0;
int mm = 0;
int ss = 0;

//ピッカーで設定した時刻
NSString *pickerTime;

int m_rssi = 0;

//フラグ
bool updateflg = NO;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //端末のスリープを無効にする
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [_timerSetButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [_timerSetButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentFill];
    [_timerSetButton setContentVerticalAlignment:UIControlContentVerticalAlignmentFill];
    
    //効果音ファイル読み込み
    NSError *error = nil;
    // 再生する audio ファイルのパスを取得
    NSString *path = [[NSBundle mainBundle] pathForResource:@"alerm2" ofType:@"aif"];
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
    
    
    //ピッカーの時間の初期化
    [self changeTimePicker:nil];
    
    //おやすみ中のビューを表示
    [self.timerRunningView setFrame:CGRectMake(500, 0, _timerRunningView.bounds.size.width, _timerRunningView.bounds.size.height)];
    [self.timerOnView setFrame:CGRectMake(500, 0, _timerRunningView.bounds.size.width, _timerRunningView.bounds.size.height)];
    [self.timerOffView setFrame:CGRectMake(500, 0, _timerRunningView.bounds.size.width, _timerRunningView.bounds.size.height)];
    
    
    //おしゃべり
    [self speach:@"何時に起きますか？"];
    
    approachCheckTimer = [NSTimer scheduledTimerWithTimeInterval: 0.3f
                                                          target: self
                                                        selector: @selector(statusUpdate)
                                                        userInfo: nil
                                                         repeats: YES];
    
}

//Mabeee delegate
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    for (MaBeeeDevice *device in MaBeeeApp.instance.devices) {
        [device updateRssi];
    }
    
    
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





#pragma -mark 時刻関連処理
//ピッカー
- (IBAction)changeTimePicker:(id)sender {
    UIDatePicker *picker = (UIDatePicker *)sender;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    df.timeStyle = NSDateFormatterMediumStyle;
    df.dateFormat = @"HH:mm:00";
    
    // 選択日時の表示
    NSLog(@"%@",[df stringFromDate:picker.date]);
    
    pickerTime = [df stringFromDate:picker.date];
}




#pragma mark - MaBeee接続用
- (IBAction)maBeeeScanButtonPressed:(UIButton *)sender {
    MaBeeeScanViewController *vc = MaBeeeScanViewController.new;
    [vc show:self];
}


#pragma mark - ボタン

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


#pragma -mark アラーム
- (IBAction)updateButtonPressed:(UIButton *)sender {
    [self playSE];
    
    AVSpeechSynthesizer* speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    //NSString* speakingText = message;
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@"トラックにスマホをセットしてください"];
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

//ステータス取得
- (void)statusUpdate{
    NSLog(@"UPDATE!!");
    for (MaBeeeDevice *device in MaBeeeApp.instance.devices) {
        [device updateRssi];
        //[device updateBatteryVoltage];
    }
}



#pragma -mark Mabeee状態受信
- (void)receiveNotification:(NSNotification *)notification {
    if ([MaBeeeDeviceRssiDidUpdateNotification isEqualToString:notification.name]) {
        //再生中（アラーム発動中）でない場合は何もしない
        if(![self.audioPlayer isPlaying]){
            return;
        }
        
        //device取得
        NSUInteger identifier = [notification.userInfo[@"MaBeeeDeviceIdentifier"] unsignedIntegerValue];
        MaBeeeDevice *device = [MaBeeeApp.instance deviceWithIdentifier:identifier];
        
        //rssi表示
        NSString *line = [NSString stringWithFormat:@"%d", device.rssi];
        [self appendLine:line];
        
        //スマホとの距離
        int rssi = device.rssi;
        
        if(rssi > -50){
            //TODO:　ぴったりくっつけるとストップ（荷台に置くと）
            //ここでアラーム停止
            for (MaBeeeDevice *device in MaBeeeApp.instance.devices) {
                device.pwmDuty = 0;
                NSLog(@"荷台にのせたからアラーム停止");
                [self speach:@"おはようございます！"];
                [self.audioPlayer stop];
                [self.timerOffView setFrame:CGRectMake(0, 0, _timerRunningView.bounds.size.width, _timerRunningView.bounds.size.height)];
                return;
            }
        }else if(rssi > -70 && rssi < -51){
            //いい具合に近づいたら走行
            for (MaBeeeDevice *device in MaBeeeApp.instance.devices) {
                device.pwmDuty = 50;
                NSLog(@"走行中:%d",(int)device.pwmDuty);
            }
        }else{
            NSLog(@"遠いから停止");
            for (MaBeeeDevice *device in MaBeeeApp.instance.devices) {
                device.pwmDuty = 0;
                NSLog(@"アラーム停止");
            }
        }
        return;
    }
}


//接近度表示
- (void)appendLine:(NSString *)line {
    self.distanseLabel.text = [NSString stringWithFormat:@"距離：%@\n", line];
}


# pragma mark - アラート
//アラーム再生
- (void)playSE{
    [self.audioPlayer play];
}



#pragma -mark アラームセット
- (IBAction)alermTimeSetting:(id)sender{
    NSLog(@"alermtimersetting");
    
    //おやすみ
    [self speach:@"おやすみなさい"];
    
    //おやすみ中のビューを表示
    [self.timerRunningView setFrame:CGRectMake(0,
                                               0,
                                               _timerRunningView.bounds.size.width,
                                               _timerRunningView.bounds.size.height)];
    
    
    //ピッカー無効
    [_timePicker setEnabled:NO];
    
    
    //移動予定
    //現在時刻表示更新
    [nowTimer invalidate];
    nowTimer = nil;
    nowTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0f
                                                target: self
                                              selector: @selector(nowTimeUpdate)
                                              userInfo: nil
                                               repeats: YES];
}

- (void)alermTimeCheck{
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
}


//現在時刻の更新
- (void)nowTimeUpdate{
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm:ss";
    NSString *date24 = [dateFormatter stringFromDate:date];
    
    hh = [(NSString *)[date24 componentsSeparatedByString:@":"][0] intValue];
    mm = [(NSString *)[date24 componentsSeparatedByString:@":"][1] intValue];
    ss = [(NSString *)[date24 componentsSeparatedByString:@":"][2] intValue];
    
    NSString *timeStr = [NSString stringWithFormat:@"%d:%d:%d",hh,mm,ss];
    [_nowLabel setText: timeStr];
    NSLog(@"nowtime   :%@",timeStr);
    
    self.checkTime;
}


- (void)checkTime{
    //ピッカーの時刻と一致するかチェック
    NSLog(@"pickertime:%@",pickerTime);
    int phh = [(NSString *)[pickerTime componentsSeparatedByString:@":"][0] intValue];
    int pmm = [(NSString *)[pickerTime componentsSeparatedByString:@":"][1] intValue];
    int pss = [(NSString *)[pickerTime componentsSeparatedByString:@":"][2] intValue];
    
    if(hh == phh && mm == pmm && ss == pss){
        NSLog(@"ビンゴ！");
        //TODO: ここでアラーム発動
        self.alermStart;
        
    }else{
        NSLog(@"まだだよ！");
    }
}


//リセット
-(IBAction)resetTimer:(id)sender{
    NSLog(@"reset");
    //現在時刻タイマーリセット
    [nowTimer invalidate];
    nowTimer = nil;
    
    //何時に起きますか？を表示
    [self.timerRunningView setFrame:CGRectMake(500, 0, _timerRunningView.bounds.size.width, _timerRunningView.bounds.size.height)];
    [self.timerOnView setFrame:CGRectMake(500, 0, _timerRunningView.bounds.size.width, _timerRunningView.bounds.size.height)];
    [self.timerOffView setFrame:CGRectMake(500, 0, _timerRunningView.bounds.size.width, _timerRunningView.bounds.size.height)];
    
    
    //ピッカーを有効
    [_timePicker setEnabled:YES];
    
    [self speach:@"何時に起きますか？"];

}


//アラーム発動
-(void)alermStart{
    //アラーム表示
    [self.timerOnView setFrame:CGRectMake(0, 0, _timerRunningView.bounds.size.width, _timerRunningView.bounds.size.height)];
    
    //アラーム再生
    [self playSE];
    [self speach:@"スマホをダンプカーに乗せてください"];
}


//Siriさんスピーチ
-(void)speach:(NSString*)message{
    AVSpeechSynthesizer* speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:message];
    [speechSynthesizer speakUtterance:utterance];
}


@end
