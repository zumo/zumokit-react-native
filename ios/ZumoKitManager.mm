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
                                               exceptionWithName:@"ZumoKitNotInitialized"
                                               reason:@"ZumoKit has not been initialized"
                                               userInfo:nil];

NSException *userNotAuthenticatedException = [NSException
                                              exceptionWithName:@"UserNotAuthenticated"
                                              reason:@"A user has not been authenticated"
                                              userInfo:nil];

NSException *walletNotFoundException = [NSException
                                        exceptionWithName:@"WalletNotFound"
                                        reason:@"The user doesn't seem to have wallet"
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
    
    [_zumoKit auth:token headers:headers completion:^(bool success, short errorCode, NSString * _Nullable errorMessage, ZKUser * _Nullable user) {
        
        self->_user = user;
        
        completionHandler(success, errorCode, errorMessage, user);
        
    }];
    
}

# pragma mark - Wallet Management

- (void)createWallet:(NSString *)mnemonic password:(NSString *)password completionHandler:(void (^)(BOOL))completionHandler {
    
    if(! _user) @throw userNotAuthenticatedException;
    
    [_user createWallet:mnemonic password:password completion:^(bool success, NSString * _Nullable errorName, NSString * _Nullable errorMessage, ZKWallet * _Nullable wallet) {
       
        self->_wallet = wallet;
        
        completionHandler(success);
                
    }];
    
}


- (void)unlockWallet:(NSString *)password completionHandler:(void (^)(BOOL))completionHandler {
 
    if(! _user) @throw userNotAuthenticatedException;
    
    [_user unlockWallet:password completion:^(bool success, NSString * _Nullable errorName, NSString * _Nullable errorMessage, ZKWallet * _Nullable wallet) {
        
        self->_wallet = wallet;
        
        completionHandler(success);
        
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


# pragma mark - Utility

- (BOOL)isValidEthAddress:(NSString *)address {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    return [[_zumoKit utils] isValidEthAddress:address];
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

- (void)clear {
    _user = NULL;
    _wallet = NULL;
}

@end
