
#import "RNZumoKit.h"
#import "ZumoKitManager.h"
#import <ZumoKitSDK/CPKeystore.h>

@implementation RNZumoKit

bool hasListeners;

// Let's run the methods in a separate queue!
- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.zumopay.walletqueue", DISPATCH_QUEUE_SERIAL);
}

RCT_EXPORT_MODULE()

# pragma mark - Events

- (NSArray<NSString *> *)supportedEvents {
    return @[@"StoreUpdated"];
}

- (void)startObserving {
    hasListeners = YES;
    
    [[ZumoKitManager sharedManager] subscribeToStoreObserverWithCompletionHandler:^(CPActionType actionType, CPState * _Nonnull state) {
        [self sendEventWithName:@"StoreUpdated" body:NULL];
    }];
}

- (void)stopObserving {
    hasListeners = NO;
    
    [[ZumoKitManager sharedManager] unsubscribeFromStoreObserver];
}

# pragma mark - Initialisation

RCT_EXPORT_METHOD(init:(NSString *)apiKey appId:(NSString *)appId apiRoot:(NSString *)apiRoot myRoot:(NSString *)myRoot txServiceUrl:(NSString *)txServiceUrl resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    // Boot the ZumoKitManager to handle the native C++ code
    [[ZumoKitManager sharedManager]
     initializeWithTxServiceUrl:txServiceUrl
     apiKey:apiKey
     appId:appId
     apiRoot:apiRoot
     myRoot:myRoot
     ];
    
    
    resolve(@(YES));
    
}

RCT_EXPORT_METHOD(auth:(NSString *)token headers:(NSDictionary *)headers resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
        
        [[ZumoKitManager sharedManager] authenticateWithToken:token headers:headers completionHandler:^(bool success, short errorCode, NSString * _Nullable data) {
            
            if(success) {
                resolve(@"true");
                return;
            }
            
            reject([NSString stringWithFormat:@"%d", errorCode], data, NULL);
            
        }];
        
    } @catch (NSException *exception) {
        
        reject([exception name], [exception reason], NULL);
        
    }
    
}

# pragma mark - Wallet Management

RCT_EXPORT_METHOD(createWallet:(NSString *)password mnemonicCount:(int)mnemonicCount resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
        
        [[ZumoKitManager sharedManager]
         createWalletWithPassword:password
         mnemonicCount:mnemonicCount
         completionHandler:^(bool success, NSDictionary * _Nullable response, NSString * _Nullable errorName, NSString * _Nullable errorMessage) {
             
             if(success) {
                 resolve(response);
             } else {
                 reject(errorName, errorMessage, NULL);
             }
             
         }];
        
    } @catch (NSException *exception) {
        
        reject([exception name], [exception reason], NULL);
        
    }
    
}

RCT_EXPORT_METHOD(getWallet:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
        
        NSDictionary *response = [[ZumoKitManager sharedManager] getWallet];
        resolve(response);
        
    } @catch (NSException *exception) {
        
        reject([exception name], [exception reason], NULL);
        
    }
    
}

RCT_EXPORT_METHOD(unlockWallet:(NSString *)walletId password:(NSString *)password resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
        
        BOOL status = [[ZumoKitManager sharedManager]
                       unlockWalletWithId:walletId
                       password:password];
        
        resolve(@(status));
        
    } @catch (NSException *exception) {
        
        reject([exception name], [exception reason], NULL);
        
    }
    
}

# pragma mark - Transactions

RCT_EXPORT_METHOD(sendTransaction:(NSString *)walletId address:(NSString *)address amount:(NSString *)amount gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
        
        [[ZumoKitManager sharedManager] sendTransactionFromWalletWithId:walletId toAddress:address amount:amount gasPrice:gasPrice gasLimit:gasLimit completionHandler:^(bool success, NSString * _Nullable errorName, NSString * _Nullable errorMessage, CPTransaction * _Nullable transaction) {
            
            if(success) {
                NSDictionary *response = @{
                                           @"value": [transaction amount],
                                           @"hash": @([transaction hash]),
                                           @"status": @([transaction status]),
                                           @"to": [transaction toAddress],
                                           @"from": [transaction fromAddress],
                                           @"timestamp": @([transaction timestamp]),
                                           @"gas_price": [transaction gasPrice],
                                           @"type": @"OUTGOING"
                                           };
                
                resolve(response);
                return;
            }
            
            reject(errorName, errorMessage, NULL);
            
        }];
        
    } @catch (NSException *exception) {
        
        reject([exception name], [exception reason], NULL);
        
    }
    
}

RCT_EXPORT_METHOD(getTransactions:(NSString *)walletId resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        
        NSArray *transactions = [[ZumoKitManager sharedManager]
                                 getTransactionsForWalletId:walletId];
        
        resolve(transactions);
        
    } @catch (NSException *exception) {
        
        reject([exception name], [exception reason], NULL);
        
    }
    
}

# pragma mark - Utility & Helpers

RCT_EXPORT_METHOD(getBalance:(NSString *)address resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        
        NSString *balance = [[ZumoKitManager sharedManager]
                             getBalanceForAddress:address];
        resolve(balance);
        
    } @catch (NSException *exception) {
        
        reject([exception name], [exception reason], NULL);
        
    }
    
}

RCT_EXPORT_METHOD(getExchangeRates:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *rates = [[ZumoKitManager sharedManager] getExchangeRates];
    resolve(rates);
}

RCT_EXPORT_METHOD(isValidEthAddress:(NSString *)address resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    BOOL isValid = [[ZumoKitManager sharedManager] isValidEthAddress:address];
    resolve(@(isValid));
}

RCT_EXPORT_METHOD(ethToGwei:(NSString *)eth resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *gwei = [[ZumoKitManager sharedManager] ethToGwei:eth];
    resolve(gwei);
}

RCT_EXPORT_METHOD(gweiToEth:(NSString *)gwei resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *eth = [[ZumoKitManager sharedManager] gweiToEth:gwei];
    resolve(eth);
}

RCT_EXPORT_METHOD(ethToWei:(NSString *)eth resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *wei = [[ZumoKitManager sharedManager] ethToWei:eth];
    resolve(wei);
}

RCT_EXPORT_METHOD(weiToEth:(NSString *)wei resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *eth = [[ZumoKitManager sharedManager] weiToEth:wei];
    resolve(eth);
}

@end
