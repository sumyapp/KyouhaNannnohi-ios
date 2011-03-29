//
//  AdMakerDelegate.h
//
//
//  Copyright 2011 NOBOT Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AdMakerView;

@protocol AdMakerDelegate<NSObject>

@required
-(UIViewController*)currentViewControllerForAd;

-(NSArray*)adKey;

@optional
- (void)requestAdSuccess;
- (void)requestAdFail;


@end
