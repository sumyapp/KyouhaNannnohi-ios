//
//  SmAddView.m
//  DekaMoji
//
//  Created by sumy on 11/03/21.
//  Copyright 2011 sumyapp. All rights reserved.
//

#import "SmAddView.h"
#import "SmAddGlobal.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>
#import <netinet/in.h>

#define SMADD_AD_LOAD_SUCCESS 1
#define SMADD_AD_LOAD_ERROR 0

@interface SmAddView()
//AdMob
#ifdef SMADD_ADMOB_NAME
- (void)showAdMob;
- (void)removeAdMob;
#endif

//AdMaker
#ifdef SMADD_ADMAKER_NAME
- (void)showAdMaker;
- (void)removeAdMaker;
#endif

//iAd
#ifdef SMADD_IAD_NAME
- (void)showIAd;
- (void)removeIAd;
#endif

//TGAd
#ifdef SMADD_TGAD_NAME
- (void)showTGAd;
- (void)removeTGAd;
#endif

//AdLantis(Beta)
#ifdef SMADD_ADLANTIS_NAME
- (void)showAdlantis;
- (void)removeAdlantis;
- (void)adlantisFailedNotificationRecive:(NSNotificationCenter*)center;
- (void)adlantisSuccessNotificationRecive:(NSNotificationCenter*)center;
#endif

//HouseAd
#ifdef SMADD_HOUSEAD_NAME
- (void)showHouseAd;
- (void)removeHouseAd;
#endif

//AmeAd
#ifdef SMADD_AMEAD_NAME
- (void)showAmeAd;
- (void)removeAmeAd;
#endif

//Common
- (void)tryNextAdLoad;
- (void)getEnableAdNamesSortByPriority;
- (void)getEnableAdNamesSortByPriorityDidEnd:(NSString*)result;
- (void)reciveAdStatus:(NSString*)adName
			  dataType:(int)dataType;
- (NSString*)makeHashBySecretKeyAndUDID;
//AdStatusReport(FeatureService)
- (void)startResponseTimeCountTimer:(NSString*)adName;
- (void)countResponseTime:(NSTimer*)timer;
- (void)stopResponseTimeCountTimer:(NSString*)adName;
- (void)stopResponseTimeCountTimerAll;
- (void)sendAdSuccess:(NSString*)adName;
- (void)sendAdSuccessDidEnd:(NSString*)result;
- (void)sendAdFailed:(NSString*)adName;
- (void)sendAdFailedDidEnd:(NSString*)result;
- (BOOL)checkFirstLaunchToday;
- (NSString*)devicePlatform;
- (BOOL)reachabilityForInternetConnection;
- (NSString*)getKeyForSaveUserDefaults:(NSString*)keyTypeString;
@end

@implementation SmAddView
#ifdef SMADD_ADMAKER_NAME
    @synthesize adMaker;
#endif
#ifdef SMADD_ADMOB_NAME
    @synthesize adMob;
#endif
#ifdef SMADD_IAD_NAME
    @synthesize iAd;
#endif
#ifdef SMADD_TGAD_NAME
    @synthesize tgAd;
#endif
#ifdef SMADD_ADLANTIS_NAME
    @synthesize adlantis;
#endif
#ifdef SMADD_HOUSEAD_NAME
    @synthesize houseAd;
#endif
#ifdef SMADD_AMEAD_NAME
    @synthesize ameAd;
#endif
@synthesize loadingAdPriorityNumber;
@synthesize enableAdNamesSortByPriority;
@synthesize masterViewController;
@synthesize isAdInTop;
@synthesize adError;
@synthesize adLoading;
@synthesize smaddAdServerUrl;
@synthesize smaddAdServerSecretKey;
@synthesize enableAdNameSortByPriority;

/**
 * This is AdViewController core method
 * These method control ad
 */
#pragma mark AdController
- (void)startAd{
	SMADD_LOG_METHOD
    if(adLoading)
        return;
    
	adLoading = YES;
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultAds = [NSDictionary dictionaryWithObject:[enableAdNameSortByPriority componentsSeparatedByString:@","]
                                                           forKey:[self getKeyForSaveUserDefaults:@"SMADD_ENABLE_AD_NAMES_SORT_BY_DEFAULTS"]];
    [defaults registerDefaults:defaultAds];
	
	enableAdNamesSortByPriority = [[defaults objectForKey:[self getKeyForSaveUserDefaults:@"SMADD_ENABLE_AD_NAMES_SORT_BY_DEFAULTS"]] retain];
	SMADD_LOG(@"enableAdNamesSortByPriority = %@", [enableAdNamesSortByPriority description])
	
	// Getting start priority most higher adservice
	loadingAdPriorityNumber = -1;
	[self tryNextAdLoad];
	
    if(!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:1];
    }
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                            selector:@selector(getEnableAdNamesSortByPriority)
                                                                              object:nil];
    [_operationQueue addOperation:operation];
    [operation release];
}

