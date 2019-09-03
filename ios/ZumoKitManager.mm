//
//  ZumoKitManager.m
//  Pods-Zumo
//
//  Created by Stephen Radford on 30/04/2019.
//

#import "ZumoKitManager.h"

@interface ZumoKitManager ()

@property (strong, nonatomic) ZumoKitImpl *zumoKit;

@property (strong, nonatomic) ZKStoreObserver *storeObserver;

@end

@implementation ZumoKitManager

NSException *zumoKitNotInitializedException = [NSException
                                               exceptionWithName:@"ZumoKitNotInitialized"
                                               reason:@"ZumoKit has not been initialized"
                                               userInfo:nil];

+ (id)sharedManager {
    static ZumoKitManager *manager = nil;
    @synchronized(self) {
        if (manager == nil)
            manager = [[self alloc] init];
    }
    return manager;
}

# pragma mark - Initialization

- (void)initializeWithTxServiceUrl:(NSString *)txServiceUrl apiKey:(NSString *)apiKey appId:(NSString *)appId apiRoot:(NSString *)apiRoot myRoot:(NSString *)myRoot {
    
    NSArray *appFolderPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [appFolderPath objectAtIndex:0];
    
    _zumoKit = [[ZumoKitImpl alloc] initWithDbPath:dbPath
                                      txServiceUrl:txServiceUrl
                                            apiKey:apiKey
                                             appId:appId
                                           apiRoot:apiRoot
                                            myRoot:myRoot
                ];
}

- (void)syncWithCompletionHandler:(void (^)(bool success, short errorCode, NSString * _Nullable data))completionHandler {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    // If there's no active user then thrown an exeption
    CPState *state = [[_zumoKit store] getState];
    if(! [state activeUser]) {
        @throw [NSException exceptionWithName:@"ZumoKitUserNotAuthenticated"
        reason:@"There's currently no active user."
        userInfo:nil];
    }

    [[_zumoKit zumoCore] sync:[[iOSSyncCallback alloc] initWithCompletionHandler:completionHandler]];
}

- (void)subscribeToStoreObserverWithCompletionHandler:(void (^)(CPState * _Nonnull))completionHandler {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    _storeObserver = [[ZKStoreObserver alloc] initWithCompletionHandler:completionHandler];
    [[_zumoKit store] subscribe:_storeObserver];
}

- (void)unsubscribeFromStoreObserver {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    [[_zumoKit store] unsubscribe:_storeObserver];
    _storeObserver = NULL;
}

- (void)authenticateWithToken:(NSString *)token headers:(NSDictionary *)headers completionHandler:(AuthCompletionBlock)completionHandler {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    iOSAuthCallback *callback = [[iOSAuthCallback alloc]
                                 initWithCompletionHandler:completionHandler];
    
    [[_zumoKit zumoCore] auth:token headers:headers callback:callback];
}

# pragma mark - Wallet Management

- (void)createWalletWithPassword:(NSString *)password mnemonicCount:(int)mnemonicCount completionHandler:(void (^)(bool success, NSDictionary * _Nullable response, NSString * _Nullable errorName, NSString * _Nullable errorMessage))completionHandler {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    CPWalletManagement *walletManagement = [_zumoKit walletManagement];
    
    NSString *mnemonicPhrase = [walletManagement generateMnemonic:mnemonicCount];
    
    [walletManagement
     createWallet: CPCurrencyETH
     password:password
     mnemonic:mnemonicPhrase
     callback: [[iOSCreateWalletCallback alloc] initWithCompletionHandler:^(bool success, NSString * _Nullable errorName, NSString * _Nullable errorMessage, CPKeystore * _Nullable keystore) {
        
        if(success) {
            
            NSDictionary *response = @{ @"mnemonic": mnemonicPhrase,
                                        @"keystore": @{
                                                @"id": [keystore id],
                                                @"address": [keystore address],
                                                @"unlocked": @([keystore unlocked]),
                                                @"balance": [keystore balance]
                                                }
                                        };
            
            completionHandler(YES, response, NULL, NULL);
        } else {
            completionHandler(NO, NULL, errorName, errorMessage);
        }
    }]];
}

- (NSDictionary *)getWallet {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    CPState *state = [[_zumoKit store] getState];
    NSArray<CPKeystore *> *keystores = [state keystores];
    
    if([keystores count] < 1) {
        @throw [NSException
                exceptionWithName:@"noKeystoresFound"
                reason:@"No keystores found."
                userInfo:NULL];
    }
    
    CPKeystore *keystore = [keystores objectAtIndex:0];
    
    return @{
             @"id": [keystore id],
             @"address": [keystore address],
             @"unlocked": @([keystore unlocked]),
             @"balance": [keystore balance]
             };
}

- (BOOL)unlockWalletWithId:(NSString *)keystoreId password:(NSString *)password {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    CPStore *store = [_zumoKit store];
    CPKeystore *keystore = [store getKeystore:keystoreId];
    
    BOOL status = [[_zumoKit walletManagement]
                   unlockWallet:keystore
                   password:password];
    
    return status;
}

- (NSArray<NSDictionary *> *)getTransactionsForWalletId:(NSString *)walletId {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    CPStore *store = [_zumoKit store];
    CPKeystore *keystore = [store getKeystore:walletId];
    NSString *address = [[keystore address] lowercaseString];
    
    CPState *state = [store getState];
    NSArray<CPTransaction *> *transactions = [state transactions];
    
    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];
    
    [transactions enumerateObjectsUsingBlock:^(CPTransaction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *type = ([[[obj toAddress] lowercaseString] isEqualToString:address]) ? @"INCOMING" : @"OUTGOING";
        
        [mapped addObject:@{
                            @"value": [obj amount],
                            @"hash": @([obj hash]),
                            @"status": @([obj status]),
                            @"to": [obj toAddress],
                            @"from": [obj fromAddress],
                            @"timestamp": @([obj timestamp]),
                            @"gas_price": [obj gasPrice],
                            @"type": type,
                            @"from_user_id": ([obj fromUserId]) ? [obj fromUserId] : @"",
                            @"to_user_id": ([obj toUserId]) ? [obj toUserId] : @"",
                            }];
        
    }];
    
    return mapped;
}

- (void)sendTransactionFromWalletWithId:(NSString *)walletId toAddress:(NSString *)address amount:(NSString *)amount gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit completionHandler:(SendTransactionCompletionBlock)completionHandler {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    CPStore *store = [_zumoKit store];
    CPKeystore *keystore = [store getKeystore:walletId];
    
    [[_zumoKit walletManagement]
     sendTransaction:keystore
     toAddress:address
     amount:amount
     gasPrice:gasPrice
     gasLimit:gasLimit
     payload:@""
     callback:[[iOSSendTransactionCallback alloc]
               initWithCompletionHandler:completionHandler]];
}

# pragma mark - Utility

- (NSString *)getBalanceForAddress:(NSString *)address {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    NSString *balance = [[_zumoKit utils] ethGetBalance:address];
    
    return balance;
}

- (NSString *)getExchangeRates {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    CPState *state = [[_zumoKit store] getState];
    return [state exchangeRates];
}

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

@end
