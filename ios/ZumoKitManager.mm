//
//  ZumoKitManager.m
//  Pods-Zumo
//
//  Created by Stephen Radford on 30/04/2019.
//

#import "ZumoKitManager.h"


@interface ZumoKitManager ()

@property (strong, nonatomic) ZumoKit *zumoKit;

@property (strong, nonatomic) ZKUser *user;

@property (strong, nonatomic) ZKWallet *wallet;

@end

@implementation ZumoKitManager

NSException *zumoKitNotInitializedException = [NSException
                                               exceptionWithName:@"zumokit_not_initialized"
                                               reason:@"ZumoKit has not been initialized."
                                               userInfo:nil];

NSException *userNotAuthenticatedException = [NSException
                                              exceptionWithName:@"user_not_authenticated"
                                              reason:@"A user has not been authenticated."
                                              userInfo:nil];

NSException *walletNotFoundException = [NSException
                                        exceptionWithName:@"wallet_not_found"
                                        reason:@"The user doesn't seem to have a wallet."
                                        userInfo:nil];

+ (id)sharedManager {
    static ZumoKitManager *manager = nil;
    @synchronized(self) {
        if (manager == nil)
            manager = [[self alloc] init];
    }
    return manager;
}


- (void)initializeWithTxServiceUrl:(NSString *)txServiceUrl apiKey:(NSString *)apiKey apiRoot:(NSString *)apiRoot myRoot:(NSString *)myRoot {

    _zumoKit =  [[ZumoKit alloc] initWithTxServiceUrl:txServiceUrl
                                               apiKey:apiKey
                                              apiRoot:apiRoot
                                               myRoot:myRoot
            ];

    [_zumoKit addStateListener:_stateListener];

}

- (void)authenticateWithToken:(NSString *)token headers:(NSDictionary *)headers completionHandler:(AuthCompletionBlock)completionHandler {

    if(! _zumoKit) @throw zumoKitNotInitializedException;

    [_zumoKit auth:token headers:headers completion:^(bool success, ZKZumoKitError * _Nullable error, ZKUser * _Nullable user) {

        self->_user = user;

        completionHandler(success, error, user);

    }];

}

# pragma mark - Wallet Management

- (void)createWallet:(NSString *)mnemonic password:(NSString *)password completionHandler:(WalletCompletionBlock)completionHandler {

    if(! _user) @throw userNotAuthenticatedException;

    [_user createWallet:mnemonic password:password completion:^(bool success, ZKZumoKitError * _Nullable error, ZKWallet * _Nullable wallet) {

        self->_wallet = wallet;

        completionHandler(success, error, wallet);

    }];

}


- (void)unlockWallet:(NSString *)password completionHandler:(WalletCompletionBlock)completionHandler {

    if(! _user) @throw userNotAuthenticatedException;

    [_user unlockWallet:password completion:^(bool success, ZKZumoKitError * _Nullable error, ZKWallet * _Nullable wallet) {

        self->_wallet = wallet;

        completionHandler(success, error, wallet);

    }];

}

- (void)revealMnemonic:(NSString *)password completionHandler:(MnemonicCompletionBlock)completionHandler {

    if(! _user) @throw userNotAuthenticatedException;
    [_user revealMnemonic:password completion:completionHandler];

}

- (void)sendEthTransaction:(NSString *)accountId gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)to value:(NSString *)value data:(NSString *)data nonce:(NSNumber *)nonce completionHandler:(SendTransactionCompletionBlock)completionHandler {

    if(! _wallet) @throw walletNotFoundException;

    [_wallet
     sendEthTransaction:accountId
     gasPrice:gasPrice
     gasLimit:gasLimit
     to:to
     value:value
     data:data
     nonce:NULL
     completion:completionHandler
     ];

}

- (void)sendBtcTransaction:(NSString *)accountId changeAccountId:(NSString *)changeAccountId to:(NSString *)to value:(NSString *)value feeRate:(NSString *)feeRate completionHandler:(SendTransactionCompletionBlock)completionHandler {

    if(! _wallet) @throw walletNotFoundException;

    [_wallet
     sendBtcTransaction:accountId
     changeAccountId:changeAccountId
     to:to value:value
     feeRate:feeRate
     completion:completionHandler];

}

# pragma mark - Wallet Recovery

- (BOOL)isRecoveryMnemonic:(NSString *)mnemonic {

    if(! _user) @throw userNotAuthenticatedException;
    return [_user isRecoveryMnemonic:mnemonic];

}

- (void)recoverWallet:(NSString *)mnemonic password:(NSString *)password completionHandler:(WalletCompletionBlock)completionHandler {

    if(! _user) @throw userNotAuthenticatedException;

    [_user recoverWallet:mnemonic password:password completion:^(bool success, ZKZumoKitError * _Nullable error, ZKWallet * _Nullable wallet) {

        self->_wallet = wallet;

        completionHandler(success, error, wallet);

    }];

}

# pragma mark - Account Management

- (nullable ZKAccount *)getAccount:(nonnull NSString *)symbol network:(ZKNetworkType)network type:(ZKAccountType)type {

    if(! _user) @throw userNotAuthenticatedException;

    return [_user getAccount:symbol network:network type:type];
}

# pragma mark - Utility

- (BOOL)isValidEthAddress:(NSString *)address {
    if(! _zumoKit) @throw zumoKitNotInitializedException;

    return [[_zumoKit utils] isValidEthAddress:address];
}

- (BOOL)isValidBtcAddress:(NSString *)address network:(ZKNetworkType)network {
    if(! _zumoKit) @throw zumoKitNotInitializedException;

    return [[_zumoKit utils] isValidBtcAddress:address network:network];
}

- (NSString *)ethToGwei:(NSString *)eth {
    if(! _zumoKit) @throw zumoKitNotInitializedException;

    return [[_zumoKit utils] ethToGwei:eth];
}

- (NSString *)gweiToEth:(NSString *)gwei {
    if(! _zumoKit) @throw zumoKitNotInitializedException;

    return [[_zumoKit utils] gweiToEth:gwei];
}

- (NSString *)ethToWei:(NSString *)eth {
    if(! _zumoKit) @throw zumoKitNotInitializedException;

    return [[_zumoKit utils] ethToWei:eth];
}

- (NSString *)weiToEth:(NSString *)wei {
    if(! _zumoKit) @throw zumoKitNotInitializedException;

    return [[_zumoKit utils] weiToEth:wei];
}

- (NSString *)generateMnemonic:(int)wordLength {
    if(! _zumoKit) @throw zumoKitNotInitializedException;

    return [[_zumoKit utils] generateMnemonic:wordLength];
}

- (NSString *)maxSpendableEth:(NSString *)accountId gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit {
    if(! _wallet) @throw walletNotFoundException;

    return [_wallet maxSpendableEth:accountId gasPrice:gasPrice gasLimit:gasPrice];
}

- (NSString *)maxSpendableBtc:(NSString *)accountId to:(NSString *)to feeRate:(NSString *)feeRate {
    if(! _wallet) @throw walletNotFoundException;

    return [_wallet maxSpendableBtc:accountId to:to feeRate:feeRate];
}

- (void)clear {
    _user = NULL;
    _wallet = NULL;
}

@end
