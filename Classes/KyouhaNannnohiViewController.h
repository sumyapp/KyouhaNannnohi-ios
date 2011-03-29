//
//  KyouhaNannnohiViewController.h
//  KyouhaNannnohi
//
//  Created by sumy on 10/01/21.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "WhatDayTodayApiModel.h"
#import "SmAddView.h"

@interface KyouhaNannnohiViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, WhatDayTodayApiModelDelegate, UIAlertViewDelegate> {
	UIPickerView* picker;
	IBOutlet UILabel* dateLabel;
	IBOutlet UILabel* topLabel;

	int searchMonth;
	int searchDay;
	
	IBOutlet UITableView *table;
	IBOutlet UIButton *closeButton;
	IBOutlet UIImageView *topbar;
	//IBOutlet UIImageView *bottombar;
	
	NSArray *resultArray;
	NSString *copyStringTmp;
	
	int dekigotoNum;
	int tanjyuoubiNum;
	int imibiNum;
	int kinenbiNum;
    
    BOOL _nowLoading;
    
	//ad
	SmAddView *smAddView;
}
- (IBAction)todayButtonPush;
- (IBAction)tomorrowButtonPush;
- (IBAction)searchButtonPush;
- (IBAction)closeButtonPush;

- (void)setDateLabel:(int)month
					 day:(int)day;
- (void)setFullDateDateLabel:(int)year
			   month:(int)month
				 day:(int)day;
- (void)tableHiddenEnable;
- (void)tableHiddenDisable;
- (void)hiddenEnd;
- (void)countNum;

@property(nonatomic, retain) UITableView *table;
@property(nonatomic, retain) NSArray *resultArray;
@end

