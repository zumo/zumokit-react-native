//
//  ZumoKitManager.h
//  Pods-Zumo
//
//  Created by Stephen Radford on 30/04/2019.
//

#import <Foundation/Foundation.h>

#import <ZumoKitSDK/ZumoKit.h>
#import <ZumoKitSDK/iOSAuthCallback.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZumoKitManager : NSObject

+ (ZumoKitManager *)sharedManager;

- (void)initializeWithTxServiceUrl:(NSString *)txServiceUrl apiKey:(NSString *)apiKey appId:(NSString *)appId apiRoot:(NSString *)apiRoot;

- (void)authenticateWithEmail:(NSString *)email;

- (void)authenticateWithEmail:(NSString *)email completionHandler:(AuthCompletionBlock)completionHandler;

@end

NS_ASSUME_NONNULL_END
