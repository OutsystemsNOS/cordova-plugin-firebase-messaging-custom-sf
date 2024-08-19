#import "AppDelegate.h"

@import UserNotifications;
//@import Firebase;
@import FirebaseMessaging;

@interface AppDelegate (FirebaseMessagingPlugin) <FIRMessagingDelegate, UNUserNotificationCenterDelegate>

@end
