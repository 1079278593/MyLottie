//
//  LOTRenderNode.h
//  Pods
//
//  Created by brandon_withrow on 6/27/17.
//
//  类似于虚基类，只是用于初始的配置，以及返回值

#import "LOTAnimatorNode.h"

@interface LOTRenderNode : LOTAnimatorNode

//绘制不规则图形
@property (nonatomic, readonly, strong) CAShapeLayer * _Nonnull outputLayer;

- (NSDictionary * _Nonnull)actionsForRenderLayer;

@end
