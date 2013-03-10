//
//  KyouhaNannnohiViewController.m
//  KyouhaNannnohi
//
//  Created by sumy on 10/01/21.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "KyouhaNannnohiViewController.h"

@implementation KyouhaNannnohiViewController
@synthesize table;
@synthesize resultArray;
@synthesize adview;

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear");    
    [self todayButtonPush];
    
	// MEDIA-ID,SPOT-NOには、管理画面で発行されたメディアID, 枠ナンバーを埋め込んでください。
	// 詳しくはhttp://wiki.ad-stir.com/%E3%83%A1%E3%83%87%E3%82%A3%E3%82%A2ID%E5%8F%96%E5%BE%97をご覧ください。
    if(self.adview == nil) {
        self.adview = [[[AdstirView alloc]initWithOrigin:CGPointMake(0, self.view.frame.size.height-50)]autorelease];
        self.adview.media = @"MEDIA-66bcc171";
        self.adview.spot = 1;
        self.adview.rootViewController = self;
        [self.adview start];
        [self.view addSubview:self.adview];
    }
    //[smAddView startAd];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"viewWillDisappear");
    [self.adview stop];
	[self.adview removeFromSuperview];
	self.adview.rootViewController = nil;
	self.adview = nil;
	[super viewWillDisappear:animated];
    //[smAddView stopAd];
}

