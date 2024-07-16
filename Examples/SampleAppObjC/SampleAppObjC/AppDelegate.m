//
//  AppDelegate.m
//  SampleAppObjC
//
//  Created by Pallab Maiti on 11/03/22.
//

#import "AppDelegate.h"

@import Rudder;
@import RudderBraze;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    RSConfig *config = [[RSConfig alloc] initWithWriteKey:@"<WRITE KEY>"];
    [config dataPlaneURL:@"<DATA PLANE URL>"];
    [config loglevel:RSLogLevelDebug];
    [config trackLifecycleEvents:YES];
    [config recordScreenViews:YES];
    
    RSClient *client = [RSClient sharedInstance];
    [client configureWith:config];
    
    [client addDestination:[[RudderBrazeDestination alloc] init]];
    [client track:@"Track 1"];
    
    [client identify:@"test_user_id"];
    
    [client track:@"daily_rewards_claim"];
    [client track:@"level_up"];
    [client track:@"revenue"];
    
    [self setupPushCategories];
    
    return YES;
}

-(void) setupPushCategories {
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max) {
      UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
      center.delegate = self;
      UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
      if (@available(iOS 12.0, *)) {
      options = options | UNAuthorizationOptionProvisional;
      }
      [center requestAuthorizationWithOptions:options
                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
          [[RSClient sharedInstance] pushAuthorizationFromUserNotificationCenter:granted];
      }];
      [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                });
            } else {
                // Handle error or denial
            }
        }];
    }
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
