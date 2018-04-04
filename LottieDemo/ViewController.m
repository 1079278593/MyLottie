//
//  ViewController.m
//  LottieDemo
//
//  Created by 小明 on 2018/3/19.
//  Copyright © 2018年 laihua. All rights reserved.
//

#import "ViewController.h"
#import "Lottie.h"
#define KMainScreenHeight [UIScreen mainScreen].bounds.size.height
#define KMainScreenWidth [UIScreen mainScreen].bounds.size.width
#define RGBA(r, g, b, a) [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a]

@interface ViewController ()
@property (nonatomic, strong) UISlider *timeSlider;
@property (nonatomic, strong) LOTAnimationView *lotView;

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
    self.lotView.autoReverseAnimation = YES;
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
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark slider event
- (void)sliderValueChanged:(UISlider *)slider {
    self.lotView.animationProgress = slider.value;
}

- (void)sliderDragUp:(UISlider *)slider {
    
}

-(UISlider *)timeSlider{
    
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
