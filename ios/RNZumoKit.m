
#import "RNZumoKit.h"
#import "ZumoKitManager.h"

@implementation RNZumoKit

// Let's run the methods in a separate queue!
- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.zumopay.walletqueue", DISPATCH_QUEUE_SERIAL);
}

RCT_EXPORT_MODULE()

# pragma mark - Initialisation

RCT_EXPORT_METHOD(init:(NSString *)apiKey appId:(NSString *)appId apiRoot:(NSString *)apiRoot txServiceUrl:(NSString *)txServiceUrl resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    [[ZumoKitManager sharedManager]
     initializeWithTxServiceUrl:txServiceUrl
     apiKey:apiKey
     appId:appId
     apiRoot:apiRoot
     ];
    
    resolve(@"true");
    
}

RCT_EXPORT_METHOD(auth:(NSString *)email resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
        
        [[ZumoKitManager sharedManager] authenticateWithEmail:email completionHandler:^(bool success, short errorCode, NSString * _Nullable data) {
            
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

RCT_EXPORT_METHOD(createWallet:(NSString *)password mnemonicCount:(NSInteger *)mnemonicCount resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
}

RCT_EXPORT_METHOD(getWallet:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    // TODO: Load the wallet from the C++ lib
}

RCT_EXPORT_METHOD(unlockWallet:(NSString *)walletId password:(NSString *)password resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    // TODO: Load the wallet from the C++ lib and unlock it
}

# pragma mark - Transactions

RCT_EXPORT_METHOD(sendTransaction:(NSString *)walletId address:(NSString *)address amount:(NSString *)amount resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    // TODO: Send a new transaction
}

RCT_EXPORT_METHOD(getTransactions:(NSString *)walletId resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    // TODO: Load transactions from C++ lib
}

# pragma mark - Utility & Helpers

RCT_EXPORT_METHOD(getBalance:(NSString *)address resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    // TODO: Get the balance for the wallet provided
}

RCT_EXPORT_METHOD(getExchangeRates:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    // TODO: Load the exchange rates from ZumoKit
}

RCT_EXPORT_METHOD(isValidEthAddress:(NSString *)address resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    // TODO: Validate the address with ZumoKit
}

@end