- (IBAction)todayButtonPush{
	NSDate* now = [NSDate date];
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	NSString* tmpString;
	int month, day;
	// 現在のロケールを設定 
	[dateFormatter setLocale:[NSLocale currentLocale]];
	
	/*[dateFormatter setDateFormat:@"yyyy"];
	tmpString = [dateFormatter stringFromDate:now];
	year = [tmpString intValue];*/
	
	[dateFormatter setDateFormat:@"MM"];
	tmpString = [dateFormatter stringFromDate:now];
	month = [tmpString intValue];
	
	[dateFormatter setDateFormat:@"dd"];
	tmpString = [dateFormatter stringFromDate:now];
	day = [tmpString intValue];
	
	[dateFormatter release];
	//NSLog(@"year[%d], month[%d], day[%d]", year, month, day);
	[picker selectRow:month-1 inComponent:0 animated:YES];
	[picker selectRow:day-1 inComponent:1 animated:YES];
	//[self setFullDateDateLabel:year month:month day:day];
	[self setDateLabel:month day:day];
}
- (IBAction)tomorrowButtonPush{
	NSDate* now = [NSDate date];
	NSDate* tommorow = [ now addTimeInterval : 86400.0f ];
	
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	NSString* tmpString;
	int month, day;
	// 現在のロケールを設定 
	[dateFormatter setLocale:[NSLocale currentLocale]];
	
	/*
	[dateFormatter setDateFormat:@"yyyy"];
	tmpString = [dateFormatter stringFromDate:tommorow];
	year = [tmpString intValue];
	*/
	
	[dateFormatter setDateFormat:@"MM"];
	tmpString = [dateFormatter stringFromDate:tommorow];
	month = [tmpString intValue];
	
	[dateFormatter setDateFormat:@"dd"];
	tmpString = [dateFormatter stringFromDate:tommorow];
	day = [tmpString intValue];
	
	[dateFormatter release];
	//NSLog(@"year[%d], month[%d], day[%d]", year, month, day);
	[picker selectRow:month-1 inComponent:0 animated:YES];
	[picker selectRow:day-1 inComponent:1 animated:YES];
	//[self setFullDateDateLabel:year month:month day:day];
	[self setDateLabel:month day:day];
}
- (IBAction)searchButtonPush{
    Reachability *reach = [Reachability reachabilityWithHostName:@"www.google.com"];
	if ([reach currentReachabilityStatus] == NotReachable) {		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"接続失敗"
														message:@"ネットワークから情報を手に入れることができませんでした。接続状況を調べて再度試してみてください。"
													   delegate:nil cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		
		[alert show];
		[alert release];
        return;
	}
    
	if(_nowLoading){
		return;
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    _nowLoading = YES;
	
	WhatDayTodayApiModel *wdt = [[[WhatDayTodayApiModel alloc] init] retain];
	wdt.delegate = self;
	[wdt loadData:searchMonth
			  day:searchDay];
}
- (void)WhatDayTodayApiModelDelegateDidFinish:(WhatDayTodayApiModel *)controller {
	resultArray = [[NSArray arrayWithArray:controller.resultData] retain];
	
	[controller release];
	
	[self countNum];
	
	[table reloadData];
	
	if([resultArray count] == 0) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"検索失敗"
														message:@"検索結果がありませんでした。日付を変えて試してみてください。"
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles: nil];
		
		[alert show];
		[alert release];		
	}
	else {
		[self tableHiddenDisable];
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    _nowLoading = NO;
}
- (void)setDateLabel:(int)month
				 day:(int)day{
	dateLabel.text = [NSString stringWithFormat:@"%d月%d日", month, day];
	searchMonth = month;
	searchDay = day;
}
- (void)setFullDateDateLabel:(int)year
					   month:(int)month
						 day:(int)day{
	dateLabel.text = [NSString stringWithFormat:@"%d年%d月%d日", year, month, day];
	searchMonth = month;
	searchDay = day;
}
- (IBAction)closeButtonPush{
	[self tableHiddenEnable];
	topLabel.text = @"今日は何の日？";
}
- (void)tableHiddenEnable{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDidStopSelector:@selector(hiddenEnd)];
	closeButton.alpha = 0.0;
	table.alpha = 0.0;
	topbar.alpha = 0.0;
	//bottombar.alpha = 0.0;
	[UIView commitAnimations];
}
- (void)tableHiddenDisable{
	NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[table scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
	closeButton.hidden = NO;
	table.hidden = NO;
	//bottombar.hidden = NO;
	topbar.hidden = NO;
	topLabel.text = dateLabel.text;
	[self.view bringSubviewToFront:table];
	[UIView beginAnimations:nil context:NULL];
	closeButton.alpha = 1.0;
	table.alpha = 1.0;
	topbar.alpha = 1.0;
	//bottombar.alpha = 1.0;
	[UIView commitAnimations];
}
- (void)hiddenEnd{
	closeButton.hidden = YES;
	table.hidden = YES;
	//bottombar.hidden = YES;
	topbar.hidden = YES;
}
/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	//PickerViewを作成
	picker = [[[UIPickerView alloc] init] autorelease];
	[picker setFrame:CGRectMake(0,196,320,216)];
	picker.delegate = self;
	picker.dataSource = self;
	[picker setShowsSelectionIndicator:YES];         //インジケーター
	[self.view addSubview:picker];
	
    //	広告
    /*
    smAddView = [[SmAddView alloc] initWithFrame:CGRectMake(0, 410, 320, 50)
                            masterViewController:self
                                       isAdInTop:NO
                                smaddAdServerUrl:@"https://smaddnet.appspot.com/apps/351885110"
                          smaddAdServerSecretKey:@"zN2M6FvBQ3X1saT5"
                      enableAdNameSortByPriority:@"admaker,admob,iad,housead"];
    [self.view addSubview:smAddView];    
    */
    if (&UIApplicationDidEnterBackgroundNotification) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(viewWillDisappear:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(viewWillAppear:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:[UIApplication sharedApplication]];
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
	return 2;
}
- (NSInteger)pickerView :(UIPickerView *)pickerView
 numberOfRowsInComponent:(NSInteger)component {
	if(component == 0) {
		return 12;
	}
	else {
		return 31;
	}
}
- (NSString *)pickerView:(UIPickerView *)pickerView 
			 titleForRow: (NSInteger)row 
			forComponent:(NSInteger)component {
	if(component == 0) {
		return [NSString stringWithFormat:@"%d月", row+1];
	}
	else {
		return [NSString stringWithFormat:@"%d日", row+1];
	}
}
- (void) pickerView: (UIPickerView*)pView didSelectRow:(NSInteger) row  inComponent:(NSInteger)component {
	[self setDateLabel:[picker selectedRowInComponent:0]+1 day:[picker selectedRowInComponent:1]+1];
}

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


//tableView関連
// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [resultArray count];
}
*/

/*
 - (NSString *) tableView:(UITableView *) tableView titleForHeaderInSection:(NSInteger) section {	
 }
 */

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	int i = 0;
	//NSLog(@"indexPath.section[%d]", indexPath.section);
	switch (indexPath.section) {
		case 0:
			i = 0;
			break;
		case 1:
			i = dekigotoNum;
			break;
		case 2:
			i = dekigotoNum + tanjyuoubiNum;
			break;
		case 3:
			i = dekigotoNum + tanjyuoubiNum + imibiNum;
			break;
		default:
			break;
	}
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									   reuseIdentifier:CellIdentifier] autorelease];
    }
	//詳細画面の表示
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	
	// Configure the cell.
	//NSLog(@"indexPath.row:%d", indexPath.row);
	NSString *str = [NSString stringWithFormat:@"%@",
					 [[resultArray objectAtIndex:indexPath.row+i] objectForKey:@"item"]];
	NSArray *array = [str componentsSeparatedByString:@","];
		  
	cell.textLabel.text = [NSString stringWithFormat:@"%@, %@", [array objectAtIndex:1], [array objectAtIndex:0]];
	cell.textLabel.textColor = [UIColor blueColor];
	cell.textLabel.font = [UIFont systemFontOfSize:14];
	
	cell.detailTextLabel.text = [array objectAtIndex:2];
	cell.detailTextLabel.textColor = [UIColor blackColor];
	cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    return cell;
}

// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	int i = 0;
	//NSLog(@"indexPath.section[%d]", indexPath.section);
	switch (indexPath.section) {
		case 0:
			i = 0;
			break;
		case 1:
			i = dekigotoNum;
			break;
		case 2:
			i = dekigotoNum + tanjyuoubiNum;
			break;
		case 3:
			i = dekigotoNum + tanjyuoubiNum + imibiNum;
			break;
		default:
			break;
	}
	
	NSString *str = [NSString stringWithFormat:@"%@",
					 [[resultArray objectAtIndex:indexPath.row+i] objectForKey:@"item"]];
	
	NSArray *array = [str componentsSeparatedByString:@","];
	copyStringTmp = [NSString stringWithFormat:@"%@, %@, %@", [array objectAtIndex:1], [array objectAtIndex:0], [array objectAtIndex:2]];
	
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@, %@", [array objectAtIndex:1], [array objectAtIndex:0]]
													message:[array objectAtIndex:2]
												   delegate:self
										  cancelButtonTitle:@"閉じる"
										  otherButtonTitles:@"コピー", nil];
	
	[alert show];
	[alert release];
}
//セルを選択させない
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}
- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//NSLog(actionSheet.title);
	//NSLog(actionSheet.message);
	if(buttonIndex == 1) {
		//UIPasteboard* board = [UIPasteboard generalPasteboard];
		//[board setString:copyStringTmp];  // 文字列の書き込み
		[UIPasteboard generalPasteboard].string = [NSString stringWithFormat:@"%@, %@", actionSheet.title, actionSheet.message];
	}	
}
- (void)countNum{
	dekigotoNum = 0;
	tanjyuoubiNum = 0;
	imibiNum = 0;
	kinenbiNum = 0;
	int i;
	NSString *strTmp;
	NSRange searchResult;
	
	/*test
	strTmp = @"aaaa";
	searchResult = [strTmp rangeOfString:@"bbb"];
	if (searchResult.location == NSNotFound) {
		NSLog(@"notFound");
	}*/
	
	for (i = 0; i < [resultArray count]; i++) {
		strTmp = [NSString stringWithFormat:@"%@",
				  [[resultArray objectAtIndex:i] objectForKey:@"item"]];
		//NSLog(@"%@", strTmp);
		searchResult = [strTmp rangeOfString:@"出来事"];
		if (searchResult.location == NSNotFound) {
			searchResult = [strTmp rangeOfString:@"誕生日"];
			if (searchResult.location == NSNotFound) {
				searchResult = [strTmp rangeOfString:@"忌(み)日"];
				if (searchResult.location == NSNotFound) {
					searchResult = [strTmp rangeOfString:@"記念日"];
					if (searchResult.location == NSNotFound) {
					}
					else {
						kinenbiNum++;
					}

				}
				else {
					imibiNum++;
				}

			}
			else {
				tanjyuoubiNum++;
			}

		}
		else {
			dekigotoNum++;
		}
	}
	//NSLog(@"dekigotoNum[%d], tanjyuoubiNum[%d], imibiNum[%d], kinenbiNum[%d]", dekigotoNum, tanjyuoubiNum, imibiNum, kinenbiNum);
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
/*	int i;
	
	if(dekigotoNum>0)
		i++;
	if(tanjyuoubiNum > 0)
		i++;
	if(imibiNum > 0)
		i++;
	if (kinenbiNum > 0)
		i++;
*/
	return 4;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int i = 0;
	//NSLog(@"%d", section);
	switch (section) {
		case 0:
			i = dekigotoNum;
			break;
		case 1:
			i = tanjyuoubiNum;
			break;
		case 2:
			i = imibiNum;
			break;
		case 3:
			i = kinenbiNum;
			break;
		default:
			break;
	}
	return i;
}
- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section) {
		case 0:
			return @"出来事";
			break;
		case 1:
			return @"誕生日";
			break;
		case 2:
			return @"忌(み)日";
			break;
		case 3:
			return @"記念日";
			break;
		default:
			return @"その他";
			break;
	}
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
//    [smAddView stopAd];
//    [smAddView release], smAddView = nil;
    [table release];
    [resultArray release];
    [picker release];
    [copyStringTmp release];
    
    [super dealloc];
}

@end
