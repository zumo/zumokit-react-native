//
//  ZumoKitManager.h
//  Pods-Zumo
//
//  Created by Stephen Radford on 30/04/2019.
//

#import <Foundation/Foundation.h>

#import <ZumoKitSDK/ZumoKit.h>
#import <ZumoKitSDK/iOSAuthCallback.h>
#import <ZumoKitSDK/CPWalletManagement.h>
#import <ZumoKitSDK/CPKeystore.h>
#import <ZumoKitSDK/CPCurrency.h>
#import <ZumoKitSDK/CPStore.h>
#import <ZumoKitSDK/CPState.h>
#import <ZumoKitSDK/CPUtils.h>
#import <ZumoKitSDK/CPTransaction.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZumoKitManager : NSObject

+ (ZumoKitManager *)sharedManager;

- (void)initializeWithTxServiceUrl:(NSString *)txServiceUrl apiKey:(NSString *)apiKey appId:(NSString *)appId apiRoot:(NSString *)apiRoot;

- (void)authenticateWithEmail:(NSString *)email completionHandler:(AuthCompletionBlock)completionHandler;

- (NSDictionary *)createWalletWithPassword:(NSString *)password mnemonicCount:(int)mnemonicCount;

- (NSDictionary *)getWallet;

- (BOOL)unlockWalletWithId:(NSString *)keystoreId password:(NSString *)password;

- (NSString *)getExchangeRates;

- (NSString *)getBalanceForAddress:(NSString *)address;

- (BOOL)isValidEthAddress:(NSString *)address;

- (NSArray<NSDictionary *> *)getTransactionsForWalletId:(NSString *)walletId;

@end

NS_ASSUME_NONNULL_END