/**
 * Please setting you use ad service remove method
 */
- (void)stopAd{
	SMADD_LOG_METHOD
    // Not edit
    [self stopResponseTimeCountTimerAll];
    [enableAdNamesSortByPriority release], enableAdNamesSortByPriority = nil;
    loadingAdPriorityNumber = -1;
    adLoading = NO;
    
    #ifdef SMADD_IAD_NAME
        [self removeIAd];
    #endif
    #ifdef SMADD_ADMOB_NAME
        [self removeAdMob];
    #endif
    #ifdef SMADD_ADMAKER_NAME
        [self removeAdMaker];
    #endif
    #ifdef SMADD_TGAD_NAME
        [self removeTGAd];
    #endif
    #ifdef SMADD_HOUSEAD_NAME
        [self removeHouseAd];
    #endif
    #ifdef SMADD_ADLANTIS_NAME
        [self removeAdlantis];
    #endif
    #ifdef SMADD_AMEAD_NAME
        [self removeAmeAd];
    #endif
}

/**
 * Please setting you use ad service remove method
 */
- (void)reciveAdStatus:(NSString*)adName
			  dataType:(int)dataType {
	SMADD_LOG(@"-[AdViewController reciveAdStatus:%@ dataType:%d]", adName, dataType)
	// 広告のロード成功。次の広告種の読み込みを開始しない
	[self stopResponseTimeCountTimer:adName];
	if(dataType == SMADD_AD_LOAD_SUCCESS) {
        if(!_operationQueue) {
            _operationQueue = [[NSOperationQueue alloc] init];
            [_operationQueue setMaxConcurrentOperationCount:1];
        }
        NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                selector:@selector(sendAdSuccess:)
                                                                                object:adName];
        [_operationQueue addOperation:operation];
        [operation release];

		[self stopResponseTimeCountTimerAll];
        adLoading = NO;
		return;
	}
    if(!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:1];
    }
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                            selector:@selector(sendAdFailed:)
                                                                              object:adName];
    [_operationQueue addOperation:operation];
    [operation release];
        
#ifdef SMADD_IAD_NAME
	if([SMADD_IAD_NAME isEqualToString:adName]){
		if(dataType == SMADD_AD_LOAD_ERROR){
			[self tryNextAdLoad];
			[self removeIAd];
		}
        return;
	}
#endif
#ifdef SMADD_ADMAKER_NAME
	if([SMADD_ADMAKER_NAME isEqualToString:adName]){
		if(dataType == SMADD_AD_LOAD_ERROR){
			[self tryNextAdLoad];
			[self removeAdMaker];
		}
        return;
	}
#endif
#ifdef SMADD_ADMOB_NAME
	if([SMADD_ADMOB_NAME isEqualToString:adName]){
		if(dataType == SMADD_AD_LOAD_ERROR){
			[self tryNextAdLoad];
			[self removeAdMob];
		}
        return;
	}
#endif
#ifdef SMADD_TGAD_NAME
	 if([SMADD_TGAD_NAME isEqualToString:adName]){
         if(dataType == SMADD_AD_LOAD_ERROR){
             [self tryNextAdLoad];
             [self removeTGAd];
         }
         return;
	 }
#endif
#ifdef SMADD_HOUSEAD_NAME
	if([SMADD_HOUSEAD_NAME isEqualToString:adName]){
		if(dataType == SMADD_AD_LOAD_ERROR){
			[self tryNextAdLoad];
			[self removeHouseAd];
		}
        return;
	}
#endif
#ifdef SMADD_ADLANTIS_NAME
	if([SMADD_ADLANTIS_NAME isEqualToString:adName]){
		if(dataType == SMADD_AD_LOAD_ERROR){
			[self tryNextAdLoad];
			[self removeAdlantis];
		}
        return;
	}
#endif
#ifdef SMADD_AMEAD_NAME
	if([SMADD_AMEAD_NAME isEqualToString:adName]){
		if(dataType == SMADD_AD_LOAD_ERROR){
			[self tryNextAdLoad];
			[self removeAmeAd];
		}
        return;
	}
#endif
    SMADD_LOG(@"reciveAdStatus: EXCEPTION_ERROR")
}

