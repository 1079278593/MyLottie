//
//  SVGAnimationView_2.m
//  helloLaihua
//
//  Created by 小明 on 2017/11/4.
//  Copyright © 2017年 laihua. All rights reserved.
//

#import "SVGAnimationView_2.h"
#import <Photos/Photos.h>
#define KMainScreenHeight [UIScreen mainScreen].bounds.size.height
#define KMainScreenWidth [UIScreen mainScreen].bounds.size.width

@interface SVGAnimationView_2 () <CAAnimationDelegate>

@property (nonatomic ,strong)CAShapeLayer *shapeLayer;
@property (nonatomic, strong) UIImageView *handImageView;

@property (nonatomic, strong) UIView *moveView;

@property (nonatomic, assign) CFTimeInterval layerStartTime;

@end

@implementation SVGAnimationView_2


#pragma mark - Life Cycle
- (id)init {
    
    self = [super init];
    if (self) {
        
        self.image = [UIImage imageNamed:@"India"];
        /**
         * contentsScale is 2 -drawInContext: will draw into a buffer twice
         * as large as the layer bounds). Defaults to 1
         如果contentsScale设置为1.0，将会以每个点1个像素绘制图片，如果设置为2.0，则会以每个点2个像素绘制图片，这就是我们熟知的Retina屏幕
         */
        [self.layer setContentsScale:[UIScreen mainScreen].scale];
        
        
        [self chinesePath];
        [self pauseLayer:self.layer];
    }
    
    return self;
}

//此方法不会自己调用，通过setNeedDisplay方法调用
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    NSLog(@"重绘制");
    
    
    double delayInSeconds = 3.2;
    dispatch_time_t dismissTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(dismissTime, dispatch_get_main_queue(), ^(void){
        
    });
    //    [self chinesePath];
    
}

- (void)dealloc {
    
    NSLog(@"svgAni dealloc");
}

#pragma mark - animation delegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    
    NSLog(@"动画结束");
    /*
     *http://blog.csdn.net/devanchen/article/details/51602443
     *setNeedsDisplay会调用自动调用drawRect方法，这样可以拿到 UIGraphicsGetCurrentContext，就可以画画了
     *setNeedsLayout会默认调用layoutSubViews，就可以 处理子视图中的一些数据。
     *综上所诉，setNeedsDisplay方便绘图，而layoutSubViews方便出来数据。
     */
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

#pragma mark - 尝试新增动画，观察layer的时间是否变化
- (void)layerAnimationWithPath:(UIBezierPath *)path {
    
//    CGFloat duration = 15.0;
    CGFloat repeatCount = 1000;
    
    // 关联layer和贝塞尔路径~
    self.shapeLayer.path = path.CGPath;
    
    // 创建Animation
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = @(0.0);
    animation.toValue = @(1.0);
    self.shapeLayer.autoreverses = NO;
    animation.duration = duration;
    animation.repeatCount = repeatCount;
    //    animation.speed = 2.0;
    
    // 设置layer的animation
    [self.shapeLayer addAnimation:animation forKey:nil];
    // 第一种设置动画完成,不移除结果的方法
    //    animation.fillMode = kCAFillModeForwards;
    //    animation.removedOnCompletion = NO;
    
    // 第二种
    self.shapeLayer.strokeEnd = 1;
    
    //    self.shapeLayer.strokeColor = gray.CGColor;
    //    self.shapeLayer.fillColor = [UIColor grayColor].CGColor;
    
    CAKeyframeAnimation *rectRunAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    rectRunAnimation.path = path.CGPath;
    rectRunAnimation.duration = duration;
    //设定每个关键帧的时长，如果没有显式地设置，则默认每个帧的时间=总duration/(values.count - 1)
    //    rectRunAnimation.keyTimes = @[[NSNumber numberWithFloat:0.60]];
    //    rectRunAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    rectRunAnimation.repeatCount = repeatCount + 1000;
    rectRunAnimation.autoreverses = NO;
    rectRunAnimation.calculationMode = kCAAnimationPaced;
    
    //--
    [self.handImageView.layer addAnimation:rectRunAnimation forKey:@"rectRunAnimation"];
}

