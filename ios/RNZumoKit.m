
#import "RNZumoKit.h"
#import "ZumoKitManager.h"

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
    return @[@"StateChanged"];
}

- (void)startObserving {
    hasListeners = YES;
    
//    [[ZumoKitManager sharedManager] subscribeToStoreObserverWithCompletionHandler:^(CPState * _Nonnull state) {
//        @try {
//
//            [self sendEventWithName:@"StoreUpdated" body:@{
//                                                           @"wallet": [[ZumoKitManager sharedManager] getWalletFromState:state]
//                                                           }];
//
//        } @catch (NSException *exception) {
//
//            //
//
//        }
//    }];
}

- (void)stopObserving {
    hasListeners = NO;
    
//    [[ZumoKitManager sharedManager] unsubscribeFromStoreObserver];
}

# pragma mark - Initialization + Authentication

RCT_EXPORT_METHOD(init:(NSString *)apiKey apiRoot:(NSString *)apiRoot myRoot:(NSString *)myRoot txServiceUrl:(NSString *)txServiceUrl)
{
    
    [[ZumoKitManager sharedManager]
     initializeWithTxServiceUrl:txServiceUrl
     apiKey:apiKey
     apiRoot:apiRoot
     myRoot:myRoot];
    
}

RCT_EXPORT_METHOD(auth:(NSString *)token headers:(NSDictionary *)headers resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
        
        [[ZumoKitManager sharedManager]
         authenticateWithToken:token
         headers:headers
         completionHandler:^(bool success, short errorCode, NSString * _Nullable errorMessage, ZKUser * _Nullable user) {
            
            if(user) {
                
                resolve(@{
                    @"id": [user getId],
                    @"hasWallet": @([user hasWallet])
                });
                
            } else {
                reject(@"error", errorMessage, NULL);
            }
            
        }];
        
    } @catch (NSException *exception) {
        
        reject(exception.name, exception.description, NULL);
        
    }
    
}

# pragma mark - Wallet Management


RCT_EXPORT_METHOD(createWallet:(NSString *)mnemonic password:(NSString *)password resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
    
        [[ZumoKitManager sharedManager] createWallet:mnemonic password:password completionHandler:^(BOOL success) {
            
            if(success) {
                resolve(@(success));
            } else {
                reject(@"error", @"Could not create wallet", NULL);
            }
            
        }];
        
    } @catch (NSException *exception) {
        
        reject(exception.name, exception.description, NULL);
        
    }
    
}

RCT_EXPORT_METHOD(revealMnemonic:(NSString *)password resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
        
        [[ZumoKitManager sharedManager] revealMnemonic:password completionHandler:^(bool success, NSString * _Nullable errorName, NSString * _Nullable errorMessage, NSString * _Nullable mnemonic) {
            
            if(success) {
                resolve(mnemonic);
            } else {
                reject(@"error", @"Could not retrieve mnemonic", NULL);
            }
            
        }];
        
    } @catch (NSException *exception) {
        
        reject(exception.name, exception.description, NULL);
        
    }
    
}

RCT_EXPORT_METHOD(unlockWallet:(NSString *)password resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
    
        [[ZumoKitManager sharedManager] unlockWallet:password completionHandler:^(BOOL success) {
            
            if(success) {
                resolve(@(success));
            } else {
                reject(@"error", @"Could not unlock wallet", NULL);
            }
            
        }];
        
    } @catch (NSException *exception) {
        
        reject(exception.name, exception.description, NULL);
        
    }
    
}


# pragma mark - Utility & Helpers


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

RCT_EXPORT_METHOD(generateMnemonic:(int)wordLength resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *mnemonic = [[ZumoKitManager sharedManager] generateMnemonic:wordLength];
    resolve(mnemonic);
}

@end
