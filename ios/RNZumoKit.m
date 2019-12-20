
#import "RNZumoKit.h"
#import "ZumoKitManager.h"
#import <ZumoKit/ZumoKit.h>

@implementation RNZumoKit

bool hasListeners;

// Let's run the methods in a separate queue!
- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.zumopay.walletqueue", DISPATCH_QUEUE_SERIAL);
}

- (NSDictionary *)constantsToExport
{
    return @{ @"VERSION": [ZumoKit version] };
}

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

RCT_EXPORT_MODULE()

# pragma mark - Events

- (NSArray<NSString *> *)supportedEvents {
    return @[@"StateChanged"];
}

- (void)startObserving {
    hasListeners = YES;
}

- (void)stopObserving {
    hasListeners = NO;
}


- (void)update:(nonnull ZKState *)state {
    
    if(!hasListeners) return;
        
    [self sendEventWithName:@"StateChanged" body:[self mapState:state]];
    
}


# pragma mark - Initialization + Authentication

RCT_EXPORT_METHOD(init:(NSString *)apiKey apiRoot:(NSString *)apiRoot myRoot:(NSString *)myRoot txServiceUrl:(NSString *)txServiceUrl)
{
    
    [[ZumoKitManager sharedManager] setStateListener:self];
    
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

RCT_EXPORT_METHOD(sendEthTransaction:(NSString *)accountId gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)to value:(NSString *)value data:(NSString *)data nonce:(NSString *)nonce resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
    
        [[ZumoKitManager sharedManager] sendEthTransaction:accountId gasPrice:gasPrice gasLimit:gasLimit to:to value:value data:data nonce:nonce ? @([nonce integerValue]) : NULL completionHandler:^(bool success, NSString * _Nullable errorName, NSString * _Nullable errorMessage, ZKTransaction * _Nullable transaction) {
            
            if(transaction) {
                resolve([self mapTransaction:transaction]);
            } else {
                reject(@"error", @"Problem sending transaction", NULL);
            }
            
        }];
    
    } @catch (NSException *exception) {
           
       reject(exception.name, exception.description, NULL);
       
   }
    
}

RCT_EXPORT_METHOD(sendBtcTransaction:(NSString *)accountId changeAccountId:(NSString *)changeAccountId to:(NSString *)to value:(NSString *)value feeRate:(NSString *)feeRate resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
        
        [[ZumoKitManager sharedManager] sendBtcTransaction:accountId changeAccountId:changeAccountId to:to value:value feeRate:feeRate completionHandler:^(bool success, NSString * _Nullable errorName, NSString * _Nullable errorMessage, ZKTransaction * _Nullable transaction) {
           
            if(transaction) {
                resolve([self mapTransaction:transaction]);
            } else {
                reject(@"error", @"Problem sending transaction", NULL);
            }
            
        }];
        
    } @catch (NSException *exception) {
        
        reject(exception.name, exception.description, NULL);
        
    }
    
}


# pragma mark - Wallet Recovery


RCT_EXPORT_METHOD(isRecoveryMnemonic:(NSString *)mnemonic resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject) {
    
    @try {
        BOOL validation = [[ZumoKitManager sharedManager] isRecoveryMnemonic:mnemonic];
        resolve(@(validation));
    } @catch (NSException *exception) {
        reject(exception.name, exception.description, NULL);
    }
    
}

