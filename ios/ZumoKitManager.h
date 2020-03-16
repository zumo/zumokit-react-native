//
//  ZumoKitManager.h
//  Pods-Zumo
//
//  Created by Stephen Radford on 30/04/2019.
//

#import <Foundation/Foundation.h>
#import <ZumoKit/ZumoKit.h>
#import <ZumoKit/ZKStateListener.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZumoKitManager : NSObject

@property(weak) id<ZKStateListener> stateListener;

+ (ZumoKitManager *)sharedManager;

- (void)initializeWithTxServiceUrl:(NSString *)txServiceUrl apiKey:(NSString *)apiKey apiRoot:(NSString *)apiRoot myRoot:(NSString *)myRoot;

- (void)authenticateWithToken:(NSString *)token headers:(NSDictionary *)headers completionHandler:(_Nonnull AuthCompletionBlock)completionHandler;

#pragma mark - Wallet Management

- (void)createWallet:(NSString *)mnemonic password:(NSString *)password completionHandler:(_Nonnull WalletCompletionBlock)completionHandler;

- (void)unlockWallet:(NSString *)password completionHandler:(_Nonnull WalletCompletionBlock)completionHandler;

- (void)revealMnemonic:(NSString *)password completionHandler:(_Nonnull MnemonicCompletionBlock)completionHandler;

- (void)sendEthTransaction:(NSString *)accountId gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)to value:(NSString *)value data:(nullable NSString *)data nonce:(nullable NSNumber *)nonce completionHandler:(_Nonnull SendTransactionCompletionBlock)completionHandler;

- (void)sendBtcTransaction:(NSString *)accountId changeAccountId:(NSString *)changeAccountId to:(NSString *)to value:(NSString *)value feeRate:(NSString *)feeRate completionHandler:(_Nonnull SendTransactionCompletionBlock)completionHandler;

#pragma mark - Wallet Recovery

- (BOOL)isRecoveryMnemonic:(NSString *)mnemonic;

- (void)recoverWallet:(NSString *)mnemonic password:(NSString *)password completionHandler:(_Nonnull WalletCompletionBlock)completionHandler;

#pragma mark - Utility

- (BOOL)isValidEthAddress:(NSString *)address;

- (BOOL)isValidBtcAddress:(NSString *)address network:(ZKNetworkType)network;

- (NSString *)ethToGwei:(NSString *)eth;

- (NSString *)gweiToEth:(NSString *)gwei;

- (NSString *)ethToWei:(NSString *)eth;

- (NSString *)weiToEth:(NSString *)wei;

- (NSString *)generateMnemonic:(int)wordLength;

- (NSString *)maxSpendableEth:(nonnull NSString *)accountId gasPrice:(nonnull NSString *)gasPrice gasLimit:(nonnull NSString *)gasLimit;

- (NSString *)maxSpendableBtc:(nonnull NSString *)accountId to:(nonnull NSString *)to feeRate:(nonnull NSString *)feeRate;

- (void)clear;

@end

NS_ASSUME_NONNULL_END
