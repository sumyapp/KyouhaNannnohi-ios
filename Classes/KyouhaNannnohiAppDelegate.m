//
//  KyouhaNannnohiAppDelegate.m
//  KyouhaNannnohi
//
//  Created by sumy on 10/01/21.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "KyouhaNannnohiAppDelegate.h"
#import "KyouhaNannnohiViewController.h"

@implementation KyouhaNannnohiAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    self.window.rootViewController = viewController;

    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