// 次の広告を読み込みに行く
- (void)tryNextAdLoad{
	loadingAdPriorityNumber++;
	SMADD_LOG(@"-[AdViewController tryNextAdLoad], loadingAdPriorityNumber = %d, [enableAdNamesSortByPriority count] = %d", loadingAdPriorityNumber, [enableAdNamesSortByPriority count])
	if([enableAdNamesSortByPriority count] <= loadingAdPriorityNumber) {
		SMADD_LOG(@"AdService is all failed")
        if(retryCount < SMADD_RETRY_COUNT_MAX) {
            SMADD_LOG(@"But, retry")
            retryCount++;
            loadingAdPriorityNumber = -1;
            [self tryNextAdLoad];
        }
        else {
            SMADD_LOG(@"adError = YES")
            adError = YES;
            adLoading = NO;
            return;
        }
	}
    
    /**
     * If not online, use support offline adservice(Cache In File etc...)
     * Currently, only support adlantis
     */
    BOOL networkConecctionAvailabble = [self reachabilityForInternetConnection];
    SMADD_LOG(@"NetworkConennctionAvailabble: %d", networkConecctionAvailabble)
    if(!networkConecctionAvailabble) {
        SMADD_LOG(@"NetworkConennctionIsNotAvailabble")
        #ifdef SMADD_ADLANTIS_NAME
        if([SMADD_ADLANTIS_NAME isEqualToString:[enableAdNamesSortByPriority objectAtIndex:loadingAdPriorityNumber]]){
            [self startResponseTimeCountTimer:SMADD_ADLANTIS_NAME];
            [self showAdlantis];
        }
        #endif
        return;
    }
	
#ifdef SMADD_IAD_NAME
	if([SMADD_IAD_NAME isEqualToString:[enableAdNamesSortByPriority objectAtIndex:loadingAdPriorityNumber]]) {
        Class clazz = NSClassFromString(@"ADBannerView");
        if (clazz) {
            [self startResponseTimeCountTimer:SMADD_IAD_NAME];
            [self showIAd];
        }
        else {
            SMADD_LOG(@"tryNextAdLoad: iAd Not support this device")
            [self tryNextAdLoad];
        }
        return;
	}
#endif
#ifdef SMADD_ADMAKER_NAME
	if([SMADD_ADMAKER_NAME isEqualToString:[enableAdNamesSortByPriority objectAtIndex:loadingAdPriorityNumber]]) {
		[self startResponseTimeCountTimer:SMADD_ADMAKER_NAME];
        [self showAdMaker];
        return;
	}
#endif
#ifdef SMADD_ADMOB_NAME
	if([SMADD_ADMOB_NAME isEqualToString:[enableAdNamesSortByPriority objectAtIndex:loadingAdPriorityNumber]]) {
		[self startResponseTimeCountTimer:SMADD_ADMOB_NAME];
        [self showAdMob];
        return;
	}
#endif
#ifdef SMADD_TGAD_NAME
	 if([SMADD_TGAD_NAME isEqualToString:[enableAdNamesSortByPriority objectAtIndex:loadingAdPriorityNumber]]){
         [self showTGAd];
         return;
	 }
#endif
#ifdef SMADD_HOUSEAD_NAME
	if([SMADD_HOUSEAD_NAME isEqualToString:[enableAdNamesSortByPriority objectAtIndex:loadingAdPriorityNumber]]){
		[self startResponseTimeCountTimer:SMADD_HOUSEAD_NAME];
        [self showHouseAd];
        return;
	}
#endif
#ifdef SMADD_ADLANTIS_NAME
	if([SMADD_ADLANTIS_NAME isEqualToString:[enableAdNamesSortByPriority objectAtIndex:loadingAdPriorityNumber]]){
		[self startResponseTimeCountTimer:SMADD_ADLANTIS_NAME];
		[self showAdlantis];
        return;
	}
#endif
#ifdef SMADD_AMEAD_NAME
	if([SMADD_AMEAD_NAME isEqualToString:[enableAdNamesSortByPriority objectAtIndex:loadingAdPriorityNumber]]){
		[self startResponseTimeCountTimer:SMADD_AMEAD_NAME];
        [self showAmeAd];
        return;
	}
#endif
	SMADD_LOG(@"tryNextAdLoad: EXCEPTION_ERROR")
	[self tryNextAdLoad];
}


/**
 * This is AdMobDelagate section
 */
#pragma mark AdMobDelegate
#ifdef SMADD_ADMOB_NAME
- (void)adViewDidReceiveAd:(GADBannerView *)bannerView {
    SMADD_LOG_METHOD
    [self reciveAdStatus:SMADD_ADMOB_NAME
                dataType:SMADD_AD_LOAD_SUCCESS];
}
- (void)adView:(GADBannerView *)bannerView
didFailToReceiveAdWithError:(GADRequestError *)error {
    SMADD_LOG_METHOD
    SMADD_LOG(@"adView:didFailToReceiveAdWithError:%@", [error localizedDescription])
    [self reciveAdStatus:SMADD_ADMOB_NAME
                dataType:SMADD_AD_LOAD_ERROR];
}

- (void)adViewWillPresentScreen:(GADBannerView *)bannerView {
    SMADD_LOG_METHOD
}

- (void)adViewDidDismissScreen:(GADBannerView *)bannerView {
    SMADD_LOG_METHOD
}

- (void)adViewWillLeaveApplication:(GADBannerView *)bannerView {
    SMADD_LOG_METHOD
}
#endif


/**
 * This is iAdDelegate section
 */
