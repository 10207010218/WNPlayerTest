//
//  WNPlayerController.h
//  playerTest
//
//  Created by 汪宁 on 16/8/16.
//  Copyright © 2016年 ZHENAI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface WNPlayerController : UIViewController<AVPlayerViewControllerDelegate>

- (id)initWithUrl:(NSURL *)url;

@end
