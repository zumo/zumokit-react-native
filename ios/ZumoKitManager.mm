//
//  ZumoKitManager.m
//  Pods-Zumo
//
//  Created by Stephen Radford on 30/04/2019.
//

#import "ZumoKitManager.h"

@interface ZumoKitManager ()

@property (strong, nonatomic) ZumoKitImpl *zumoKit;

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

- (void)initializeWithTxServiceUrl:(NSString *)txServiceUrl apiKey:(NSString *)apiKey appId:(NSString *)appId apiRoot:(NSString *)apiRoot {
    
    NSArray *appFolderPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [appFolderPath objectAtIndex:0];
    
    _zumoKit = [[ZumoKitImpl alloc] initWithDbPath:dbPath
                                  txServiceUrl:txServiceUrl
                                        apiKey:apiKey
                                         appId:appId
                                       apiRoot:apiRoot
            ];
}

- (void)authenticateWithEmail:(NSString *)email completionHandler:(AuthCompletionBlock)completionHandler {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    iOSAuthCallback *callback = [[iOSAuthCallback alloc]
                                 initWithCompletionHandler:completionHandler];
    
    [[_zumoKit zumoCore] auth:email callback:callback];
}

# pragma mark - Wallet Management

- (NSDictionary *)createWalletWithPassword:(NSString *)password mnemonicCount:(int)mnemonicCount {
    if(! _zumoKit) @throw zumoKitNotInitializedException;
    
    CPWalletManagement *walletManagement = [_zumoKit walletManagement];
    
    NSString *mnemonicPhrase = [walletManagement generateMnemonic:mnemonicCount];
    
    CPKeystore *keystore = [walletManagement
                            createWallet:CPCurrencyETH
                            password:password
                            mnemonic:mnemonicPhrase];
    
    return @{ @"mnemonic": mnemonicPhrase,
              @"keystore": @{
                      @"id": [keystore id],
                      @"address": [keystore address],
                      @"unlocked": @([keystore unlocked])
                    }
              };
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
             @"unlocked": @([keystore unlocked])
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
        
        NSString *type = ([[obj toAddress] isEqualToString:address]) ? @"INCOMING" : @"OUTGOING";
        
        [mapped addObject:@{
                            @"value": [obj amount],
                            @"hash": @([obj hash]),
                            @"status": @([obj status]),
                            @"to": [obj toAddress],
                            @"from": [obj fromAddress],
                            @"timestamp": @([obj timestamp]),
                            @"gas_price": [obj gasPrice],
                            @"type": type
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

@end
