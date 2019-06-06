
#import "RNZumoKit.h"
#import "ZumoKitManager.h"
#import <ZumoKitSDK/CPKeystore.h>

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
    
    resolve(@(YES));
    
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

RCT_EXPORT_METHOD(createWallet:(NSString *)password mnemonicCount:(int)mnemonicCount resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
        
        NSDictionary *response = [[ZumoKitManager sharedManager]
                                createWalletWithPassword:password
                                mnemonicCount:mnemonicCount];
        
        resolve(response);
        
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
        
        [[ZumoKitManager sharedManager] sendTransactionFromWalletWithId:walletId toAddress:address amount:amount gasPrice:gasPrice gasLimit:gasLimit completionHandler:^(bool success, NSString * _Nullable errorMessage, CPTransaction * _Nonnull transaction) {
            
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
            
            reject(@"ErrorSendingTransaction", errorMessage, NULL);
            
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

@end
