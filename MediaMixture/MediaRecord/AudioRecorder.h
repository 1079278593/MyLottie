//
//  AudioRecorder.h
//  helloLaihua
//
//  Created by 小明 on 2017/9/10.
//  Copyright © 2017年 laihua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioRecorder : NSObject

@property (nonatomic, copy, readonly) NSString *audioPath;
@property (nonatomic, copy, readonly) NSString *tmpAudioPath;
@property (nonatomic, strong) AVAudioRecorder *recorder;

+ (instancetype)sharedInstance;

- (void)startRecord;
- (void)stopRecord;
- (void)pauseRecord;
- (void)deleteRecord;

//断点续录
- (void)startBreakPointRecord;
- (void)pauseBreakPointRecord;

@end
