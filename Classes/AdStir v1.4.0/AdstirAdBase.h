//
//  Copyright 2012-2013 UNITED, inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kAdstirAdErrorTimedOut = 100,
    kAdstirAdErrorParameter = 200,
    kAdstirAdErrorWebview = 300,
} AdstirAdError;

@protocol AdstirAdDelegate;

@interface AdstirAdBase : UIView
@property (copy) NSString*  media;
@property (copy) NSString*  spot;
@property (assign) NSTimeInterval interval;
@property (assign) id<AdstirAdDelegate> delegate;
@end

@protocol AdstirAdDelegate <NSObject>
- (void)adstirAdDidReceived:(AdstirAdBase*)view;
- (void)adstirAdDidFailed:(AdstirAdBase*)view;
- (void)adstirAdDidError:(AdstirAdBase*)view WithCode:(AdstirAdError)code;
@end

@interface AdstirAdpapriView : AdstirAdBase
@end

@interface AdstirBypassClickView : AdstirAdBase
@end

@interface AdstirIconView : AdstirAdBase
@property (copy) NSString*  slot;
@end

