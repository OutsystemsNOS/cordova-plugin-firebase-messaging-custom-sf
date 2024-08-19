#import "AppDelegate.h"

@import UserNotifications;
//@import Firebase;
@import FirebaseCore;

@interface AppDelegate (FirebaseMessagingPlugin) <FIRMessagingDelegate, UNUserNotificationCenterDelegate>

@end
