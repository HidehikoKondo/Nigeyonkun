//
//  InterfaceController.m
//  HackathonProject WatchKit Extension
//
//  Created by UDONKONET on 2017/05/14.
//  Copyright © 2017年 UDONKONET. All rights reserved.
//

#import "InterfaceController.h"


@interface InterfaceController()
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *textLabel;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)textInput {
    NSArray* suggestions = @[@"こんにちは",@"ハロー",@"グーテンモルゲン"];
    
    [self presentTextInputControllerWithSuggestions:suggestions
                                   allowedInputMode:WKTextInputModeAllowEmoji
                                         completion:^(NSArray *results){
                                             if (results && results.count > 0) {
                                                 //入力した文字の取り出し
                                                 id text = [results objectAtIndex:0];
                                                 //入力した文字列をラベルに表示
                                                 [_textLabel setText:(NSString*)text];
                                                 
                                                 //iPhoneに送信
                                                 [self submit:text];
                                             }
                                         }
     ];
}



-(void)submit:(NSString *)message{
    NSDictionary *applicationDict = @{@"message" : message};
    [[WCSession defaultSession] updateApplicationContext:applicationDict error:nil];
    
    
    if ([[WCSession defaultSession] isReachable]) {
        [[WCSession defaultSession] sendMessage:applicationDict
                                   replyHandler:^(NSDictionary *replyHandler) {
                                       // do something
                                       NSLog(@"送った/ %@",message);
                                   }
                                   errorHandler:^(NSError *error) {
                                       // do something
                                       NSLog(@"送れなかった・・・orz");
                                   }
         ];
    }else{
        NSLog(@"つながってないよ");
        [_textLabel setText:@"つながってないよ"];
    }
}





@end



