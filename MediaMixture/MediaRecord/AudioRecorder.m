//
//  AudioRecorder.m
//  helloLaihua
//
//  Created by 小明 on 2017/9/10.
//  Copyright © 2017年 laihua. All rights reserved.
//

#import "AudioRecorder.h"

@interface AudioRecorder ()

@property (nonatomic, strong) AVAudioRecorder *tmpRecorder;

@property (nonatomic, copy) NSString *audioPath;
@property (nonatomic, copy) NSString *tmpAudioPath;

@end

@implementation AudioRecorder

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
        
    }
    return self;
}

#pragma mark - Recorder Event
///start or resume a record
- (void)startRecord {

    // Set session category
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    // Set the session active
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if ([self.recorder prepareToRecord]) {
        [self.recorder record];
        NSLog(@"开始录音");
    }
}

- (void)stopRecord {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    // Set the session active
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self.recorder stop];
}

- (void)pauseRecord {
    [self.recorder pause];
}

- (void)deleteRecord {
    [self.recorder deleteRecording];
}

#pragma mark 断点续录
- (void)startBreakPointRecord {
    if ([self.recorder prepareToRecord]) {
        [self.recorder record];
        NSLog(@"开始录音");
    }
}

- (void)pauseBreakPointRecord {
    
    //1.保存一小段音频(stop即保存)
//    [self stopRecord];
    
    //2.
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.audioPath]) {
        NSError *error;
        if ([fileManager createDirectoryAtPath:self.audioPath withIntermediateDirectories:YES attributes:nil error:&error] == NO) {
            NSLog(@"Could not delete old recording:%@", [error localizedDescription]);
        }
    }
}

#pragma mark - Private method
- (NSDictionary *)recordSetting {
    
    NSDictionary *setting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey, //采样率
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,//通道的数目
                                   nil];
    return setting;
}

#pragma mark - Getters
- (AVAudioRecorder *)recorder {
    
    if (_recorder == nil) {
        
        // Set session category
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        // Set the session active
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        _recorder.meteringEnabled = YES;// Monitor sound wave
        _recorder = [[AVAudioRecorder alloc] initWithURL:[self audioPathURL] settings:[self recordSetting] error:nil];
    }
    
    return _recorder;
}

- (AVAudioRecorder *)tmpRecorder {
    
    if (_tmpRecorder == nil) {
        
        // Set session category
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        // Set the session active
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        _tmpRecorder.meteringEnabled = YES;// Monitor sound wave
        _tmpRecorder = [[AVAudioRecorder alloc] initWithURL:[self tmpAudioPathURL] settings:[self recordSetting] error:nil];
    }
    
    return _tmpRecorder;
}

- (NSString *)audioPath {
    if (_audioPath == nil) {
        NSString *docPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _audioPath = [docPath stringByAppendingPathComponent:@"sound.wav"];
        NSLog(@"%@",_audioPath);
    }
    return _audioPath;
}

- (NSString *)tmpAudioPath {
    if (_tmpAudioPath == nil) {
        NSString *docPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _tmpAudioPath = [docPath stringByAppendingPathComponent:@"tmpSound.wav"];
        NSLog(@"%@",_tmpAudioPath);
    }
    return _tmpAudioPath;
}

- (NSURL *)audioPathURL {
    return [NSURL fileURLWithPath:self.audioPath];
}

- (NSURL *)tmpAudioPathURL {
    return [NSURL fileURLWithPath:self.tmpAudioPath];
}

@end
