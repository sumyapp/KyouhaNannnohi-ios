//
//  wordItemModel.m
//  german
//
//  Created by Yonemoto Tsuyoshi on 09/10/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "WhatDayTodayApiModel.h"

@implementation WhatDayTodayApiModel
@synthesize delegate;
@synthesize resultData;

- (void)loadData:(int)month
			 day:(int)day{
	NSString* request = [[NSString stringWithFormat:@"http://www.mizunotomoaki.com/wikipedia_daytopic/api.cgi/%d/%d", month, day]
						 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];		
	[self readXML:request];
}

- (void)readXML:(NSString*) request
{
	//NSLog(@"start readXML");
	myConnection * con = [[[myConnection alloc] init] autorelease];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self selector:@selector(loadDataXml:) name:@"connectionDidFinishNotification"  object:con];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self selector:@selector(isErrorXml:) name:@"didFailWithError"  object:con];
	
	//[con connectionWithPathMethodPost:request];
	[con connectionWithPath:[request stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    //NSLog(@"ERROR:%@", [parseError localizedDescription]);
}


- (void)parserDidStartDocument:(NSXMLParser *)parser {
	// start
	//NSLog(@"parserDidStartDocument");

	resultData = [[NSMutableArray alloc] init];
	kinenbiTitles = [[NSMutableArray alloc] init];
}

- (void)parser:(NSXMLParser *) parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	tempXMLString = [NSMutableString string];
	//NSLog(@"%@", elementName);
	if([elementName isEqualToString:@"dekigoto"]) {
		nowElements = @"出来事";
	}
	else if([elementName isEqualToString:@"tanjyoubi"]) {
		nowElements = @"誕生日";
	}
	else if([elementName isEqualToString:@"imibi"]) {
		nowElements = @"忌(み)日";
	}
	else if([elementName isEqualToString:@"kinenbi"]) {
		nowElements = @"記念日";
	}
	else if([elementName isEqualToString:@"kinenbi_detail"]) {
		nowElements = @"記念日詳細";
	}
	else if([elementName isEqualToString:@"item"]) {
		if ([nowElements isEqualToString:@"記念日"]) {
			return;
		}
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		[resultData addObject:dict];
		[dict release];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	//NSLog(@"%@", tempXMLString);
	[tempXMLString appendString:[[string componentsSeparatedByString:@"\n"] objectAtIndex:0]];
}

- (void)parser:(NSXMLParser *) parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	//NSLog(@"%@, %@, %@", elementName, namespaceURI, qName);
	
	if([elementName isEqualToString:@"title"] && [nowElements isEqualToString:@"記念日詳細"]) {
		//NSLog(@"title: %@", tempXMLString);
		nowKinenbiTitle = tempXMLString;
	}

	if([elementName isEqualToString:@"item"]) {
		NSString *outString;
		if ([nowElements isEqualToString:@"記念日詳細"]) {
			if ([tempXMLString isEqualToString:@""]) {
				outString = [NSString stringWithFormat:@"記念日,%@,%@", nowKinenbiTitle, nowKinenbiTitle];
			}
			else {
				outString = [NSString stringWithFormat:@"記念日,%@,%@", nowKinenbiTitle, tempXMLString];
			}
			
			[(NSMutableDictionary *)[resultData lastObject] setObject:outString forKey:elementName];
			NSLog(@"記念日詳細: %@", outString);
			return;
		}
		
		NSArray *array = [tempXMLString componentsSeparatedByString:@" - "];
		

		int i;
		//NSLog(@"%d", [array count]);
		if ([array count] < 2) {
			//NSLog(tempXMLString);
			array = [tempXMLString componentsSeparatedByString:@"-"];
			if ([array count] < 2) {
				array = [tempXMLString componentsSeparatedByString:@" – "];
				if ([array count] < 2) {
					outString = [NSString stringWithFormat:@"%@,,%@", nowElements, tempXMLString];
				}
				else {
					outString = [NSString stringWithFormat:@"%@,%@,%@", nowElements, [array objectAtIndex:0], [array objectAtIndex:1]];
					if([array count] > 3){
						for (i = 3; i < [array count]; i++) {
							outString = [outString stringByAppendingString:[NSString stringWithFormat:@" – %@", [array objectAtIndex:i]]];							
						}
					}
				}				
			}
			else {
				outString = [NSString stringWithFormat:@"%@,%@,%@", nowElements, [array objectAtIndex:0], [array objectAtIndex:1]];
				if([array count] > 3){
					for (i = 3; i < [array count]; i++) {
						outString = [outString stringByAppendingString:[NSString stringWithFormat:@"-%@", [array objectAtIndex:i]]];
					}
				}
			}
		}
		else {
			outString = [NSString stringWithFormat:@"%@,%@,%@", nowElements, [array objectAtIndex:0], [array objectAtIndex:1]];
			if([array count] > 3){
				for (i = 3; i < [array count]; i++) {
					outString = [outString stringByAppendingString:[NSString stringWithFormat:@" - %@", [array objectAtIndex:i]]];
				}
			}
		}
		//[array release];
		
		//if ([nowElements isEqualToString:@"記念日"] != YES) {
			[(NSMutableDictionary *)[resultData lastObject] setObject:outString forKey:elementName];
		//}
		//else {
		//	[(NSMutableDictionary *)[resultData lastObject] setObject:outString forKey:@"dust"];
		//}

		
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	// end
	//NSLog(@"end readXML");
	[self.delegate WhatDayTodayApiModelDelegateDidFinish:self];
}

-(void) loadDataXml: (NSNotification *) notification{
	myConnection * con = (myConnection*)[notification object];
	
	if(con != nil){
		NSXMLParser *parser = [[NSXMLParser alloc] initWithData:con.m_data] ;
		
		if(parser == nil){
			UIAlertView * base = [[UIAlertView alloc] initWithTitle:@"ネットワークエラー" message:@"アクセスできませんでした" 
														   delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
			
			[base show];
			[base release];
		}else{
			//NSLog(@"result find");
			[parser setDelegate:self];
			[parser parse];
		}
		[parser release];
		
	}else{	
		UIAlertView * base = [[UIAlertView alloc] initWithTitle:@"該当情報はありません" message:@"該当情報はありません" 
													   delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];		
		[base show];
		[base release];
	}
	
	
}

-(void) isErrorXml: (NSNotification *) notification
{
	UIAlertView * base = [[UIAlertView alloc] initWithTitle:@"ネットワークエラー" message:@"アクセスできませんでした" 
												   delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[base show];
	[base release];
}

@end
