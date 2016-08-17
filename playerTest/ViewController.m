//
//  ViewController.m
//  playerTest
//
//  Created by 汪宁 on 16/8/16.
//  Copyright © 2016年 ZHENAI. All rights reserved.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import "WNPlayerController.h"
@interface ViewController ()
@property(nonatomic, strong) WNPlayerController *vc;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"play" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor=[UIColor redColor];
    btn.frame=CGRectMake(20, 50, 50, 50);
    btn.center = CGPointMake(CGRectGetWidth(self.view.frame) / 2, 100);
    [self.view addSubview:btn];
   
    

}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    
    return UIInterfaceOrientationMaskPortrait;
    
}
-(void)play{
    
    _vc=[[WNPlayerController alloc]initWithUrl:[NSURL URLWithString:@"https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"]];
   
    [self presentViewController:_vc animated:YES completion:nil];
    
   
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
