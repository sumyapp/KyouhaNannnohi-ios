//
//  Copyright 2011-2013 UNITED, inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AdstirViewDelegate;

@interface AdstirView : UIView
// Initialization
- (id)init;
- (id)initWithOrigin:(CGPoint)origin;

// Required properties
@property (nonatomic,copy) NSString* media;
@property (nonatomic,assign) int spot;
@property (nonatomic,assign) UIViewController* rootViewController;

// Optional properties
@property (nonatomic,assign) NSTimeInterval updateAdstirConfigInterval;
@property (nonatomic,assign) id<AdstirViewDelegate> delegate;
- (void) start;
- (void) stop;

@end

@protocol AdstirViewDelegate <NSObject>
@optional
- (void)adstirDidReceiveAd:(AdstirView*)adstirview;
- (void)adstirDidFailToReceiveAd:(AdstirView*)adstirview;
@end
