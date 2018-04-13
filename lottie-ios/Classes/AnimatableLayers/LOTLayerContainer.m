//
//  LOTLayerContainer.m
//  Lottie
//
//  Created by brandon_withrow on 7/18/17.
//  Copyright © 2017 Airbnb. All rights reserved.
//

#import "CGGeometry+LOTAdditions.h"
#import "LOTAsset.h"
#import "LOTHelpers.h"
#import "LOTLayerContainer.h"
#import "LOTMaskContainer.h"
#import "LOTNumberInterpolator.h"
#import "LOTRenderGroup.h"
#import "LOTTransformInterpolator.h"

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
#import "LOTCacheProvider.h"
#endif

@implementation LOTLayerContainer {
    LOTTransformInterpolator *_transformInterpolator;
    LOTNumberInterpolator *_opacityInterpolator;
    NSNumber *_inFrame;
    NSNumber *_outFrame;
    CALayer *DEBUG_Center;
    LOTRenderGroup *_contentsGroup;
    LOTMaskContainer *_maskLayer;
}

//CALayer在运行时自动生成了currentFrame的set和get方法,不要在CALayer中实现自定义的存取方法或是使用@synthesize.所以使用@dynamic实现radius属性，@dynamic就是告诉编译器,不自动生成setter和getter方法
@dynamic currentFrame;

#pragma mark - Life Cycle

//display:调用后触发
- (id)initWithLayer:(id)layer {
    if (self = [super initWithLayer:layer]) {
        if ([layer isKindOfClass:[LOTLayerContainer class]]) {
            LOTLayerContainer *other = (LOTLayerContainer *) layer;
            self.currentFrame = [other.currentFrame copy];
        }
    }
    return self;
}

- (instancetype)initWithModel:(LOTLayer *)layer inLayerGroup:(LOTLayerGroup *)layerGroup {
    
    self = [super init];
    if (self) {
        _wrapperLayer = [CALayer new];
        [self addSublayer:_wrapperLayer];
        DEBUG_Center = [CALayer layer];
        
        DEBUG_Center.bounds = CGRectMake(0, 0, 20, 20);
        DEBUG_Center.borderColor = [UIColor blueColor].CGColor;
        DEBUG_Center.borderWidth = 2;
        DEBUG_Center.masksToBounds = YES;
        
        if (ENABLE_DEBUG_SHAPES) {
            [_wrapperLayer addSublayer:DEBUG_Center];
        }
        self.actions = @{@"hidden" : [NSNull null], @"opacity" : [NSNull null], @"transform" : [NSNull null]};
        _wrapperLayer.actions = [self.actions copy];
        _timeStretchFactor = @1;
        [self commonInitializeWith:layer inLayerGroup:layerGroup];
    }
    return self;
}

- (void)commonInitializeWith:(LOTLayer *)layer inLayerGroup:(LOTLayerGroup *)layerGroup {
    if (layer == nil) {
        return;
    }
    _layerName = layer.layerName;
    if (layer.layerType == LOTLayerTypeImage ||
        layer.layerType == LOTLayerTypeSolid ||
        layer.layerType == LOTLayerTypePrecomp) {
        _wrapperLayer.bounds = CGRectMake(0, 0, layer.layerWidth.floatValue, layer.layerHeight.floatValue);
        _wrapperLayer.anchorPoint = CGPointMake(0, 0);
        _wrapperLayer.masksToBounds = YES;
        DEBUG_Center.position = LOT_RectGetCenterPoint(self.bounds);
    }
    
    if (layer.layerType == LOTLayerTypeImage) {
        [self _setImageForAsset:layer.imageAsset];
    }
    
    _inFrame = [layer.inFrame copy];
    _outFrame = [layer.outFrame copy];
    
    _timeStretchFactor = [layer.timeStretch copy];
    _transformInterpolator = [LOTTransformInterpolator transformForLayer:layer];
    
    if (layer.parentID) {
        NSNumber *parentID = layer.parentID;
        LOTTransformInterpolator *childInterpolator = _transformInterpolator;
        while (parentID != nil) {
            LOTLayer *parentModel = [layerGroup layerModelForID:parentID];
            LOTTransformInterpolator *interpolator = [LOTTransformInterpolator transformForLayer:parentModel];
            childInterpolator.inputNode = interpolator;
            childInterpolator = interpolator;
            parentID = parentModel.parentID;
        }
    }
    _opacityInterpolator = [[LOTNumberInterpolator alloc] initWithKeyframes:layer.opacity.keyframes];
    if (layer.layerType == LOTLayerTypeShape &&
        layer.shapes.count) {
        [self buildContents:layer.shapes];
    }
    if (layer.layerType == LOTLayerTypeSolid) {
        _wrapperLayer.backgroundColor = layer.solidColor.CGColor;
    }
    if (layer.masks.count) {
        _maskLayer = [[LOTMaskContainer alloc] initWithMasks:layer.masks];
        _wrapperLayer.mask = _maskLayer;
    }
    
    NSMutableDictionary *interpolators = [NSMutableDictionary dictionary];
    interpolators[ @"Opacity" ] = _opacityInterpolator;
    interpolators[ @"Anchor Point" ] = _transformInterpolator.anchorInterpolator;
    interpolators[ @"Scale" ] = _transformInterpolator.scaleInterpolator;
    interpolators[ @"Rotation" ] = _transformInterpolator.rotationInterpolator;
    if (_transformInterpolator.positionXInterpolator &&
        _transformInterpolator.positionYInterpolator) {
        interpolators[ @"X Position" ] = _transformInterpolator.positionXInterpolator;
        interpolators[ @"Y Position" ] = _transformInterpolator.positionYInterpolator;
    } else if (_transformInterpolator.positionInterpolator) {
        interpolators[ @"Position" ] = _transformInterpolator.positionInterpolator;
    }
    
    // Deprecated
    interpolators[ @"Transform.Opacity" ] = _opacityInterpolator;
    interpolators[ @"Transform.Anchor Point" ] = _transformInterpolator.anchorInterpolator;
    interpolators[ @"Transform.Scale" ] = _transformInterpolator.scaleInterpolator;
    interpolators[ @"Transform.Rotation" ] = _transformInterpolator.rotationInterpolator;
    if (_transformInterpolator.positionXInterpolator &&
        _transformInterpolator.positionYInterpolator) {
        interpolators[ @"Transform.X Position" ] = _transformInterpolator.positionXInterpolator;
        interpolators[ @"Transform.Y Position" ] = _transformInterpolator.positionYInterpolator;
    } else if (_transformInterpolator.positionInterpolator) {
        interpolators[ @"Transform.Position" ] = _transformInterpolator.positionInterpolator;
    }
    _valueInterpolators = interpolators;
}