#pragma mark iAdDelegate
#ifdef SMADD_IAD_NAME
- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
	SMADD_LOG_METHOD
	return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
	SMADD_LOG_METHOD
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
	SMADD_LOG_METHOD
	[UIView beginAnimations:@"animateAdBannerOn" context:NULL];
	[banner setAlpha:1.0];
	[UIView commitAnimations];
	
	[self reciveAdStatus:SMADD_IAD_NAME
				dataType:SMADD_AD_LOAD_SUCCESS];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	SMADD_LOG_METHOD
	SMADD_LOG(@"%@", [error description])

	[UIView beginAnimations:@"animateAdBannerOff" context:NULL];
	[banner setAlpha:0.0];
	[UIView commitAnimations];
	
	[self reciveAdStatus:SMADD_IAD_NAME
				dataType:SMADD_AD_LOAD_ERROR];
}
#endif


/**
 * This is HouseAdDelagate section
 */
#pragma mark HouseAdDelagate
#ifdef SMADD_HOUSEAD_NAME
- (void)adViewTemplate:(AdViewTemplate *)adView didFailToReceiveAdWithError:(NSError *)error{
	SMADD_LOG_METHOD
	[self reciveAdStatus:SMADD_HOUSEAD_NAME
				dataType:SMADD_AD_LOAD_ERROR];
}

- (void)adViewTemplateDidLoadAd:(AdViewTemplate *)adView{
	SMADD_LOG_METHOD
	[self reciveAdStatus:SMADD_HOUSEAD_NAME
				dataType:SMADD_AD_LOAD_SUCCESS];
}
#endif


/**
 * This is relate AdMob method section
 */
#pragma mark AdMob
#ifdef SMADD_ADMOB_PUBLISER_ID
- (void)showAdMob {
	SMADD_LOG_METHOD
    if(adMob == nil) {
        adMob = [[GADBannerView alloc]
                 initWithFrame:CGRectMake(0,0,GAD_SIZE_320x50.width,GAD_SIZE_320x50.height)];
        
        // Specify the ad's "unit identifier." This is your AdMob Publisher ID.
        adMob.adUnitID = SMADD_ADMOB_PUBLISER_ID;
        
        // Let the runtime know which UIViewController to restore after taking
        // the user wherever the ad goes and add it to the view hierarchy.
        adMob.rootViewController = masterViewController;
        [adMob setDelegate:self];
        [self addSubview:adMob];
        
        // Initiate a generic request to load it with an ad.
        [adMob loadRequest:[GADRequest request]];
    }
    else {
        [adMob removeFromSuperview];
        [self addSubview:adMob];
        [adMob loadRequest:[GADRequest request]];
        SMADD_LOG(@"showAdMob: EXCEPTION_ERROR")
    }
}

- (void)removeAdMob {
	SMADD_LOG_METHOD
    [adMob removeFromSuperview];
    adMob.delegate = nil;
    [adMob release];
    adMob = nil;
}
#endif


/**
 * This is relate AdMaker method section
 */
#pragma mark AdMaker
#ifdef SMADD_ADMAKER_NAME
- (void)showAdMaker {
	SMADD_LOG_METHOD
	if(adMaker == nil) {
        SMADD_LOG(@"AdMaker alloc init")
		adMaker = [[AdMakerView alloc] init];
        [adMaker adMakerDelegate:self];
        [adMaker start];
	}
	else {
		SMADD_LOG(@"showAdMaker: EXCEPTION_ERROR")
	}    
}

- (void)removeAdMaker {
	SMADD_LOG_METHOD
    [adMaker adMakerDelegate:nil];
    [adMaker setDelegate:nil];
	[adMaker.view removeFromSuperview];
	[adMaker release];
	adMaker = nil;
}

//AdMakerDelegate
-(UIViewController*)currentViewControllerForAd {
    return masterViewController;
}

-(NSArray*)adKey {
    return [NSArray arrayWithObjects:SMADD_ADMAKER_AD_URL, SMADD_ADMAKER_SITE_ID, SMADD_ADMAKER_ZONE_ID, nil];
}

- (void)requestAdSuccess {
    SMADD_LOG_METHOD
    [adMaker setFrame:CGRectMake(0, 0, 320, 50)];
    [self addSubview:adMaker.view];
    [self reciveAdStatus:SMADD_ADMAKER_NAME
                dataType:SMADD_AD_LOAD_SUCCESS];
}

//広告の取得に失敗
-(void)requestAdFail {
    SMADD_LOG_METHOD
    [self reciveAdStatus:SMADD_ADMAKER_NAME
                dataType:SMADD_AD_LOAD_ERROR];
}
#endif


/**
 * This is relate iAd method section
 */