- (void)replacePath {
    
    NSLog(@"替换动画");
    CGFloat duration = 10.0;
    
    // 创建贝塞尔路径~
    UIBezierPath *path = [UIBezierPath bezierPath];
    //#0
    [path moveToPoint:CGPointMake(21.0, 28.8)];
    [path addLineToPoint:CGPointMake(21.0, 4.2)];
    [path addLineToPoint:CGPointMake(18.0, 3.0)];
    
    
    //#2
    [path moveToPoint:CGPointMake(6.0, 11.4)];
    [path addLineToPoint:CGPointMake(9.0, 12.6)];
    [path addLineToPoint:CGPointMake(9.0, 28.8)];
    
    //#4
    [path moveToPoint:CGPointMake(18.0, 30.6)];
    [path addLineToPoint:CGPointMake(21.0, 31.8)];
    [path addLineToPoint:CGPointMake(18.6, 41.4)];
    [path addLineToPoint:CGPointMake(15.6, 49.2)];
    [path addLineToPoint:CGPointMake(10.2, 59.4)];
    
    //#6
    [path moveToPoint:CGPointMake(4.2, 35.4)];
    [path addLineToPoint:CGPointMake(7.2, 36.6)];
    [path addLineToPoint:CGPointMake(7.2, 69.6)];
    [path addLineToPoint:CGPointMake(5.4, 71.4)];
    [path addLineToPoint:CGPointMake(7.2, 69.6)];
    [path addLineToPoint:CGPointMake(31.2, 64.2)];
    
    //#8
    [path moveToPoint:CGPointMake(66.6, 39.6)];
    [path addLineToPoint:CGPointMake(66.6, 8.4)];
    [path addLineToPoint:CGPointMake(69.0, 6.6)];
    [path addLineToPoint:CGPointMake(66.6, 8.4)];
    [path addLineToPoint:CGPointMake(44.4, 8.4)];
    
    //#9
    [path moveToPoint:CGPointMake(44.4, 22.8)];
    [path addLineToPoint:CGPointMake(66.6, 22.8)];
    
    //#11
    [path moveToPoint:CGPointMake(44.4, 5.4)];
    [path addLineToPoint:CGPointMake(44.4, 73.2)];
    [path addLineToPoint:CGPointMake(43.2, 75.0)];
    [path addLineToPoint:CGPointMake(44.4, 73.2)];
    [path addLineToPoint:CGPointMake(57.6, 65.4)];
    
    //#13
    [path moveToPoint:CGPointMake(50.4, 36.6)];
    [path addLineToPoint:CGPointMake(53.4, 43.2)];
    [path addLineToPoint:CGPointMake(55.8, 48.6)];
    [path addLineToPoint:CGPointMake(61.2, 57.6)];
    [path addLineToPoint:CGPointMake(66.6, 64.2)];
    [path addLineToPoint:CGPointMake(74.4, 70.8)];
    
    // 关联layer和贝塞尔路径~
    self.shapeLayer.path = path.CGPath;
    
    // 创建Animation
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = @(0.0);
    animation.toValue = @(1.0);
    self.shapeLayer.autoreverses = NO;
    animation.duration = duration;
    animation.repeatCount = 1000;
    //    animation.speed = 2.0;
    animation.delegate = self;
    
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
    
    // 设置layer的animation
    [self.shapeLayer addAnimation:animation forKey:nil];
    // 第一种设置动画完成,不移除结果的方法
    //    animation.fillMode = kCAFillModeForwards;
    //    animation.removedOnCompletion = NO;
    
    // 第二种
    self.shapeLayer.strokeEnd = 1;
    
    /////////------------
    
    CAKeyframeAnimation *rectRunAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    rectRunAnimation.path = path.CGPath;
    rectRunAnimation.duration = duration;
    //设定每个关键帧的时长，如果没有显式地设置，则默认每个帧的时间=总duration/(values.count - 1)
    //    rectRunAnimation.keyTimes = @[[NSNumber numberWithFloat:0.60]];
    //    rectRunAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    rectRunAnimation.repeatCount = 1000;
    rectRunAnimation.autoreverses = NO;
    rectRunAnimation.calculationMode = kCAAnimationPaced;
    
    rectRunAnimation.removedOnCompletion = NO;
    rectRunAnimation.fillMode = kCAFillModeBoth;
    
    //--
    [self.handImageView.layer addAnimation:rectRunAnimation forKey:@"rectRunAnimation"];
}

