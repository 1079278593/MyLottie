//
//  ViewController.m
//  LottieDemo
//
//  Created by 小明 on 2018/3/19.
//  Copyright © 2018年 laihua. All rights reserved.
//

#import "ViewController.h"
#import "Lottie.h"
#import "ScreenRecorder.h"
#import "SVGAnimationView_2.h"
#define KMainScreenHeight [UIScreen mainScreen].bounds.size.height
#define KMainScreenWidth [UIScreen mainScreen].bounds.size.width
#define RGBA(r, g, b, a) [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a]

@interface ViewController ()
@property (nonatomic, strong) UISlider *timeSlider;
@property (nonatomic, strong) LOTAnimationView *lotView;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic ,strong) ScreenRecorder *screenRecorder;
@property (nonatomic ,strong) UIImageView *imgView;
@property (nonatomic, strong) SVGAnimationView_2 *svgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //1.url
//    LOTAnimationView *animation = [[LOTAnimationView alloc] initWithContentsOfURL:[NSURL URlfil]];
//    [self.view addSubview:animation];
    
    //2.json
    self.lotView = [LOTAnimationView animationNamed:@"give_the_thumbs-up"];
    [self.view addSubview:self.lotView];
    self.lotView.loopAnimation = YES;
//    self.lotView.autoReverseAnimation = YES;
//    [self.lotView setValueDelegate:self forKeypath:nil];
    [self.lotView playWithCompletion:^(BOOL animationFinished) {
        // Do Something
    }];
    
//    UIView *moveView = [[UIView alloc]init];
//    moveView.frame = CGRectMake(100, 250, 100, 100);
//    moveView.backgroundColor = [UIColor redColor];
//    [self.view addSubview:moveView];
//
//    [UIView animateWithDuration:1 animations:^{
////        [UIView setAnimationRepeatCount:100];
//        moveView.frame = CGRectMake(100, 350, 100, 100);
//    }];
    
    self.timeSlider.frame = CGRectMake(0, KMainScreenHeight - 20, KMainScreenWidth, 20);
    
    self.button.frame = CGRectMake(100, 280, 80, 44);
    self.imgView.frame = CGRectMake(100, 380, 100, 100);
    self.svgView.frame = CGRectMake(0, 0, 50, 50);
    self.svgView.backgroundColor = [[UIColor lightGrayColor]colorWithAlphaComponent:0.3];
    
    self.screenRecorder = [ScreenRecorder sharedInstance];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Event
- (void)recordEvent:(UIButton *)button {
    
    [self timerFire];
    return;
    double delayInSeconds = 3.2;
    dispatch_time_t dismissTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(dismissTime, dispatch_get_main_queue(), ^(void){
        
        NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFire) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        
    });
    
}

- (void)timerFire {
    
    self.screenRecorder.recorderView = self.svgView;
    self.screenRecorder.totalTime = 15;
    self.screenRecorder.expireDirection = UIDeviceOrientationPortrait;
    [self.screenRecorder startRecording];
    
    //监听finishBlock
    self.screenRecorder.finishBlock = ^(NSString *path) {
        //录制完成，开始合成录音
        NSLog(@"录制完成");
    };
}

#pragma mark slider event
- (void)sliderValueChanged:(UISlider *)slider {
    self.lotView.animationProgress = slider.value;
    self.svgView.time = slider.value*15;
    
}

- (void)sliderDragUp:(UISlider *)slider {
    
}


#pragma mark - Getter And Setter
- (UIButton *)button {
    if (_button == nil) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.backgroundColor = [[UIColor redColor]colorWithAlphaComponent:0.3];
        [_button setTitle:@"录制" forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(recordEvent:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_button];
    }
    return _button;
}

- (UIImageView *)imgView {
    if (_imgView == nil) {
        _imgView = [[UIImageView alloc]init];
        _imgView.contentMode = UIViewContentModeScaleAspectFit;
        _imgView.backgroundColor = [UIColor lightGrayColor];
        [self.view addSubview:_imgView];
    }
    return _imgView;
}

- (SVGAnimationView_2 *)svgView {
    
    if (_svgView == nil) {
        _svgView = [[SVGAnimationView_2 alloc] init];
        [self.lotView addSubview:_svgView];
    }
    return _svgView;
}

- (UISlider *)timeSlider{
    
    if (_timeSlider == nil) {
        
        _timeSlider = [[UISlider alloc]init];
        _timeSlider.backgroundColor = [UIColor clearColor];
        _timeSlider.enabled = !NO;//禁止滑动
        _timeSlider.value = 0.0;
        _timeSlider.minimumValue=0.0;
        _timeSlider.maximumValue=1.0;
        
        [_timeSlider setMinimumTrackImage:nil forState:UIControlStateNormal];
        [_timeSlider setMaximumTrackImage:nil forState:UIControlStateNormal];
        
        //注意这里要加UIControlStateHightlighted的状态，否则当拖动滑块时滑块将变成原生的控件
        [_timeSlider setThumbImage:[UIImage imageNamed:@"sliderBtn"] forState:UIControlStateHighlighted];
        [_timeSlider setThumbImage:[UIImage imageNamed:@"sliderBtn"] forState:UIControlStateNormal];
        
        //滑块拖动时的事件
        [_timeSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        //滑动拖动后的事件
        [_timeSlider addTarget:self action:@selector(sliderDragUp:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_timeSlider];
    }
    
    return _timeSlider;
}
@end
