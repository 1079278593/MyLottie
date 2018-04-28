//
//  ScreenRecorder.m
//  helloLaihua
//
//  Created by 小明 on 2017/8/31.
//  Copyright © 2017年 laihua. All rights reserved.
//

#import "ScreenRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface ScreenRecorder ()
@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *avAdaptor;
@property (nonatomic, strong) NSDictionary *outputBufferPoolAuxAttributes;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, strong) NSString *videoPath;
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, assign) BOOL isPauseRecording;

//1. recorder use frameRate
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, assign) NSTimeInterval duration;

//2. recorder use time
@property (nonatomic) CFTimeInterval previousStamp;
@property (nonatomic) CFTimeInterval validStamp;

@end

@implementation ScreenRecorder {
    dispatch_queue_t _render_queue;
    dispatch_queue_t _append_pixelBuffer_queue;
    dispatch_semaphore_t _frameRenderingSemaphore;
    dispatch_semaphore_t _pixelAppendSemaphore;
    
    CGSize _viewSize;
    CGFloat _scale;
    
    CGColorSpaceRef _rgbColorSpace;
    CVPixelBufferPoolRef _outputBufferPool;
}

#pragma mark - Life Cycle
+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // _viewSize = [UIApplication sharedApplication].delegate.window.bounds.size;
        _scale = [UIScreen mainScreen].scale;
        _scale = 1.5;
        // record half size resolution for retina iPads
        if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && _scale > 1) {
            _scale = 1.0;
        }
        
        //semaphore set
        _append_pixelBuffer_queue = dispatch_queue_create("VideoRecorder_appendQueue", DISPATCH_QUEUE_SERIAL);
        _render_queue = dispatch_queue_create("VideoRecorder_renderQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_render_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        _frameRenderingSemaphore = dispatch_semaphore_create(1);
        _pixelAppendSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - Video Record Events
- (void)startRecording {
    if (_isRecording) {
        return;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:self.videoPath]) {
        if (![fm removeItemAtPath:self.videoPath error:nil]) {
            NSLog(@"remove screenVideo failed.");
        }
    }
    //设置视频尺寸
    if (self.recorderView.frame.size.width > 0) {
        _viewSize = self.recorderView.frame.size;
    }
    
    [self recorderAttributeSetting];
    
    _isRecording = (self.videoWriter.status == AVAssetWriterStatusWriting);
    
    
    //displaylink方式
    //    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(recordRunloop)];
    //    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    //    if ([[UIDevice currentDevice] systemVersion].floatValue >= 10) {
    //        //10.0以上的设置方法
    //        _displayLink.preferredFramesPerSecond = frameRate;
    //    } else {
    //        /**
    //         10.0以下的系统
    //         iOS设备的刷新频率事60HZ也就是每秒60次。那么每一次刷新的时间就是1/60秒 大概16.7毫秒。当我们的frameInterval值为1的时候我们需要保证的是 CADisplayLink调用的｀target｀的函数计算时间不应该大于 16.7否则就会出现严重的丢帧现象
    //         */
    //        _displayLink.frameInterval = 1;
    //    }
    
    
    //NSOperationQueue方式
    if (!self.queue) {
        //1.创建队列
        self.queue = [[NSOperationQueue alloc] init];
    }
    
    // 2.创建操作：使用 NSInvocationOperation 创建操作
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(recordRunloop) object:nil];
    [self.queue addOperation:operation];
    
    
}

