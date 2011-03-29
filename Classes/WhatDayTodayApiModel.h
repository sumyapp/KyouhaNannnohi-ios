//
//  wordItemModel.h
//  german
//
//  Created by Yonemoto Tsuyoshi on 09/10/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "myConnection.h"
#define dekigoto 0
#define tanjyoubi 1

@protocol WhatDayTodayApiModelDelegate;

@interface WhatDayTodayApiModel : NSObject<NSXMLParserDelegate> {
	id <WhatDayTodayApiModelDelegate> delegate;
	NSMutableArray *resultData; // 各問ごとのアイテム
	NSMutableString *tempXMLString; //XMLの要素文字列を保存する変数
	NSString *nowElements;
	NSMutableArray *kinenbiTitles;
	NSString *nowKinenbiTitle;
}

@property(nonatomic, assign) id <WhatDayTodayApiModelDelegate> delegate;
@property(nonatomic, retain) NSMutableArray *resultData;

- (void)loadData:(int)month
			 day:(int)day;
- (void)readXML:(NSString*)request;

@end

@protocol WhatDayTodayApiModelDelegate
- (void)WhatDayTodayApiModelDelegateDidFinish:(WhatDayTodayApiModel *)controller;
@end