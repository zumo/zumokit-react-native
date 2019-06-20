//
//  ZumoKitManager.h
//  Pods-Zumo
//
//  Created by Stephen Radford on 30/04/2019.
//

#import <Foundation/Foundation.h>

#import <ZumoKitSDK/ZumoKit.h>
#import <ZumoKitSDK/iOSAuthCallback.h>
#import <ZumoKitSDK/iOSSendTransactionCallback.h>
#import <ZumoKitSDK/iOSCreateWalletCallback.h>
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

- (void)createWalletWithPassword:(NSString *)password mnemonicCount:(int)mnemonicCount completionHandler:(CreateWalletCompletionBlock)completionHandler;

- (NSDictionary *)getWallet;

- (BOOL)unlockWalletWithId:(NSString *)keystoreId password:(NSString *)password;

- (NSString *)getExchangeRates;

- (NSString *)getBalanceForAddress:(NSString *)address;

- (BOOL)isValidEthAddress:(NSString *)address;

- (NSArray<NSDictionary *> *)getTransactionsForWalletId:(NSString *)walletId;

- (void)createWalletWithPassword:(NSString *)password mnemonicCount:(int)mnemonicCount completionHandler:(void (^)(bool success, NSDictionary * _Nullable response, NSString * _Nullable errorName, NSString * _Nullable errorMessage))completionHandler;

- (NSString *)ethToGwei:(NSString *)eth;

- (NSString *)gweiToEth:(NSString *)gwei;

- (NSString *)ethToWei:(NSString *)eth;

- (NSString *)weiToEth:(NSString *)wei;

@end

NS_ASSUME_NONNULL_END