- (void)stopRecording {
    if (!_isRecording) {
        return;
    }
    [self recordFinish];
    [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)pauseRecording {
    [self pauseLayer:self.recorderView.layer];
    _isPauseRecording = YES;
}

- (void)resumeRecording {
    [self resumeLayer:self.recorderView.layer];
    _isPauseRecording = NO;
}

- (void)forceStopRecording {
    NSLog(@"forceStopRecording");
    [self resetRecorder];
    [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    [_videoWriterInput markAsFinished];
    [_videoWriter finishWritingWithCompletionHandler:^{
        
    }];
}
#pragma mark - layer animation pause/resume
- (void)pauseLayer:(CALayer *)layer {
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    NSLog(@"暂停layer动画，paused time:%f", pausedTime);
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}

//继续layer上面的动画
- (void)resumeLayer:(CALayer *)layer {
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
    NSLog(@"pause time:%f", pausedTime);
    NSLog(@"恢复layer动画,begin time:%f", timeSincePause);
}

#pragma mark - recording
- (void)recordRunloop {
    
    while (self.isRecording) {
        
        //    }
        @autoreleasepool {
            
            //        if (!self.isRecording) {
            //            NSLog(@"视频已经结束录制");
            //            return;
            //        }
            
            
            //将当期帧数传递出去
            if (self.frameCountBlock) {
                self.frameCountBlock(self.frameCount);
            }
            
            if (![self.videoWriterInput isReadyForMoreMediaData]) break;
            
            CMTime time;
            if (isRecordFramRate) {
                //按照帧数:(第几帧,每秒帧数)
                self.frameCount++;
                time = CMTimeMake(self.frameCount, (int32_t) frameRate);
                NSLog(@"frame count:%ld", (long) self.frameCount);
                NSLog(@"video duration:%f", (self.frameCount / (float) frameRate));
            } else {
                //按照时间:(第几秒,时间尺度：首选的时间尺度"每秒的帧数")！
                if (self.previousStamp == 0) {
                    self.previousStamp = self.displayLink.timestamp;
                } else {
                    self.validStamp += self.displayLink.timestamp - self.previousStamp;
                    self.previousStamp = self.displayLink.timestamp;
                }
                //            self.duration = CMTimeGetSeconds(self.validStamp);
                time = CMTimeMakeWithSeconds(self.validStamp, 1000);
                NSLog(@"validStamp:%f", self.validStamp);
                NSLog(@"displayLink timestamp:%f", _displayLink.timestamp);
            }
            
            //获取bitmapContext：1.从outputPoolBuffer获取，2.如果设置代理，将会从delegate获取
            CVPixelBufferRef pixelBuffer = NULL;
            //1.从outputPoolBuffer获取
            CGContextRef bitmapContext = [self bitmapContextFromBuffer:&pixelBuffer];
            
            
            // draw each window into the context (other windows include UIKeyboard, UIAlert)
            // FIX: UIKeyboard is currently only rendered correctly in portrait orientation
            UIGraphicsPushContext(bitmapContext); {//切换到bitmapContext
                //填充背景色
                CGContextSetFillColorWithColor(bitmapContext, [UIColor whiteColor].CGColor);
                CGContextFillRect(bitmapContext, CGRectMake(0, 0, _viewSize.width, _viewSize.height));
                
                /**
                 绘制方式：drawInContext、renderInContext、drawViewHierarchyInRect、CGContextDrawImage()
                 */
                CGFloat progressTime = self.validStamp;
                if (isRecordFramRate) {
                    progressTime = (CGFloat) self.frameCount / frameRate;
                }
                
                //1.根据image绘制
//                self.recorderView.animationProgress = progressTime/15.0;
                self.recorderView.time = progressTime;
                
                __block UIImage *image = nil;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    UIGraphicsBeginImageContextWithOptions(_viewSize, NO, [UIScreen mainScreen].scale);
                    [self.recorderView.layer renderInContext:UIGraphicsGetCurrentContext()];
                    image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                });
                
                
                [image drawInRect:CGRectMake(0, 0, _viewSize.width, _viewSize.height)]; //如果image为nil？
                
                if (progressTime > self.totalTime) {
                    [self stopRecording];
                    break;
                }
            }UIGraphicsPopContext();
            
            if (self.isRecording && self.videoWriter) {
                BOOL success = [_avAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
                if (!success) {
                    NSLog(@"Warning: Unable to write buffer to video");
                }
                CGContextRelease(bitmapContext);
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                CVPixelBufferRelease(pixelBuffer);
                
            }
            
        }
        
    }
    //    [self recordRunloop];
    
    
}

- (void)recordFinish;
{
    NSLog(@"recordFinishWithSession");
    
    [_videoWriterInput markAsFinished];
    [_videoWriter finishWritingWithCompletionHandler:^{
        
        void (^completion)(void) = ^() {
            [self resetRecorder];
            self.finishBlock(self.videoPath); //传出地址
        };
        
        if (self.videoURL) {
            completion();
        }
    }];
}

- (CGContextRef)bitmapContextFromBuffer:(CVPixelBufferRef *)pixelBuffer {
    
    CVPixelBufferPoolCreatePixelBuffer(NULL, _outputBufferPool, pixelBuffer);
    CVPixelBufferLockBaseAddress(*pixelBuffer, 0);
    
    CGContextRef bitmapContext = NULL;
    
    bitmapContext = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(*pixelBuffer),
                                          CVPixelBufferGetWidth(*pixelBuffer),
                                          CVPixelBufferGetHeight(*pixelBuffer),
                                          8, CVPixelBufferGetBytesPerRow(*pixelBuffer), _rgbColorSpace,
                                          kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextScaleCTM(bitmapContext, _scale, _scale);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, _viewSize.height);
    
    CGContextConcatCTM(bitmapContext, flipVertical);
    
    return bitmapContext;
}

