//
//  ScreenRecorder.h
//  helloLaihua
//
//  Created by 小明 on 2017/8/31.
//  Copyright © 2017年 laihua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LOTAnimationView.h"
#import "SVGAnimationView_2.h"
@protocol ScreenRecorderDelegate;

#define frameRate 25 //用作DisplayLink的runloop、按帧导出方式的'时间CMTime'
static const BOOL isRecordFramRate = !NO; //默认按照时间戳方式录制:NO。YES代表按照帧数录制
typedef void (^RecordFinishBlock)(NSString *videoPath);
typedef void (^VideoFrameCountBlock)(NSInteger frameCount);

@interface ScreenRecorder : NSObject

/*
 *视频文件路径
 */
@property (nonatomic, strong, readonly) NSString *videoPath;


/*
 *视频录制完成后的block回调
 */
@property (nonatomic ,strong)RecordFinishBlock finishBlock;


/*
 *视频录制进度(帧数)
 */
@property (nonatomic ,strong)VideoFrameCountBlock frameCountBlock;


/*
 *必须设置
 *录制这个目标view:SVGAnimationView_2  LOTAnimationView
 */
@property (nonatomic, strong)SVGAnimationView_2 *recorderView;


/*
 *必须设置
 *录制时长
 */
@property (nonatomic, assign)CGFloat totalTime;


/*
 *生成的视频方向，默认根据设备方向来设置。传入一个指定方向，则视频方向按照指定方向生成(方向主要指的是：横屏竖屏)
 */
@property (nonatomic, assign) UIDeviceOrientation expireDirection;


/*
 *delegate
 */
@property (nonatomic, weak)id<ScreenRecorderDelegate> delegate;
+ (instancetype)sharedInstance;


/*
 *视频的：开始、结束、暂停、恢复、中断等等操作
 */
- (void)startRecording;
- (void)stopRecording;
- (void)pauseRecording;
- (void)resumeRecording;

///强行结束录制
- (void)forceStopRecording;

@end
