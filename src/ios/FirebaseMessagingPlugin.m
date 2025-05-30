#import "FirebaseMessagingPlugin.h"
#import <Cordova/CDV.h>
#import "AppDelegate.h"
#import "UserNotifications/UserNotifications.h"

//@import Firebase;
@import FirebaseMessaging;
@import FirebaseCore;

@implementation FirebaseMessagingPlugin

- (void)pluginInitialize {
    NSLog(@"Starting Firebase Messaging plugin");

    if(![FIRApp defaultApp]) {
        [FIRApp configure];
    }
}

//mlrosa - Added a new method to check if notifications are ative or not
- (void)hasPermission:(CDVInvokedUrlCommand *)command {
    @try {
        NSLog(@"Starting hasPermission");
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            BOOL granted = settings.authorizationStatus == UNAuthorizationStatusAuthorized;

            NSString *isEnabledString = granted ? @"true" : @"false";
            NSLog(@"Starting send result");
            CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:isEnabledString];
            [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        }];
    } @catch (NSException *exception) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsString:[NSString stringWithFormat:@"Erro ao verificar permissões: %@", exception.reason]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)requestPermission:(CDVInvokedUrlCommand *)command {
    NSDictionary* options = [command.arguments objectAtIndex:0];

    NSNumber* forceShowSetting = options[@"forceShow"];
    if (forceShowSetting && [forceShowSetting boolValue]) {
        self.forceShow = UNNotificationPresentationOptionBadge |
            UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert;
    } else {
        self.forceShow = UNNotificationPresentationOptionNone;
    }

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions authOptions = (UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge);
    [center requestAuthorizationWithOptions:authOptions
                          completionHandler:^(BOOL granted, NSError* err) {
                              CDVPluginResult *pluginResult;
                              if (err) {
                                  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:err.localizedDescription];
                              } else if (!granted) {
                                  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Notifications permission is not granted"];
                              } else {
                                  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                              }

                              [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                          }];

    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)clearNotifications:(CDVInvokedUrlCommand *)command {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeAllDeliveredNotifications];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)deleteToken:(CDVInvokedUrlCommand *)command {
    [[FIRMessaging messaging] deleteTokenWithCompletion:^(NSError * err) {
        CDVPluginResult *pluginResult;
        if (err) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:err.localizedDescription];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getToken:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult;
    NSString* type = [command.arguments objectAtIndex:0];

    if ([type length] == 0) {
        NSString *fcmToken = [FIRMessaging messaging].FCMToken;
        if (fcmToken) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:fcmToken];
        } else {
            [[FIRMessaging messaging] tokenWithCompletion:^(NSString * token, NSError * err) {
                CDVPluginResult *pluginResult;
                if (err) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:err.localizedDescription];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:token];
                }
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }];
        }
    } else if ([type hasPrefix:@"apns-"]) {
        NSData* apnsToken = [FIRMessaging messaging].APNSToken;
        if (apnsToken) {
            if ([type isEqualToString:@"apns-buffer"]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArrayBuffer:apnsToken];
            } else if ([type isEqualToString:@"apns-string"]) {
                NSUInteger len = apnsToken.length;
                const unsigned char *buffer = apnsToken.bytes;
                NSMutableString *hexToken  = [NSMutableString stringWithCapacity:(len * 2)];
                for (int i = 0; i < len; ++i) {
                    [hexToken appendFormat:@"%02x", buffer[i]];
                }
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:hexToken];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid token type argument"];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:nil];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:nil];
    }

    if (pluginResult) {
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)setBadge:(CDVInvokedUrlCommand *)command {
    int badge = [[command.arguments objectAtIndex:0] intValue];

    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getBadge:(CDVInvokedUrlCommand *)command {
    int badge = (int)[[UIApplication sharedApplication] applicationIconBadgeNumber];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:badge];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)subscribe:(CDVInvokedUrlCommand *)command {
    NSString* topic = [NSString stringWithFormat:@"%@", [command.arguments objectAtIndex:0]];

    [[FIRMessaging messaging] subscribeToTopic:topic
                                    completion:^(NSError* err) {
                                        CDVPluginResult *pluginResult;
                                        if (err) {
                                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:err.localizedDescription];
                                        } else {
                                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                                        }
                                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                    }];
}

- (void)unsubscribe:(CDVInvokedUrlCommand *)command {
    NSString* topic = [NSString stringWithFormat:@"%@", [command.arguments objectAtIndex:0]];

    [[FIRMessaging messaging] unsubscribeFromTopic:topic
                                        completion:^(NSError* err) {
                                            CDVPluginResult *pluginResult;
                                            if (err) {
                                                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:err.localizedDescription];
                                            } else {
                                                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                                            }
                                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                                        }];
}

- (void)onMessage:(CDVInvokedUrlCommand *)command {
    self.notificationCallbackId = command.callbackId;
}

- (void)onBackgroundMessage:(CDVInvokedUrlCommand *)command {
    self.backgroundNotificationCallbackId = command.callbackId;

    if (self.lastNotification) {
        [self sendBackgroundNotification:self.lastNotification];

        self.lastNotification = nil;
    }
}

- (void)onTokenRefresh:(CDVInvokedUrlCommand *)command {
    self.tokenRefreshCallbackId = command.callbackId;
}

- (void)sendNotification:(NSDictionary *)userInfo {
    if (self.notificationCallbackId) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:userInfo];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.notificationCallbackId];
    }
}

- (void)sendBackgroundNotification:(NSDictionary *)userInfo {
    if (self.backgroundNotificationCallbackId) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:userInfo];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.backgroundNotificationCallbackId];
    } else {
        self.lastNotification = userInfo;
    }
}

- (void)sendToken:(NSString *)fcmToken {
    if (self.tokenRefreshCallbackId) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.tokenRefreshCallbackId];
    }
}

@end