#pragma mark iAd
#ifdef SMADD_IAD_NAME
- (void)showIAd{
	SMADD_LOG_METHOD
	if(iAd == nil) {
		iAd = [[ADBannerView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
	}
	else {
		SMADD_LOG(@"showIAd: EXCEPTION_ERROR")
	}
	[iAd setAlpha:0.0];
	// iAdの広告サイズを指定
    if (&ADBannerContentSizeIdentifierPortrait != nil) {
        [iAd setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        // [iAd setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
    } else {
       [iAd setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifier320x50];
        //[iAd setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifier480x32];
    }
	[iAd setDelegate:self];
	[self addSubview:iAd];	
}

- (void)removeIAd{
	SMADD_LOG_METHOD
    [iAd removeFromSuperview];
    [iAd setDelegate:nil];
    [iAd release];
    iAd = nil;
}
#endif


/**
 * This is relate HouseAd method section
 */
#pragma mark HouseAd
#ifdef SMADD_HOUSEAD_NAME
- (void)showHouseAd{
	SMADD_LOG_METHOD
	if(houseAd == nil) {
		houseAd = [[AdViewTemplate alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
	}
	else {
		SMADD_LOG(@"showHouseAd: EXCEPTION_ERROR")
	}
	[houseAd setDelegate:self];
	[houseAd setUrl:SMADD_HOUSEAD_URL];
	[houseAd setBannerLinkUrlHost:SMADD_HOUSEAD_LINK_HOSTNAME];
	[houseAd setBackgroundColor:[UIColor clearColor]]; //広告の背景を透明に
	[houseAd setController:masterViewController];
	[houseAd setOpaque:NO];
	[houseAd start];
	[self addSubview:houseAd];
}

- (void)removeHouseAd{
	SMADD_LOG_METHOD
	[houseAd removeFromSuperview];
	[houseAd release];
	houseAd = nil;
}
#endif

#pragma mark TGAD
#ifdef SMADD_TGAD_NAME
//TGAd for iPhone
- (void)showTGAd {
	if(tgAd == nil) {
		tgAd = [TGAView requestWithKey:SMADD_TGAD_KEY Position:0.0];
	}
	[self addSubview:tgAd];
}
 
- (void)removeTGAd {
	[tgAd removeFromSuperview];
	[tgAd release];
	tgAd = nil;
}
#endif


/*
 * this faunction is beta version, please carefully to use this
 */
#pragma mark AdLantis
#ifdef SMADD_ADLANTIS_NAME
- (void)showAdlantis {	
	if(adlantis == nil) {        
        if(adlantisAlreadyAlloc) {
            [self reciveAdStatus:SMADD_ADLANTIS_NAME dataType:YES];
        }
        else {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc addObserver:self selector:@selector(adlantisSuccessNotificationRecive:) name:@"AdlantisAdsUpdatedNotification" object:nil];
            //[nc addObserver:self selector:@selector(adlantisFailedNotificationRecive:) name:@"ADSessionDidCloseNotification" object:nil];
            //[nc addObserver:self selector:@selector(checkAdlantisLoaded:) name:@"AdlantisAdManagerAssetUpdatedNotification" object:nil];
            //[nc addObserver:self selector:@selector(checkAdlantisLoaded:) name:@"AdlantisPreviewWillBeShownNotification" object:nil];
            //[nc addObserver:self selector:@selector(checkAdlantisLoaded:) name:@"AdlantisPreviewWillBeHiddenNotification" object:nil];
            adlantisAlreadyAlloc = YES;
        }
        
        AdlantisAdManager.sharedManager.publisherID = SMADD_ADLANTIS_PUBLISHER_ID;
		adlantis = [[AdlantisView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
	}
    
	[self addSubview:adlantis];
}

- (void)removeAdlantis {
    [[AdlantisAdManager sharedManager] clearMemoryCache];
	[adlantis removeFromSuperview];
	[adlantis release];
	adlantis = nil;
}

- (void)adlantisSuccessNotificationRecive:(NSNotificationCenter*)center {
	SMADD_LOG_METHOD
	[self reciveAdStatus:SMADD_ADLANTIS_NAME dataType:YES];
}
// Current, not use this. Use timeout counter
- (void)adlantisFailedNotificationRecive:(NSNotificationCenter*)center {
	SMADD_LOG_METHOD
	[self reciveAdStatus:SMADD_ADLANTIS_NAME dataType:NO];
}
#endif

/*
 * this faunction is beta version, please carefully to use this
 */
#pragma mark AmeAd
#ifdef SMADD_AMEAD_NAME
- (void)showAmeAd {
    SMADD_LOG_METHOD
    if(ameAd == nil) {
        ameAd = [[SmAddAmeAdView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
        ameAd.currentContentSizeIdentifier = AdCloudContentSizeIdentifierPortrait;
        ameAd.sid = @"f2cf420f86ef20915bd5d20e89c94cc6c2bea1ba41e947384dac58a9602ff566";
        ameAd.ameAdDelegate = self;
        [self addSubview:ameAd];
    }
    
    [ameAd setHidden:YES];
}

- (void)removeAmeAd {
    SMADD_LOG_METHOD
    ameAd.ameAdDelegate = nil;
    [ameAd removeFromSuperview];
	[ameAd release];
	ameAd = nil;
}

- (void)ameAdBannerView:(AdCloudView *)banner didFailToReceiveAdWithError:(NSError *)error {
    SMADD_LOG_METHOD
    [self reciveAdStatus:SMADD_AMEAD_NAME
                dataType:SMADD_AD_LOAD_ERROR];
}

- (void)ameAdBannerViewDidLoadAd:(AdCloudView *)banner {
    SMADD_LOG_METHOD
    [ameAd setHidden:NO];
    
    [self reciveAdStatus:SMADD_AMEAD_NAME
                dataType:SMADD_AD_LOAD_SUCCESS];
}
#endif

#pragma mark CommonMethod, No need to edit

- (void)getEnableAdNamesSortByPriority {
	SMADD_LOG_METHOD
	
	NSString *urlString = [[[NSString alloc] initWithFormat:@"%@?hash=%@&udid=%@&locale=%@&language=%@&modelType=%@&osVersion=%@&appVersion=%@&firstLaunchToday=%d",
							smaddAdServerUrl, [self makeHashBySecretKeyAndUDID], [UIDevice currentDevice].uniqueIdentifier, [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode], [[NSLocale preferredLanguages] objectAtIndex:0], [self devicePlatform], [UIDevice currentDevice].systemVersion, [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], [self checkFirstLaunchToday]] autorelease];
	urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	//NSString *urlString = AD_SERVER_URL;
	SMADD_LOG(@"%@", urlString)
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	NSURLResponse *resp;
	NSError *err = nil;
	NSData *resultData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
	
	if (err) {
		SMADD_LOG(@"ERROR")
		return;
	}
	
	NSString *resultString = [[[NSString alloc] initWithData:resultData encoding:NSASCIIStringEncoding] autorelease];
	
	[self performSelectorOnMainThread:@selector(getEnableAdNamesSortByPriorityDidEnd:)
						   withObject:resultString
						waitUntilDone:YES];	
}

- (void)getEnableAdNamesSortByPriorityDidEnd:(NSString*)result{
	SMADD_LOG_METHOD
	SMADD_LOG(@"result = %@", result)
	if(result != nil && ![result isEqualToString:@""]) {
		NSArray *array = [result componentsSeparatedByString:@","];
		if([array count] > 0){
            //check for a minimum of one available adname
            BOOL available = NO;
            for (NSString* nadname in array) {
                if(available) {
                    break;
                }    
                for(NSString* oadname in enableAdNamesSortByPriority) {
                    if([oadname isEqualToString:nadname]) {
                        available = YES;
                        break;
                    }
                }
            }
            
            if(available) {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:array forKey:[self getKeyForSaveUserDefaults:@"SMADD_ENABLE_AD_NAMES_SORT_BY_DEFAULTS"]];
                [defaults synchronize];
                SMADD_LOG(@"save: %@", [array description])
            }
            else {
                SMADD_LOG(@"Not save, because available ad service name is not found")
            }
		}
        else {
            SMADD_LOG(@"Not save, because available ad service name is not found")
        }
	}	
}

//AdStatusReport(FeatureService)
- (void)sendAdSuccess:(NSString*)adName {
	SMADD_LOG_METHOD	
	if([_responseTimeDic objectForKey:adName] == nil) {
		SMADD_LOG(@"sendAdFailed: EXCEPTION_ERROR")
		[self performSelectorOnMainThread:@selector(sendAdSuccessDidEnd:)
							   withObject:@"sendAdSuccess: EXCEPTION_ERROR"
							waitUntilDone:YES];
		return;
	}
	
	NSString *urlString = [[[NSString alloc] initWithFormat:@"%@/success?hash=%@&udid=%@&locale=%@&adName=%@&responseTime=%f",
							smaddAdServerUrl, [self makeHashBySecretKeyAndUDID], [UIDevice currentDevice].uniqueIdentifier, [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode], adName, [[_responseTimeDic objectForKey:adName] floatValue]] autorelease];
	urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	SMADD_LOG(@"%@", urlString)
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	NSURLResponse *resp;
	NSError *err = nil;
	NSData *resultData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
	
	if (err) {
		SMADD_LOG(@"ERROR")
		return;
	}

	NSString *resultString = [[[NSString alloc] initWithData:resultData encoding:NSASCIIStringEncoding] autorelease];
	
	[self performSelectorOnMainThread:@selector(sendAdSuccessDidEnd:)
						   withObject:resultString
						waitUntilDone:YES];
}

- (void)sendAdSuccessDidEnd:(NSString*)result {
	SMADD_LOG_METHOD
	SMADD_LOG(@"result = %@", result)
}

- (void)sendAdFailed:(NSString*)adName {
	SMADD_LOG_METHOD
	if([_responseTimeDic objectForKey:adName] == nil) {
		SMADD_LOG(@"sendAdFailed: EXCEPTION_ERROR")
		[self performSelectorOnMainThread:@selector(sendAdFailedDidEnd:)
							   withObject:@"sendAdFailed: EXCEPTION_ERROR"
							waitUntilDone:YES];
        return;
	}
	
	NSString *urlString = [[[NSString alloc] initWithFormat:@"%@/failed?hash=%@&udid=%@&locale=%@&adName=%@&responseTime=%f",
							smaddAdServerUrl, [self makeHashBySecretKeyAndUDID], [UIDevice currentDevice].uniqueIdentifier, [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode], adName, [[_responseTimeDic objectForKey:adName] floatValue]]autorelease];
	urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	SMADD_LOG(@"%@", urlString)
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	NSURLResponse *resp;
	NSError *err = nil;
	NSData *resultData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];

	if (err) {
		SMADD_LOG(@"ERROR")
		return;
	}

	NSString *resultString = [[[NSString alloc] initWithData:resultData encoding:NSASCIIStringEncoding] autorelease];
	
	[self performSelectorOnMainThread:@selector(sendAdFailedDidEnd:)
						   withObject:resultString
						waitUntilDone:YES];
}

- (void)sendAdFailedDidEnd:(NSString*)result {
	SMADD_LOG_METHOD
	SMADD_LOG(@"result = %@", result)
}

- (void)startResponseTimeCountTimer:(NSString*)adName {
	SMADD_LOG_METHOD
	if(_responseTimeCountTimerDic == nil) {
		_responseTimeCountTimerDic = [[NSMutableDictionary alloc] initWithCapacity:[enableAdNamesSortByPriority count]];
	}
	
	if(_responseTimeDic == nil) {
		_responseTimeDic = [[NSMutableDictionary alloc] initWithCapacity:[enableAdNamesSortByPriority count]];
	}
	[_responseTimeDic setObject:[NSNumber numberWithFloat:0] forKey:adName];
	

	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.25f
												   target:self
												 selector:@selector(countResponseTime:)
												 userInfo:adName
												  repeats:YES];
	[_responseTimeCountTimerDic setObject:timer forKey:adName];
}

- (void)countResponseTime:(NSTimer*)timer {
	SMADD_LOG(@"-[SmAddView countResponseTime:%@]", [timer userInfo])
	
	if(_responseTimeCountTimerDic == nil || _responseTimeDic == nil) {
		SMADD_LOG(@"countResponseTime: EXCEPTION_ERROR")
		return;
	}	
	
	NSString *adName = [timer userInfo];
	NSNumber *responseTime = [_responseTimeDic objectForKey:adName];
	if(responseTime == nil) {
		SMADD_LOG(@"countResponseTime: EXCEPTION_ERROR")
		responseTime = [NSNumber numberWithFloat:0.25];
	}
	else {
		responseTime = [NSNumber numberWithFloat:[responseTime floatValue] + 0.25];
	}
	[_responseTimeDic setObject:responseTime forKey:adName];
    
    // adservice is timeout
    if([responseTime intValue] >= SMADD_TIMEOUT_TIME) {
        [self reciveAdStatus:adName dataType:SMADD_AD_LOAD_ERROR];
    }
}

- (void)stopResponseTimeCountTimer:(NSString*)adName {
	SMADD_LOG_METHOD
	if(_responseTimeCountTimerDic == nil) {
		SMADD_LOG(@"stopResponseTimeCountTimer: EXCEPTION_ERROR")
		return;
	}
	
	NSTimer *timer = [_responseTimeCountTimerDic objectForKey:adName];
	if(timer != nil) {
		[timer invalidate];
		[_responseTimeCountTimerDic removeObjectForKey:adName];
	}
}

- (void)stopResponseTimeCountTimerAll {
	SMADD_LOG_METHOD
	if(_responseTimeCountTimerDic == nil) {
		SMADD_LOG(@"stopResponseTimeCountTimerAll: EXCEPTION_ERROR")
		return;
	}
	
	for (NSTimer *timer in [_responseTimeCountTimerDic allValues]) {
		[timer invalidate];
	}
	[_responseTimeCountTimerDic removeAllObjects];
    [_responseTimeCountTimerDic release], _responseTimeCountTimerDic = nil;
}

- (NSString*)makeHashBySecretKeyAndUDID {
    SMADD_LOG_METHOD
    SMADD_LOG(@"smaddAdServerSecretKey = %@", smaddAdServerSecretKey)
	NSString *udid = [UIDevice currentDevice].uniqueIdentifier;
	NSString *string = [[NSString alloc] initWithFormat:@"%@:%@", udid, smaddAdServerSecretKey];
	const char *cStr = [string UTF8String];
    unsigned char result[16];
	
	[string release];
	
    CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
	NSString *md5 = [[[NSString alloc] initWithFormat:
					  @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
					  result[0], result[1], result[2], result[3], 
					  result[4], result[5], result[6], result[7],
					  result[8], result[9], result[10], result[11],
					  result[12], result[13], result[14], result[15]] autorelease];
	return md5;
}

// this sdk and server are use GMT
- (BOOL)checkFirstLaunchToday {
    SMADD_LOG_METHOD
    BOOL firstLaunchToday = YES;
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString *beforLaunchDay = [defaults objectForKey:[self getKeyForSaveUserDefaults:@"SMADD_BEFOR_LAUNCH_DAY"]];
    
    NSDate *todayDate = [NSDate date];
    NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"YYYY-MM-dd"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSString *today = [formatter stringFromDate:todayDate];
    SMADD_LOG(@"today = %@", today)
    if([today isEqualToString:beforLaunchDay]){
        firstLaunchToday = NO;
    }
    else {
        [defaults setObject:today forKey:[self getKeyForSaveUserDefaults:@"SMADD_BEFOR_LAUNCH_DAY"]];
    }
    
    return firstLaunchToday;
}

- (NSString*)devicePlatform{
    SMADD_LOG_METHOD
    struct utsname u;
    uname(&u);
    return [NSString stringWithFormat:@"%s", u.machine];
}

- (NSString*)getKeyForSaveUserDefaults:(NSString*)keyTypeString {
    return [NSString stringWithFormat:@"%@:%@", smaddAdServerUrl, keyTypeString];
}


- (id)initWithFrame:(CGRect)frame {
    SMADD_LOG_METHOD
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
		[self setBackgroundColor:[UIColor clearColor]];
		[self setOpaque:NO];
    }
    return self;	
}

- (id)initWithFrame:(CGRect)frame
masterViewController:(UIViewController*)controller
            isAdInTop:(BOOL)adInTop
     smaddAdServerUrl:(NSString*)serverUrlString
smaddAdServerSecretKey:(NSString*)secretKey
enableAdNameSortByPriority:(NSString*)adNames {
    self = [self initWithFrame:frame];
    if (self) {
        // Initialization code.
		[self setBackgroundColor:[UIColor clearColor]];
		[self setOpaque:NO];
        [self setSmaddAdServerUrl:serverUrlString];
        [self setSmaddAdServerSecretKey:secretKey];
        [self setEnableAdNameSortByPriority:adNames];
        [self setIsAdInTop:adInTop];
    }
    return self;
}

- (BOOL)reachabilityForInternetConnection {
    // Part 1 - Create Internet socket addr of zero
	struct sockaddr_in zeroAddr;
	bzero(&zeroAddr, sizeof(zeroAddr));
	zeroAddr.sin_len = sizeof(zeroAddr);
	zeroAddr.sin_family = AF_INET;
    
	// Part 2- Create target in format need by SCNetwork
	SCNetworkReachabilityRef target = 
    SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &zeroAddr);
    
	// Part 3 - Get the flags
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(target, &flags);
    
	// Part 4 - Create output
	BOOL sNetworkReachable;
	if (flags & kSCNetworkFlagsReachable) {
		sNetworkReachable = YES;
    } else {
		sNetworkReachable = NO;
    }
    
    CFRelease(target);
//    
//	BOOL sCellNetwork;
//	if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
//		sCellNetwork = YES;
//    } else {
//		sCellNetwork = NO;
//    }
    
    return sNetworkReachable;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
    SMADD_LOG_METHOD    

    #ifdef SMADD_ADMAKER_NAME
        [adMaker release], adMaker = nil;
    #endif
    #ifdef SMADD_ADMOB_NAME
        adMob.delegate = nil;
        [adMob release], adMob = nil;
    #endif
    #ifdef SMADD_IAD_NAME
        iAd.delegate = nil;
        [iAd release], iAd = nil;
    #endif
    #ifdef SMADD_TGAD_NAME
        [tgAd release], tgAd = nil;
    #endif
    #ifdef SMADD_HOUSEAD_NAME
        [houseAd release], houseAd = nil;
    #endif
    #ifdef SMADD_ADLANTIS_NAME
        [adlantis release], adlantis = nil;
    #endif
    #ifdef SMADD_AMEAD_NAME
        ameAd.ameAdDelegate = nil;
        [ameAd release], ameAd = nil;
    #endif
    
    //Not edit
    [_responseTimeCountTimerDic release], _responseTimeCountTimerDic = nil;
    [_responseTimeDic release], _responseTimeDic = nil;
    [_operationQueue cancelAllOperations], [_operationQueue release], _operationQueue = nil;
    [enableAdNamesSortByPriority release], enableAdNamesSortByPriority = nil;
    [smaddAdServerUrl release];
    [smaddAdServerSecretKey release];
    [enableAdNameSortByPriority release];
    
    [super dealloc];
    SMADD_LOG(@"-[SmAddView dealloc] : [super dealloc]")
}


@end