#pragma mark - Private Methods
///recorder的初始设置
- (void)recorderAttributeSetting {
    
    NSLog(@"setUpWriter");
    _rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    NSDictionary *bufferAttributes = @{(id) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                       (id) kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                                       (id) kCVPixelBufferWidthKey : @(_viewSize.width * _scale),
                                       (id) kCVPixelBufferHeightKey : @(_viewSize.height * _scale),
                                       (id) kCVPixelBufferBytesPerRowAlignmentKey : @(_viewSize.width * _scale * 4)
                                       };
    
    _outputBufferPool = NULL;
    CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)(bufferAttributes), &_outputBufferPool);
    
    //必须删除了这个文件，如果存在这个文件，无法开始新的录制
    [self removeVideoFromPath:self.videoPath];
    
    NSParameterAssert(self.videoWriter);
    
    NSInteger pixelNumber = _viewSize.width * _viewSize.height * _scale;
    NSDictionary *videoCompression = @{ AVVideoAverageBitRateKey : @(pixelNumber * 11.4) }; //11.4视频平均压缩率，值10.1相当于AVCaptureSessionPresetHigh，数值越大，显示越精细，当前7.5
    
    NSDictionary *videoSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                    AVVideoWidthKey : [NSNumber numberWithInt:_viewSize.width * _scale],
                                    AVVideoHeightKey : [NSNumber numberWithInt:_viewSize.height * _scale],
                                    AVVideoCompressionPropertiesKey : videoCompression};
    
    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSParameterAssert(_videoWriterInput);
    
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    _videoWriterInput.transform = [self transformFromOrientation];
    
    _avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput sourcePixelBufferAttributes:nil];
    
    [self.videoWriter addInput:_videoWriterInput];
    
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
}

///根据device的orientation返回transform，设置视频方向
- (CGAffineTransform)transformFromOrientation {
    CGAffineTransform videoTransform;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationLandscapeLeft:
            videoTransform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        case UIDeviceOrientationLandscapeRight:
            videoTransform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            videoTransform = CGAffineTransformMakeRotation(M_PI);
            break;
        default:
            videoTransform = CGAffineTransformIdentity;
    }
    if (self.expireDirection) {
        videoTransform = CGAffineTransformIdentity;
    }
    //    NSLog(@"视频录制方向%d",[UIDevice currentDevice].orientation);
    return videoTransform;
}

///根据path删除视频文件
- (void)removeVideoFromPath:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            NSLog(@"Could not delete old recording:%@", [error localizedDescription]);
        }
    }
}

///根据path，返回文件大小
- (long long)fileSizeFromPath:(NSString *)path {
    NSFileManager *fileMananger = [NSFileManager defaultManager];
    if ([fileMananger fileExistsAtPath:path]) {
        NSDictionary *dic = [fileMananger attributesOfItemAtPath:path error:nil];
        return [dic[ @"NSFileSize" ] longLongValue];
        //  return [[fileMananger attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    
    return 0;
}

///重置recorder
- (void)resetRecorder {
    NSLog(@"resetRecorder"); //
    self.avAdaptor = nil;
    self.videoWriterInput = nil;
    self.videoWriter = nil;
    self.previousStamp = 0;
    self.outputBufferPoolAuxAttributes = nil;
    CGColorSpaceRelease(_rgbColorSpace);
    CVPixelBufferPoolRelease(_outputBufferPool);
    
    _isRecording = NO;
    _isPauseRecording = NO;
    
    //1.帧方式
    self.frameCount = 0;
    self.duration = 0; //这个可以不设置，用于观察时间
    
    //2.时间戳方式
    self.previousStamp = 0;
    self.validStamp = 0;
}

#pragma mark - Getters and Setters
- (AVAssetWriter *)videoWriter {
    
    if (_videoWriter == nil) {
        NSError *error = nil;
        _videoWriter = [[AVAssetWriter alloc] initWithURL:self.videoURL fileType:AVFileTypeQuickTimeMovie error:&error];
    }
    return _videoWriter;
}

- (NSString *)videoPath {
    if (_videoPath == nil) {
        NSString *docPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _videoPath = [docPath stringByAppendingPathComponent:@"screenCapture.mp4"];
        NSLog(@"%@", _videoPath);
    }
    return _videoPath;
}

- (NSURL *)videoURL {
    return [NSURL fileURLWithPath:self.videoPath];
}

@end
