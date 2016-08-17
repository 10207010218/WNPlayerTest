//
//  WNPlayerController.m
//  playerTest
//
//  Created by 汪宁 on 16/8/16.
//  Copyright © 2016年 ZHENAI. All rights reserved.
//

#import "WNPlayerController.h"
#define VIEWWIDTH    [UIScreen mainScreen].bounds.size.width
#define VIEWHEIGHT    [UIScreen mainScreen].bounds.size.height

typedef NS_ENUM(NSInteger, PanMoveDirection){
    PanMoveDirectionHorizontal,
    PanMoveDirectionVertical
};
@interface WNPlayerController()


@property (nonatomic,strong)AVPlayer         *player;
@property (nonatomic,strong)AVPlayerItem     *playerItem;
@property (nonatomic,strong)AVAudioSession   *session;
@property (nonatomic,strong)NSURL            *url;

@property (nonatomic,strong)UIView           *bottomView;
@property (nonatomic,strong)UIButton         *pauseButton;
@property (nonatomic,strong)UIButton         *backButton;
@property (nonatomic,assign)BOOL             isPlay;
@property (nonatomic,assign)BOOL             Lock;

@property (nonatomic,strong)UISlider *movieProgressSlider;//进度条
@property (nonatomic,assign)CGFloat ProgressBeginToMove;
@property (nonatomic,assign)CGFloat totalMovieDuration;//视频总时间
@property (nonatomic,strong)UILabel *beginTimeLabel;//起始时间
@property (nonatomic,strong)UILabel *endTimeLabel;//结束时间
@property (nonatomic,assign)float startProgress;//起始进度条
@property (nonatomic,assign)float NowProgress;//进度条当前位置


@property (nonatomic,assign)float systemVolume;//系统音量值
@property (nonatomic, strong) UISlider *mpVolumeSlider;
@property (nonatomic, strong) UIImageView *volumeLogoImage;
@property (nonatomic, assign) PanMoveDirection panDirection;
@property (nonatomic, strong)UIButton *lockButton;
//监控视频播放进度
@property (nonatomic,strong)NSTimer *avTimer;
//工具监控
@property (nonatomic,strong)NSTimer *toolTimer;

@end

@implementation WNPlayerController

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}
- (id)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}
-(void)viewDidLoad
{
  [super viewDidLoad];
    
  self.view.backgroundColor=[UIColor yellowColor];
 [self createAvPlayer];// 创建播放器
    
 [self createToolView];// 工具
 
    
    
    
}
- (void)createAvPlayer{
    //设置静音状态也可播放声音
//    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    CGRect playerFrame = CGRectMake(0, 0, self.view.layer.bounds.size.height, self.view.layer.bounds.size.width);
    
    AVURLAsset *asset = [AVURLAsset assetWithURL: _url];
    Float64 duration = CMTimeGetSeconds(asset.duration);
    //获取视频总时长
    _totalMovieDuration = duration;
    
    _playerItem = [AVPlayerItem playerItemWithAsset: asset];
    
    _player = [[AVPlayer alloc]initWithPlayerItem:_playerItem];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = playerFrame;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    [_player play];
     self.avTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    _isPlay=YES;
    
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap)];
    [self.view addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
    [self.view addGestureRecognizer:panGesture];

    
}

