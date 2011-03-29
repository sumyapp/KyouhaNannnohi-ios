//
//  myConnection.m
//  navTest2
//DataList
//  Created by motohiro on 09/04/29.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myConnection.h"


@implementation myConnection

@synthesize m_data;

-(void)connectionWithPathMethodPost: (NSString *) path
{
	//NSLog(@"connectionWithPathMethodPost");
	NSArray *arr = [path componentsSeparatedByString:@"?"];
	NSURL* url = [NSURL URLWithString:[arr objectAtIndex:0]];
	NSString* content = [arr objectAtIndex:1];
	
	NSMutableURLRequest* request = [[[NSMutableURLRequest alloc]initWithURL:url] autorelease];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[content dataUsingEncoding:NSUTF8StringEncoding]];

	[NSURLConnection connectionWithRequest:request delegate:self];
}

-(void) connectionWithPath: (NSString *) path
{
	//NSLog(@"in connectionWith");
	NSURLRequest *request;
	request = [NSURLRequest requestWithURL:[NSURL URLWithString:path]];
	[NSURLConnection connectionWithRequest:request delegate:self];
}

-(void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse*)response
{
	//NSLog(@"in responce");
	m_data = [[NSMutableData alloc] init];
	[m_data retain];
}

-(void) connection:(NSURLConnection*) connection didReceiveData:(NSData*)partialData
{
	//NSLog(@"in data");
	[m_data appendData: partialData];
}

-(void) connectionDidFinishLoading:(NSURLConnection*) connection
{
	//NSLog(@"in Finish");
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:@"connectionDidFinishNotification" object: self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	UIAlertView * base = [[[UIAlertView alloc] initWithTitle:@"ネットワークエラー" message:@"アクセスできませんでした" 
						  													   delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
								
	[base show];
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:@"didFailWithError" object: self];
    [m_data release];
    m_data = nil;
}
@end