- (void)buildContents:(NSArray *)contents {
    _contentsGroup = [[LOTRenderGroup alloc] initWithInputNode:nil contents:contents keyname:_layerName];
    [_wrapperLayer addSublayer:_contentsGroup.containerLayer];
}

#pragma mark - 自定义属性，动画
/**
 Core Animation 隐式的为很多图层属性添加动画,比如:position,transform,contents,通过改变其属性值,便可以达到动画效果.但如果我们要自定义CALayer.那么CALayer子类的自定义属性如何也能在创建子类后,修改属性值就可以达到动画效果呢?
 链接：https://www.jianshu.com/p/78e1b416e56a
 */

// MARK - Animation

//覆盖needDisplayForKey:方法,这是最为主要的方法,在这个方法我们判断如果里面的key值与radius相同的话,便返回yes.这样我们就可以检测radius这个属性值的变化,如果发现属性值变了,就可以自动重绘，自动重绘时，系统调用display:
+ (BOOL)needsDisplayForKey:(NSString *)key {
    if ([key isEqualToString:@"currentFrame"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

//重写覆盖actionForKey:方法,以此返回一个在当前图层(presentationLayer)中有半径起点值的动画.这就可以让动画发生过程中,设置动画效果
- (id<CAAction>)actionForKey:(NSString *)event {
    NSLog(@"actionForKey");
    if ([event isEqualToString:@"currentFrame"]) {
        CABasicAnimation *theAnimation = [CABasicAnimation
                                          animationWithKeyPath:event];
        theAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        theAnimation.fromValue = [[self presentationLayer] valueForKey:event];
        return theAnimation;
    }
    return [super actionForKey:event];
}

#pragma mark - display(属性修改调用needsDisplayForKey，最终导致display被系统调用)
//当CALayer或其子类属性被修改时调用此方法：needsDisplayForKey:
//key为修改的属性名，返回YES后，系统会自动调用-display方法
- (void)display {
    @synchronized(self) {
        LOTLayerContainer *presentation = self;
        if (self.animationKeys.count && self.presentationLayer) {
            presentation = (LOTLayerContainer *) self.presentationLayer;
        }
        [self displayWithFrame:presentation.currentFrame];
    }
}

- (void)displayWithFrame:(NSNumber *)frame {
    [self displayWithFrame:frame forceUpdate:NO];
}

#pragma mark 这里display
- (void)displayWithFrame:(NSNumber *)frame forceUpdate:(BOOL)forceUpdate {
    NSNumber *newFrame = @(frame.floatValue / self.timeStretchFactor.floatValue);
    if (ENABLE_DEBUG_LOGGING) NSLog(@"View %@ Displaying Frame %@, with local time %@", self, frame, newFrame);
    BOOL hidden = NO;
    if (_inFrame && _outFrame) {
        hidden = (frame.floatValue < _inFrame.floatValue ||
                  frame.floatValue > _outFrame.floatValue);
    }
    self.hidden = hidden;
    if (hidden) {
        return;
    }
    if (_opacityInterpolator && [_opacityInterpolator hasUpdateForFrame:newFrame]) {
        self.opacity = [_opacityInterpolator floatValueForFrame:newFrame];
    }
    if (_transformInterpolator && [_transformInterpolator hasUpdateForFrame:newFrame]) {
        _wrapperLayer.transform = [_transformInterpolator transformForFrame:newFrame];
    }
    [_contentsGroup updateWithFrame:newFrame withModifierBlock:nil forceLocalUpdate:forceUpdate];
    _maskLayer.currentFrame = newFrame;
}

#pragma mark - Getter And Setter
- (void)setViewportBounds:(CGRect)viewportBounds {
    _viewportBounds = viewportBounds;
    if (_maskLayer) {
        CGPoint center = LOT_RectGetCenterPoint(viewportBounds);
        viewportBounds.origin = CGPointMake(-center.x, -center.y);
        _maskLayer.bounds = viewportBounds;
    }
}

- (void)searchNodesForKeypath:(LOTKeypath *_Nonnull)keypath {
    if (_contentsGroup == nil && [keypath pushKey:self.layerName]) {
        // Matches self.
        if ([keypath pushKey:@"Transform"]) {
            // Is a transform node, check interpolators
            LOTValueInterpolator *interpolator = _valueInterpolators[ keypath.currentKey ];
            if (interpolator) {
                // We have a match!
                [keypath pushKey:keypath.currentKey];
                [keypath addSearchResultForCurrentPath:_wrapperLayer];
                [keypath popKey];
            }
            if (keypath.endOfKeypath) {
                [keypath addSearchResultForCurrentPath:_wrapperLayer];
            }
            [keypath popKey];
        }
        if (keypath.endOfKeypath) {
            [keypath addSearchResultForCurrentPath:_wrapperLayer];
        }
        [keypath popKey];
    }
    [_contentsGroup searchNodesForKeypath:keypath];
}

- (void)setValueDelegate:(id<LOTValueDelegate> _Nonnull)delegate
              forKeypath:(LOTKeypath *_Nonnull)keypath {
    if ([keypath pushKey:self.layerName]) {
        // Matches self.
        if ([keypath pushKey:@"Transform"]) {
            // Is a transform node, check interpolators
            LOTValueInterpolator *interpolator = _valueInterpolators[ keypath.currentKey ];
            if (interpolator) {
                // We have a match!
                [interpolator setValueDelegate:delegate];
            }
            [keypath popKey];
        }
        [keypath popKey];
    }
    [_contentsGroup setValueDelegate:delegate forKeypath:keypath];
}

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR

- (void)_setImageForAsset:(LOTAsset *)asset {
    if (asset.imageName) {
        UIImage *image;
        if (asset.rootDirectory.length > 0) {
            NSString *rootDirectory = asset.rootDirectory;
            if (asset.imageDirectory.length > 0) {
                rootDirectory = [rootDirectory stringByAppendingPathComponent:asset.imageDirectory];
            }
            NSString *imagePath = [rootDirectory stringByAppendingPathComponent:asset.imageName];
            
            id<LOTImageCache> imageCache = [LOTCacheProvider imageCache];
            if (imageCache) {
                image = [imageCache imageForKey:imagePath];
                if (!image) {
                    image = [UIImage imageWithContentsOfFile:imagePath];
                    [imageCache setImage:image forKey:imagePath];
                }
            } else {
                image = [UIImage imageWithContentsOfFile:imagePath];
            }
        } else {
            NSString *imagePath = [asset.assetBundle pathForResource:asset.imageName ofType:nil];
            image = [UIImage imageWithContentsOfFile:imagePath];
        }
        
        if (image) {
            _wrapperLayer.contents = (__bridge id _Nullable)(image.CGImage);
        } else {
            NSLog(@"%s: Warn: image not found: %@", __PRETTY_FUNCTION__, asset.imageName);
        }
    }
}

#else

- (void)_setImageForAsset:(LOTAsset *)asset {
    if (asset.imageName) {
        NSArray *components = [asset.imageName componentsSeparatedByString:@"."];
        NSImage *image = [NSImage imageNamed:components.firstObject];
        if (image) {
            NSWindow *window = [NSApp mainWindow];
            CGFloat desiredScaleFactor = [window backingScaleFactor];
            CGFloat actualScaleFactor = [image recommendedLayerContentsScale:desiredScaleFactor];
            id layerContents = [image layerContentsForContentsScale:actualScaleFactor];
            _wrapperLayer.contents = layerContents;
        }
    }
}

#endif

@end