-(void)createToolView
{
    _backButton=[[UIButton alloc]initWithFrame:CGRectMake(10, 10, 44, 44)];
    [_backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [_backButton setTitle:@"返回" forState:UIControlStateNormal];
    _backButton.backgroundColor=[UIColor grayColor];
    [self.view addSubview:_backButton];
    
    _bottomView=[[UIView alloc]initWithFrame:CGRectMake(0, VIEWWIDTH-50, VIEWHEIGHT, 50)];
    _bottomView.backgroundColor=[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    [self.view addSubview:_bottomView];
    
    _pauseButton=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 50)];
    [_pauseButton addTarget:self action:@selector(pauseVideo) forControlEvents:UIControlEventTouchUpInside];
    [_pauseButton setTitle:@"暂停键" forState:UIControlStateNormal];
    _pauseButton.backgroundColor=[UIColor grayColor];
    [_bottomView addSubview:_pauseButton];
    
    
    
    _movieProgressSlider = [[UISlider alloc]initWithFrame:CGRectMake(110, 10, _bottomView.frame.size.width-170, 30)];
    [_movieProgressSlider setMinimumTrackTintColor:[UIColor whiteColor]];
    [_movieProgressSlider setMaximumTrackTintColor:[UIColor colorWithRed:0.49f green:0.48f blue:0.49f alpha:1.00f]];
    [_movieProgressSlider setThumbImage:[UIImage imageNamed:@"progressThumb.png"] forState:UIControlStateNormal];
    [_movieProgressSlider addTarget:self action:@selector(scrubbingDidBegin) forControlEvents:UIControlEventTouchDown];
    [_movieProgressSlider addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
    [_bottomView addSubview:_movieProgressSlider];
    
    
    _beginTimeLabel=[[UILabel alloc]initWithFrame:CGRectMake(60, 10, 50, 30)];
    _beginTimeLabel.text=@"00:00:00";
    _beginTimeLabel.font=[UIFont systemFontOfSize:8];
    [_bottomView addSubview:_beginTimeLabel];
    
    _endTimeLabel=[[UILabel alloc]initWithFrame:CGRectMake(VIEWHEIGHT-60, 10, 50, 30)];
    _endTimeLabel.text=[self transSecondsToString:_totalMovieDuration];
    _endTimeLabel.font=[UIFont systemFontOfSize:8];
    [_bottomView addSubview:_endTimeLabel];
    
    
    
    UIView *parentVolumeView = [[UIView alloc] initWithFrame:CGRectMake(250, 50, 110, 15)];
    parentVolumeView.backgroundColor = [UIColor clearColor];
    parentVolumeView.center = CGPointMake(VIEWHEIGHT-50, 82);
    parentVolumeView.transform = CGAffineTransformMakeRotation(-90*M_PI/180.0);
    [parentVolumeView.layer setCornerRadius:10];
    [self.view addSubview:parentVolumeView];
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:parentVolumeView.bounds];
    //[volumeView setTintColor:UIColorFromRGB(0xFF3C3C)];
    [volumeView setVolumeThumbImage:[UIImage imageNamed:@"进度圆圈.png"] forState:UIControlStateNormal];
    [parentVolumeView addSubview:volumeView];
    //volumeView.showsVolumeSlider=NO;  //这个就是直接用系统的音量控制view
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            self.mpVolumeSlider = (UISlider*)view;
            [self.mpVolumeSlider addTarget:self action:@selector(setVolumeLogoImage) forControlEvents:UIControlEventValueChanged];
            break;
        }
    }
    
    self.volumeLogoImage = [[UIImageView alloc] initWithFrame:CGRectMake(12, 170-20-17, 20, 20)];
    self.volumeLogoImage.center=CGPointMake(VIEWHEIGHT-50, 150);
    [self.view addSubview:self.volumeLogoImage];
    [self setVolumeLogoImage];
    
    
   self.toolTimer= [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(hiddenTools) userInfo:nil repeats:NO];
    
    
    
    _lockButton=[[UIButton alloc]initWithFrame:CGRectMake(8, 180, 44, 50)];
    [_lockButton setImage:[UIImage imageNamed:@"开启锁屏.png"] forState:UIControlStateNormal];
    [_lockButton setImage:[UIImage imageNamed:@"关闭锁屏.png"] forState:UIControlStateSelected];
    
    [_lockButton addTarget:self action:@selector(lockScreen:) forControlEvents:UIControlEventTouchUpInside];
    _Lock=NO;
    
    [self.view addSubview:_lockButton];
  
    
}
-(void)lockScreen:(UIButton *)button{
    button.selected=!button.selected;
    if (button.selected) {
        _Lock=YES;
    }else{
        _Lock=NO;
    }
}

