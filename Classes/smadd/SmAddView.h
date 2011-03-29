//
//  SmAddView.h
//
//  Created by sumy on 11/03/21.
//  Copyright 2011 sumyapp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>

/*
 This SmAdd SDK is support these sdk
  - AdMaker : AdMakerSDK3.1.1 2011-03-02
  - AdMob : GoogleAdMobAdsSdkiOS-4.0.2
  - iAd : iOS4.3
  - AdLantis(Beta, currently not support) : AdLantis iPhone SDK version v1.2.1
  - TGAD(Beta, currently not support) :  Don't know
 */

//TODO: remove not use adservice's import
/*
 iAdFrameWork link type is "weak", not use "required",
 if you choise "required" or default settings, this app clash in under iOS 4.0
 */
#import <iAd/iAd.h> //iad

#import "AdMakerView.h" //admaker
#import "AdMakerDelegate.h" //admaker

#import "GADBannerView.h" //admob
#import "GADBannerViewDelegate.h" //admob

//#import "TGAView.h" //tgad

#import "AdViewTemplate.h" //housead

/*
 If you use AdLantis, you can specify the linker flag 
 -all_load -weak_library /usr/lib/libSystem.B.dylib
 in your Xcode build settings.
 */
//#import "AdlantisView.h" //adlantis
//#import "AdlantisAdManager.h" //adlantis

//#import "SmAddAmeAdView.h" //amead


//TODO: remove not use adservice's define
//common
#define SMADD_TIMEOUT_TIME 10
#define SMADD_RETRY_COUNT_MAX 2
//admob
#define SMADD_ADMOB_NAME @"admob"
#define SMADD_ADMOB_PUBLISER_ID @"a14b588f78270d7"
////admaker
#define SMADD_ADMAKER_NAME @"admaker"
#define SMADD_ADMAKER_AD_URL @"http://images.ad-maker.info/apps/nannohi.html"
#define SMADD_ADMAKER_SITE_ID @"53"
#define SMADD_ADMAKER_ZONE_ID @"54"
//houseAd
#define SMADD_HOUSEAD_NAME @"housead"
#define SMADD_HOUSEAD_URL @"http://public.sumyapp.com/sumyapp_banner.html"
#define SMADD_HOUSEAD_LINK_HOSTNAME @"public.sumyapp.com"
//iAd
#define SMADD_IAD_NAME @"iad"
//TGAD
//#define SMADD_TGAD_NAME @"tgad"
//#define SMADD_TGAD_KEY @""
//AdLantis
//#define SMADD_ADLANTIS_NAME @"adlantis"
//#define SMADD_ADLANTIS_PUBLISHER_ID @""
//AmeAd
//#define SMADD_AMEAD_NAME @"amead"
//#define SMADD_AMEAD_SID @""

//TODO: remove not use adservice's delegate
@interface SmAddView : UIView<UIWebViewDelegate, ADBannerViewDelegate, AdViewTemplateDelegate, GADBannerViewDelegate, AdMakerDelegate> {
	//AdMaker
    #ifdef SMADD_ADMAKER_NAME
        AdMakerView *adMaker;
    #endif
    
	//AdMob
    #ifdef SMADD_ADMOB_NAME
        GADBannerView *adMob;
    #endif
    
	//iAd
    #ifdef SMADD_IAD_NAME
        ADBannerView *iAd;
    #endif
    
	//HouseAd
    #ifdef SMADD_HOUSEAD_NAME
        AdViewTemplate *houseAd;
    #endif
    
	//TGAd
    #ifdef SMADD_TGAD_NAME
        TGAView *tgAd;
    #endif
    
	//adlantis
    #ifdef SMADD_ADLANTIS_NAME
        AdlantisView *adlantis;
        BOOL adlantisAlreadyAlloc;
    #endif
    
    //ameAd
    #ifdef SMADD_AMEAD_NAME
        SmAddAmeAdView *ameAd;
    #endif
    
	//Common
    int retryCount;
	int loadingAdPriorityNumber;
	NSArray *enableAdNamesSortByPriority;
	UIViewController *masterViewController;
	BOOL isAdInTop;
	BOOL adError;
    BOOL adLoading;
	NSOperationQueue *_operationQueue;
    NSString *smaddAdServerUrl;
    NSString *smaddAdServerSecretKey;
    NSString *enableAdNameSortByPriority;
    
	//Feature service
	NSMutableDictionary *_responseTimeCountTimerDic;
	NSMutableDictionary *_responseTimeDic;
}
- (id)initWithFrame:(CGRect)frame
masterViewController:(UIViewController*)controller
            isAdInTop:(BOOL)adInTop
     smaddAdServerUrl:(NSString*)serverUrlString
    smaddAdServerSecretKey:(NSString*)secretKey
enableAdNameSortByPriority:(NSString*)adNames;

- (void)startAd;
- (void)stopAd;
#ifdef SMADD_ADMAKER_NAME
    @property (retain, readonly) AdMakerView *adMaker;
#endif
#ifdef SMADD_ADMOB_NAME
    @property (retain, readonly) GADBannerView *adMob;
#endif
#ifdef SMADD_IAD_NAME
    @property (retain, readonly) ADBannerView *iAd;
#endif
#ifdef SMADD_HOUSEAD_NAME
    @property (retain, readonly) AdViewTemplate *houseAd;
#endif
#ifdef SMADD_TGAD_NAME
    @property (retain, readonly) TGAView *tgAd;
#endif
#ifdef SMADD_ADLANTIS_NAME
    @property (retain, readonly) AdlantisView *adlantis;
#endif
#ifdef SMADD_AMEAD_NAME
    @property (retain, readonly) SmAddAmeAdView *ameAd;
#endif
@property (readonly) int loadingAdPriorityNumber;
@property (retain, readonly) NSArray *enableAdNamesSortByPriority;
@property (nonatomic, assign) UIViewController *masterViewController;
@property (readwrite) BOOL isAdInTop;
@property (readonly) BOOL adError;
@property (readonly) BOOL adLoading;
@property (retain, readwrite) NSString *smaddAdServerUrl;
@property (retain, readwrite) NSString *smaddAdServerSecretKey;
@property (retain, readwrite) NSString *enableAdNameSortByPriority;
@end