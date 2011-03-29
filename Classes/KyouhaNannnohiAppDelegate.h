//
//  KyouhaNannnohiAppDelegate.h
//  KyouhaNannnohi
//
//  Created by sumy on 10/01/21.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KyouhaNannnohiViewController;

@interface KyouhaNannnohiAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    KyouhaNannnohiViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet KyouhaNannnohiViewController *viewController;

@end