#pragma mark - 主要的动画
- (void)chinesePath {
    
    NSLog(@"文字动画");
//    CGFloat duration = 8.0;
    CGFloat repeat = 1;
    
    // 创建贝塞尔路径~
    UIBezierPath *path = [UIBezierPath bezierPath];
    //#0
    [path moveToPoint:CGPointMake(21.0, 28.8)];
    [path addLineToPoint:CGPointMake(21.0, 4.2)];
    [path addLineToPoint:CGPointMake(18.0, 3.0)];
    
    //#1
    [path moveToPoint:CGPointMake(21.0, 15.0)];
    [path addLineToPoint:CGPointMake(34.2, 15.0)];
    [path addLineToPoint:CGPointMake(30.0, 13.8)];
    [path addLineToPoint:CGPointMake(26.4, 15.0)];
    
    //#2
    [path moveToPoint:CGPointMake(6.0, 11.4)];
    [path addLineToPoint:CGPointMake(9.0, 12.6)];
    [path addLineToPoint:CGPointMake(9.0, 28.8)];
    
    //#3
    [path moveToPoint:CGPointMake(1.2, 28.8)];
    [path addLineToPoint:CGPointMake(37.2, 28.8)];
    [path addLineToPoint:CGPointMake(33.0, 27.0)];
    [path addLineToPoint:CGPointMake(28.8, 28.8)];
    
    //#4
    [path moveToPoint:CGPointMake(18.0, 30.6)];
    [path addLineToPoint:CGPointMake(21.0, 31.8)];
    [path addLineToPoint:CGPointMake(18.6, 41.4)];
    [path addLineToPoint:CGPointMake(15.6, 49.2)];
    [path addLineToPoint:CGPointMake(10.2, 59.4)];
    
    //#5
    [path moveToPoint:CGPointMake(18.6, 43.8)];
    [path addLineToPoint:CGPointMake(22.8, 49.2)];
    [path addLineToPoint:CGPointMake(25.2, 53.4)];
    [path addLineToPoint:CGPointMake(26.4, 58.8)];
    
    //#6
    [path moveToPoint:CGPointMake(4.2, 35.4)];
    [path addLineToPoint:CGPointMake(7.2, 36.6)];
    [path addLineToPoint:CGPointMake(7.2, 69.6)];
    [path addLineToPoint:CGPointMake(5.4, 71.4)];
    [path addLineToPoint:CGPointMake(7.2, 69.6)];
    [path addLineToPoint:CGPointMake(31.2, 64.2)];
    
    //#7
    [path moveToPoint:CGPointMake(31.2, 70.8)];
    [path addLineToPoint:CGPointMake(31.2, 35.4)];
    [path addLineToPoint:CGPointMake(28.2, 34.2)];
    
    //#8
    [path moveToPoint:CGPointMake(66.6, 39.6)];
    [path addLineToPoint:CGPointMake(66.6, 8.4)];
    [path addLineToPoint:CGPointMake(69.0, 6.6)];
    [path addLineToPoint:CGPointMake(66.6, 8.4)];
    [path addLineToPoint:CGPointMake(44.4, 8.4)];
    
    //#9
    [path moveToPoint:CGPointMake(44.4, 22.8)];
    [path addLineToPoint:CGPointMake(66.6, 22.8)];
    
    //#10
    [path moveToPoint:CGPointMake(66.6, 36.6)];
    [path addLineToPoint:CGPointMake(44.4, 36.6)];
    
    //#11
    [path moveToPoint:CGPointMake(44.4, 5.4)];
    [path addLineToPoint:CGPointMake(44.4, 73.2)];
    [path addLineToPoint:CGPointMake(43.2, 75.0)];
    [path addLineToPoint:CGPointMake(44.4, 73.2)];
    [path addLineToPoint:CGPointMake(57.6, 65.4)];
    
    //#12
    [path moveToPoint:CGPointMake(69.0, 42.6)];
    [path addLineToPoint:CGPointMake(72.6, 45.0)];
    [path addLineToPoint:CGPointMake(58.8, 52.8)];
    
    //#13
    [path moveToPoint:CGPointMake(50.4, 36.6)];
    [path addLineToPoint:CGPointMake(53.4, 43.2)];
    [path addLineToPoint:CGPointMake(55.8, 48.6)];
    [path addLineToPoint:CGPointMake(61.2, 57.6)];
    [path addLineToPoint:CGPointMake(66.6, 64.2)];
    [path addLineToPoint:CGPointMake(74.4, 70.8)];
    
    // 关联layer和贝塞尔路径~
    self.shapeLayer.path = path.CGPath;
    
    // 创建Animation
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.fromValue = @(0.0);
    animation.toValue = @(1.0);
    self.shapeLayer.autoreverses = NO;
    animation.duration = duration;
    animation.repeatCount = repeat;
    //    animation.speed = 2.0;
    animation.delegate = self;
    
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeBoth;
    
    // 设置layer的animation
    [self.shapeLayer addAnimation:animation forKey:nil];
    // 第一种设置动画完成,不移除结果的方法
    //    animation.fillMode = kCAFillModeForwards;
    //    animation.removedOnCompletion = NO;
    
    // 第二种
    self.shapeLayer.strokeEnd = 1;
    
    /////////------------
    
    CAKeyframeAnimation *rectRunAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    rectRunAnimation.path = path.CGPath;
    rectRunAnimation.duration = duration;
    //设定每个关键帧的时长，如果没有显式地设置，则默认每个帧的时间=总duration/(values.count - 1)
    //    rectRunAnimation.keyTimes = @[[NSNumber numberWithFloat:0.60]];
    //    rectRunAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    rectRunAnimation.repeatCount = repeat;
    rectRunAnimation.autoreverses = NO;
    rectRunAnimation.calculationMode = kCAAnimationPaced;
    
    rectRunAnimation.removedOnCompletion = NO;
    rectRunAnimation.fillMode = kCAFillModeBoth;
    
    //--
    
    [self.handImageView.layer addAnimation:rectRunAnimation forKey:@"rectRunAnimation"];
}