-(void)hiddenTools
{
    [self showOrHideTools:NO];
    [self.toolTimer invalidate];
}
- (void)setVolumeLogoImage {
    float systemVolume = self.mpVolumeSlider.value; //这句重复代码不能删
    systemVolume = self.mpVolumeSlider.value;
    if (systemVolume > 0) {
        [self.volumeLogoImage setImage:[UIImage imageNamed:@"音量.png"]];
    } else {
        [self.volumeLogoImage setImage:[UIImage imageNamed:@"无音量 .png"]];
    }
}

-(void)updateUI{
    
    //1.根据播放进度与总进度计算出当前百分比。
    float new = CMTimeGetSeconds(_player.currentItem.currentTime) / CMTimeGetSeconds(_player.currentItem.duration);
    if (new>=1) {
        [_avTimer invalidate];
        
        //  这里处理视频播放完成之后要做的事情  比如暂停 播放下一个视频等等
    }
    

    //2.计算当前百分比与实际百分比的差值，
    float DValue = new - _NowProgress;
    //3.实际百分比更新到当前百分比
    _NowProgress = new;
    //4.当前百分比加上差值更新到实际进度条
    self.movieProgressSlider.value = self.movieProgressSlider.value + DValue;
    NSString *timeStr=[self transSecondsToString:CMTimeGetSeconds(_player.currentItem.currentTime) ];
    _beginTimeLabel.text=timeStr;
    
    
    
}

-(void)playOrPause:(BOOL)play
{
    if (play) {
        
        float dragedSeconds = floorf(_totalMovieDuration * _NowProgress);
        CMTime newCMTime = CMTimeMake(dragedSeconds,1);
        //2.更新电影到实际秒数。
        [_player seekToTime:newCMTime];
        [self.player play];
        self.avTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
        
        
    }else
    {
        
        [self.player pause];
        [self.avTimer invalidate];
        
    }
    
}