RCT_EXPORT_METHOD(recoverWallet:(NSString *)mnemonic password:(NSString *)password resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    
    @try {
    
        [[ZumoKitManager sharedManager] recoverWallet:mnemonic password:password completionHandler:^(BOOL success) {
            
            if(success) {
                resolve(@(success));
            } else {
                reject(@"error", @"Could not recover wallet", NULL);
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

RCT_EXPORT_METHOD(isValidBtcAddress:(NSString *)address network:(NSString *)network resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    ZKNetworkType networkType = ZKNetworkTypeMAINNET;
    if([network isEqualToString:@"TESTNET"]) {
        networkType = ZKNetworkTypeTESTNET;
    }
    
    BOOL isValid = [[ZumoKitManager sharedManager] isValidBtcAddress:address network:networkType];
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

RCT_EXPORT_METHOD(maxSpendableEth:(NSString *)accountId gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *max = [[ZumoKitManager sharedManager] maxSpendableEth:accountId gasPrice:gasPrice gasLimit:gasLimit];
    resolve(max);
}

RCT_EXPORT_METHOD(maxSpendableBtc:(NSString *)accountId to:(NSString *)to feeRate:(NSString *)feeRate resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *max = [[ZumoKitManager sharedManager] maxSpendableBtc:accountId to:to feeRate:feeRate];
    resolve(max);
}

RCT_EXPORT_METHOD(clear:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    [[ZumoKitManager sharedManager] clear];
    resolve(@(YES));
}

#pragma mark - Mapping

- (NSDictionary *)mapState:(ZKState *)state {

    return @{
        @"accounts": [self mapAccounts:[state accounts]],
        @"transactions": [self mapTransactions:[state transactions]],
        @"exchangeRates": [state exchangeRates]
    };
    
}

- (NSArray<NSDictionary *> *)mapAccounts:(NSArray<ZKAccount *>*)accounts {
 
    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];
    
    [accounts enumerateObjectsUsingBlock:^(ZKAccount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [mapped addObject:@{
            @"id": [obj id],
            @"path": [obj path],
            @"symbol": [obj symbol] ? [obj symbol] : @"",
            @"coin": [obj coin],
            @"address": [obj address],
            @"balance": [obj balance],
            @"chainId": [obj chainId] ? [obj chainId] : @0
        }];

    }];
    
    return mapped;
    
}

- (NSDictionary *)mapTransaction:(ZKTransaction *)transaction {
    
    NSString *status;
           
    switch ([transaction status]) {
       case ZKTransactionStatusCONFIRMED:
           status = @"CONFIRMED";
           break;
           
       case ZKTransactionStatusFAILED:
           status = @"FAILED";
           break;
            
        case ZKTransactionStatusRESUBMITTED:
            status = @"RESUBMITTED";
            break;
            
        case ZKTransactionStatusCANCELLED:
            status = @"CANCELLED";
            break;
           
       default:
           status = @"PENDING";
           break;
           
    }
    
    NSMutableDictionary *dict = [@{
        @"id": [transaction id],
        @"txHash": [transaction txHash],
        @"accountId": [transaction accountId],
        @"symbol": [transaction symbol],
        @"coin": [transaction coin],
        @"status": status,
        @"fromAddress": [transaction fromAddress],
        @"toAddress": [transaction toAddress],
        @"value": [transaction value],
        @"cost": [transaction cost],
        @"timestamp": @([transaction timestamp])
    } mutableCopy];
    
    if([transaction chainId]) dict[@"chainId"] = [transaction chainId];
    if([transaction nonce]) dict[@"nonce"] = [transaction nonce];
    if([transaction fromUserId]) dict[@"fromUserId"] = [transaction fromUserId];
    if([transaction toUserId]) dict[@"toUserId"] = [transaction toUserId];
    if([transaction data]) dict[@"data"] = [transaction data];
    if([transaction gasPrice]) dict[@"gasPrice"] = [transaction gasPrice];
    if([transaction gasLimit]) dict[@"gasLimit"] = [transaction gasLimit];
    if([transaction submittedAt]) dict[@"submittedAt"] = [transaction submittedAt];
    if([transaction confirmedAt]) dict[@"confirmedAt"] = [transaction confirmedAt];
    if([transaction fiatValue]) dict[@"fiatValue"] = [transaction fiatValue];
    
    return dict;
}

- (NSArray<NSDictionary *> *)mapTransactions:(NSArray<ZKTransaction *>*)transactions {
    
    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];
    
    [transactions enumerateObjectsUsingBlock:^(ZKTransaction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mapped addObject:[self mapTransaction:obj]];
    }];
    
    return mapped;
    
}


@end
