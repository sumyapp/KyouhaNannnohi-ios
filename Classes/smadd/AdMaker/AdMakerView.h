//
//  AdMakerView.h
//
//
//  Copyright 2011 NOBOT Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdMakerDelegate.h"

@protocol AdMakerDelegate;

@interface AdMakerView : UIWebView <UIWebViewDelegate> {
	id<AdMakerDelegate> delegate;
}

+(AdMakerView*)sharedManager;
-(void)adMakerDelegate:(id)_delegate;
-(id)myInitWithFrame:(CGRect)frame; //広告の表示位置
-(void)deleteInstance; //AdMakerの削除

- (void)viewDidAppear;
- (void)viewWillDisappear;


@end