- (void)pauseLayer:(CALayer *)layer {
    
    //暂停
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
//    NSLog(@"paused time:%f",pausedTime);
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
//    NSLog(@"begin time:%f",timeSincePause);
    
}

#pragma mark - Getters and Setters
- (void)setTime:(CGFloat)time {
    NSLog(@"setTime:%f",time);
    _time = time;

    CALayer *layer = self.layer;
    
//    [self pauseLayer:layer];
    
    CFTimeInterval pausedTime = [layer timeOffset];
    NSLog(@"pausedTime:%f",pausedTime);
    
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
//    layer.beginTime = timeSincePause;
    layer.beginTime = timeSincePause - time*2;
//    NSLog(@"pause time:%f",pausedTime);
    NSLog(@"timeSincePause:%f",timeSincePause);
    NSLog(@"begin time:%f",layer.beginTime);
    
    //begin time后，动画会从新开始，需要pause
    [self pauseLayer:layer];
    /**
     说明：
     pause time是初始暂停的时间，一般不会改变。
     begin time是会随着系统时间而增加。这里可能是个bug，时间拖动越长，slide的value为0时，不是动画的起始时间
     */
}

- (CAShapeLayer *)shapeLayer {
    
    if (_shapeLayer == nil) {
        
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.lineWidth = 2.0f;
        _shapeLayer.lineCap = kCALineCapRound;
        _shapeLayer.lineJoin = kCALineJoinRound;
        _shapeLayer.strokeColor = [UIColor redColor].CGColor;
        _shapeLayer.fillColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:_shapeLayer];
    }
    return _shapeLayer;
}

- (UIImageView *)handImageView {
    
    if (_handImageView == nil) {
        
        _handImageView = [[UIImageView alloc] init];
        _handImageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *image = [UIImage imageNamed:@"hand_1.png"];
        _handImageView.image = image;
        _handImageView.frame = CGRectMake(0, 0, 100, 100 / (image.size.width / image.size.height));
        //改变锚点
        _handImageView.layer.anchorPoint = CGPointMake(0.1, 0.1);
        [self addSubview:_handImageView];
    }
    
    return _handImageView;
}

- (UIView *)moveView {
    if (_moveView == nil) {
        _moveView = [[UIView alloc]init];
        _moveView.backgroundColor = [UIColor redColor];
        [self addSubview:_moveView];
    }
    return _moveView;
}

@end
