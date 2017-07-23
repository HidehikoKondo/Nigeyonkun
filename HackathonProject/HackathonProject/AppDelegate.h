//
//  AppDelegate.h
//  HackathonProject
//
//  Created by UDONKONET on 2017/05/14.
//  Copyright © 2017年 UDONKONET. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MEMELib/MEMELib.h>
#import <WatchKit/WatchKit.h>
#import <WatchConnectivity/WatchConnectivity.h>

//MEMEの設定
#define APPCLIENDID @"392782397631375"
#define CLIENTSECRET @"7y1t8ksnzousqkndunecbj4skb2mwzg9"

//アラートタイトル
#define TITLE_MEME @"JINS MEME"
#define TITLE_ERROR @"エラー"
#define TITLE_AUTH_FAIL @"認証エラー"
#define TITLE_ERROR_CONNECTION @"JINS MEME 接続エラー"
#define TITLE_DEVICE_INVALID @"デバイスエラー"
#define TITLE_SDK_ERROR @"SDKエラー"
#define TITLE_FW_ERROR @"ファームウェアエラー"
#define TITLE_BT_ERROR @"Bluetoothエラー"


//アラートメッセージ
#define MES_NOT_ES @"JINS MEME MTには対応していません\nJINS MEME ESをご利用ください"
#define MES_DATA_FAIL @"JINS MEMEからデータ取得ができませんでした"
#define MES_ERROR @"予期せぬエラーが発生しました"
#define MES_SDK_INVALID @"SDKが無効です"
#define MES_APP_INVALID @"Application ID または Client Secretが無効です"
#define MES_ERROR_CONNECTION @"接続エラーです"
#define MES_DEVICE_INVALID @"無効なデバイスです"
#define MES_SDK_ERROR @"無効なコマンドです"
#define MES_FW_ERROR @"ファームウェアのバージョンを確認してください"
#define MES_BT_ERROR @"BluetoothをONにしてください"


//ラベルメッセージ
#define MES_MEME_DISCONNECT @"JINS MEMEを切断しました\n接続してください"
#define MES_MEME_CONNECT_OK @"接続OK!"



@interface AppDelegate : UIResponder <UIApplicationDelegate, WCSessionDelegate>

@property (strong, nonatomic) UIWindow *window;


//MEMEから取得した値たちをDelegateで持っておく。
@property (strong ,nonatomic) MEMERealTimeData *memeValue;
@property (nonatomic ,strong) NSMutableDictionary *blinkStatus;

@end