-(void)goBack{
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
#pragma mark 拖动视频播放进度条
//按住滑块
-(void)scrubbingDidBegin{
    _ProgressBeginToMove = _movieProgressSlider.value;
}

//释放滑块
-(void)scrubbingDidEnd{
    [self UpdatePlayer];
}

//拖动停止后更新avplayer
-(void)UpdatePlayer{
    //1.暂停播放
    [self playOrPause:NO];
    //2.存储实际百分比值
    _NowProgress = _movieProgressSlider.value;
    //3.重新开始播放
    [self playOrPause:YES];
}

-(void)pauseVideo{
    if (_isPlay) {
        [self.player pause];
        _pauseButton.backgroundColor=[UIColor redColor];
        _isPlay=NO;
    }else
    {
        
        [self.player play];
        _pauseButton.backgroundColor=[UIColor yellowColor];
        _isPlay=YES;
    }
}


-(void)showOrHideTools:(BOOL)show
{
    if (show) {
        _backButton.hidden=NO;
        _bottomView.hidden=NO;
        _lockButton.hidden=NO;
        self.mpVolumeSlider.hidden=NO;
        self.volumeLogoImage.hidden=NO;
        [UIView animateWithDuration:0.3 animations:^{
            _backButton.alpha=1;
            _bottomView.alpha=1;;
        }];
        self.toolTimer= [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(hiddenTools) userInfo:nil repeats:NO];

    }else
    {
        [UIView animateWithDuration:0.3 animations:^{
            _backButton.alpha=0;
            _bottomView.alpha=0;
            self.mpVolumeSlider.hidden=YES;
            self.volumeLogoImage.hidden=YES;
            _lockButton.hidden=YES;
        }completion:^(BOOL finished) {
            _backButton.hidden=YES;
            _bottomView.hidden=YES;
           
        }];
      
    }
}


#pragma mark - 平移手势方法
- (void)panDirection:(UIPanGestureRecognizer *)pan
{
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self.view];
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动e
            // 使用绝对值来判断移动的方向
          

            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x < y){ // 垂直移动
                self.panDirection = PanMoveDirectionVertical;
                
                self.mpVolumeSlider.hidden=NO;
                self.volumeLogoImage.hidden=NO;
                self.toolTimer= [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(hiddenTools) userInfo:nil repeats:NO];
                
            } else {
                self.panDirection = PanMoveDirectionHorizontal;
                
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (self.panDirection) {
                case PanMoveDirectionHorizontal:{
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanMoveDirectionVertical:{
                    
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            
            switch (self.panDirection) {
                case PanMoveDirectionHorizontal:{
                    [self UpdatePlayer];
                }
                    break;
                case PanMoveDirectionVertical:{
                    
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - pan垂直移动的方法
- (void)verticalMoved:(CGFloat)value
{
    self.mpVolumeSlider.value -= value/10000;
    
}
#pragma mark - pan水平移动的方法

-(void)horizontalMoved:(CGFloat)value
{
    
   _movieProgressSlider.value+=value/10000;
   _NowProgress= _movieProgressSlider.value;
    
    float dragedSeconds = floorf(_totalMovieDuration * _NowProgress);
    CMTime newCMTime = CMTimeMake(dragedSeconds,1);
    //2.更新电影到实际秒数。
    [_player seekToTime:newCMTime];
    
}


#pragma mark timeTransfer
-(NSString *)transSecondsToString:(Float64)seconds
{
    NSInteger hours=seconds/3600;
    NSInteger minues=(NSInteger)seconds%3600/60;
    NSInteger secondss=(NSInteger)seconds%60;
    
    NSString *hourStr;
    NSString *minuesStr;
    NSString *secondsStr;
    
    if (hours<10) {
        hourStr=[NSString stringWithFormat:@"0%ld",hours];
        
    }else if(hours<99)
    {
        hourStr=[NSString stringWithFormat:@"%ld",hours];
    }
    
    if (minues<10) {
        minuesStr=[NSString stringWithFormat:@"0%ld",minues];
        
    }else
    {
        minuesStr=[NSString stringWithFormat:@"%ld",minues];
    }
    
    if (seconds<10) {
        secondsStr=[NSString stringWithFormat:@"0%ld",secondss];
        
    }else
    {
        secondsStr=[NSString stringWithFormat:@"%ld",secondss];
    }
    
    NSString *result=[NSString stringWithFormat:@"%@:%@:%@",hourStr,minuesStr,secondsStr];
    return result;
    
}

-(BOOL)shouldAutorotate
{
    return !_Lock;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    
    return UIInterfaceOrientationMaskLandscape;
    
}
-(void)tap{
    
    if (_bottomView.hidden) {
        [self showOrHideTools:YES];
    }else
    {
        [self showOrHideTools:NO];
    }
  
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
  
    
    
}

#pragma mark - AVPlayerViewControllerDelegate
- (void)playerViewControllerWillStartPictureInPicture:(AVPlayerViewController *)playerViewController {
    NSLog(@"%s", __FUNCTION__);
}

- (void)playerViewControllerDidStartPictureInPicture:(AVPlayerViewController *)playerViewController {
    NSLog(@"%s", __FUNCTION__);
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController failedToStartPictureInPictureWithError:(NSError *)error {
    NSLog(@"%s", __FUNCTION__);
}

- (void)playerViewControllerWillStopPictureInPicture:(AVPlayerViewController *)playerViewController {
    NSLog(@"%s", __FUNCTION__);
}

- (void)playerViewControllerDidStopPictureInPicture:(AVPlayerViewController *)playerViewController {
    NSLog(@"%s", __FUNCTION__);
}

- (BOOL)playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart:(AVPlayerViewController *)playerViewController {
    NSLog(@"%s", __FUNCTION__);
    return true;
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler {
    NSLog(@"%s", __FUNCTION__);
}



@end
