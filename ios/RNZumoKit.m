
#import "RNZumoKit.h"
#import <ZumoKit/ZumoKit.h>
#import <ZumoKit/ZKZumoKitErrorCode.h>
#import <ZumoKit/ZKZumoKitErrorType.h>

@interface RNZumoKit ()

@property (strong, nonatomic) ZumoKit *zumoKit;

@property (strong, nonatomic) ZKUser *user;

@property (strong, nonatomic) ZKWallet *wallet;

@end

@implementation RNZumoKit

bool hasListeners;

// Let's run the methods in a separate queue!
- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("com.zumopay.walletqueue", DISPATCH_QUEUE_SERIAL);
}

- (NSDictionary *)constantsToExport
{
    return @{ @"version": [ZumoKit version] };
}

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

- (void)rejectPromiseWith:(RCTPromiseRejectBlock)reject
                errorType:(NSString *)errorType
                errorCode:(NSString *)errorCode
             errorMessage:(NSString *)errorMessage
{
    reject(
        errorCode,
        errorMessage,
        [[NSError alloc] initWithDomain:ZumoKitDomain
                                   code:-101
                              userInfo:@{@"type": errorType}]
    );
}

- (void)rejectPromiseWithNSError:(RCTPromiseRejectBlock)reject error:(NSError *)error
{
    [self rejectPromiseWith:reject
                  errorType:error.userInfo[ZKZumoKitErrorTypeKey]
                  errorCode:error.userInfo[ZKZumoKitErrorCodeKey]
                  errorMessage:error.localizedDescription];
}

- (void)rejectPromiseWithMessage:(RCTPromiseRejectBlock)reject errorMessage:(NSString *)errorMessage
{
    [self rejectPromiseWith:reject
                errorType:ZKZumoKitErrorTypeINVALIDREQUESTERROR
                errorCode:ZKZumoKitErrorCodeUNKNOWNERROR
                errorMessage:errorMessage];
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

RCT_EXPORT_METHOD(init:(NSString *)apiKey apiRoot:(NSString *)apiRoot txServiceUrl:(NSString *)txServiceUrl)
{
    _zumoKit = [[ZumoKit alloc] initWithApiKey:apiKey apiRoot:apiRoot txServiceUrl:txServiceUrl];

    [_zumoKit addStateListener:self];

}

RCT_EXPORT_METHOD(getUser:(NSString *)token resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_zumoKit getUser:token completion:^(ZKUser * _Nullable user, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            self->_user = user;

            resolve(@{
                @"id": [user getId],
                @"hasWallet": @([user hasWallet])
            });

        }];

    } @catch (NSException *exception) {

        [self rejectPromiseWithMessage:reject errorMessage:exception.description];

    }

}

 RCT_EXPORT_METHOD(getHistoricalExchangeRates:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
 {

     @try {

         [_zumoKit getHistoricalExchangeRates:^(ZKHistoricalExchangeRates _Nullable historicalRates, NSError * _Nullable error) {

             if(error != nil) {
                 [self rejectPromiseWithNSError:reject error:error];
                 return;
             }

             resolve([self mapHistoricalExchangeRates:historicalRates]);

         }];

     } @catch (NSException *exception) {

         [self rejectPromiseWithMessage:reject errorMessage:exception.description];

     }

 }

# pragma mark - Wallet Management


RCT_EXPORT_METHOD(createWallet:(NSString *)mnemonic password:(NSString *)password resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_user createWallet:mnemonic password:password completion:^(ZKWallet * _Nullable wallet, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            self->_wallet = wallet;

            resolve(@(YES));

        }];

    } @catch (NSException *exception) {

        [self rejectPromiseWithMessage:reject errorMessage:exception.description];

    }

}

RCT_EXPORT_METHOD(revealMnemonic:(NSString *)password resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_user revealMnemonic:password completion:^(NSString * _Nullable mnemonic, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve(mnemonic);

        }];

    } @catch (NSException *exception) {

        [self rejectPromiseWithMessage:reject errorMessage:exception.description];

    }

}

RCT_EXPORT_METHOD(unlockWallet:(NSString *)password resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_user unlockWallet:password completion:^(ZKWallet * _Nullable wallet, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            self->_wallet = wallet;

            resolve(@(YES));

        }];

    } @catch (NSException *exception) {

        [self rejectPromiseWithMessage:reject errorMessage:exception.description];

    }

}

RCT_EXPORT_METHOD(submitTransaction:(NSDictionary *)composedTransactionData resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        NSString * signedTransaction = composedTransactionData[@"signedTransaction"];
        ZKAccount *account = [self unboxAccount:composedTransactionData[@"account"]];
        NSString * destination = (composedTransactionData[@"destination"] == [NSNull null]) ? NULL : composedTransactionData[@"destination"];
        NSString * value = (composedTransactionData[@"value"] == [NSNull null]) ? NULL : composedTransactionData[@"value"];
        NSString * data = (composedTransactionData[@"data"] == [NSNull null]) ? NULL : composedTransactionData[@"data"];
        NSString * fee = composedTransactionData[@"fee"];

        ZKComposedTransaction * composedTransaction = [[ZKComposedTransaction alloc] initWithSignedTransaction:signedTransaction account:account destination:destination value:value data:data fee:fee];

        [_wallet submitTransaction:composedTransaction completion:^(ZKTransaction * _Nullable transaction, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve([self mapTransaction:transaction]);

        }];

    } @catch (NSException *exception) {

       [self rejectPromiseWithMessage:reject errorMessage:exception.description];

   }

}


RCT_EXPORT_METHOD(composeEthTransaction:(NSString *)accountId gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)to value:(NSString *)value data:(NSString *)data nonce:(NSString *)nonce resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_wallet composeEthTransaction:accountId gasPrice:gasPrice gasLimit:gasLimit to:to value:value data:data nonce:nonce ? @([nonce integerValue]) : NULL completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve([self mapComposedTransaction:transaction]);

        }];

    } @catch (NSException *exception) {

       [self rejectPromiseWithMessage:reject errorMessage:exception.description];

   }

}

RCT_EXPORT_METHOD(composeBtcTransaction:(NSString *)accountId changeAccountId:(NSString *)changeAccountId to:(NSString *)to value:(NSString *)value feeRate:(NSString *)feeRate resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_wallet composeBtcTransaction:accountId changeAccountId:changeAccountId to:to value:value feeRate:feeRate completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve([self mapComposedTransaction:transaction]);

        }];

    } @catch (NSException *exception) {

        [self rejectPromiseWithMessage:reject errorMessage:exception.description];

    }

}

RCT_EXPORT_METHOD(composeExchange:(NSString *)depositAccountId withdrawAccountId:(NSString *)withdrawAccountId exchangeRate:(NSDictionary *)exchangeRate exchangeSettings:(NSDictionary *)exchangeSettings value:(NSString *)value resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {
        ZKExchangeRate *rate = [self unboxExchangeRate:exchangeRate];
        ZKExchangeSettings *fees = [self unboxExchangeSettings:exchangeSettings];

        [_wallet composeExchange:depositAccountId withdrawAccountId:withdrawAccountId exchangeRate:rate exchangeSettings:fees value:value completion:^(ZKComposedExchange * _Nullable exchange, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve([self mapComposedExchange:exchange]);

        }];

    } @catch (NSException *exception) {

        [self rejectPromiseWithMessage:reject errorMessage:exception.description];

    }

}

RCT_EXPORT_METHOD(submitExchange:(NSDictionary *)composedExchangeData resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        NSString * signedTransaction = composedExchangeData[@"signedTransaction"];
        ZKAccount *depositAccount = [self unboxAccount:composedExchangeData[@"depositAccount"]];
        ZKAccount *withdrawAccount = [self unboxAccount:composedExchangeData[@"withdrawAccount"]];
        ZKExchangeRate *exchangeRate = [self unboxExchangeRate:composedExchangeData[@"exchangeRate"]];
        ZKExchangeSettings *exchangeSettings = [self unboxExchangeSettings:composedExchangeData[@"exchangeSettings"]];
        NSString * exchangeAddress = composedExchangeData[@"exchangeAddress"];
        NSString * value = composedExchangeData[@"value"];
        NSString * returnValue = composedExchangeData[@"returnValue"];
        NSString * depositFee = composedExchangeData[@"depositFee"];
        NSString * exchangeFee = composedExchangeData[@"exchangeFee"];
        NSString * withdrawFee = composedExchangeData[@"withdrawFee"];

        ZKComposedExchange * composedExchange = [[ZKComposedExchange alloc] initWithSignedTransaction:signedTransaction depositAccount:depositAccount withdrawAccount:withdrawAccount exchangeRate:exchangeRate exchangeSettings:exchangeSettings exchangeAddress:exchangeAddress value:value returnValue:returnValue depositFee:depositFee exchangeFee:exchangeFee withdrawFee:withdrawFee];

       [_wallet submitExchange:composedExchange completion:^(ZKExchange * _Nullable exchange, NSError * _Nullable error) {

           if(error != nil) {
               [self rejectPromiseWithNSError:reject error:error];
               return;
           }

           resolve([self mapExchange:exchange]);

       }];

    } @catch (NSException *exception) {

       [self rejectPromiseWithMessage:reject errorMessage:exception.description];

   }

}


# pragma mark - Wallet Recovery


RCT_EXPORT_METHOD(isRecoveryMnemonic:(NSString *)mnemonic resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject) {

    @try {
        BOOL validation = [_user isRecoveryMnemonic:mnemonic];
        resolve(@(validation));
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }

}

RCT_EXPORT_METHOD(recoverWallet:(NSString *)mnemonic password:(NSString *)password resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_user recoverWallet:mnemonic password:password completion:^(ZKWallet * _Nullable wallet, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            self->_wallet = wallet;

            resolve(@(YES));

        }];

    } @catch (NSException *exception) {

        [self rejectPromiseWithMessage:reject errorMessage:exception.description];

    }

}

#pragma mark - Account Management

RCT_EXPORT_METHOD(getAccount:(NSString *)symbol network:(NSString *)network type:(NSString *)type resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        ZKNetworkType networkType = [self  unboxNetworkType:network];
        ZKAccountType accountType = [self unboxAccountType:type];

        ZKAccount * account = [_user getAccount:symbol network:networkType type:accountType];

        if(account) {
            resolve([self mapAccount:account]);
        } else {
            [self rejectPromiseWith:reject
                          errorType:ZKZumoKitErrorTypeINVALIDREQUESTERROR
                          errorCode:ZKZumoKitErrorCodeACCOUNTNOTFOUND
                       errorMessage:@"Account not found."];
        }

    } @catch (NSException *exception) {

        [self rejectPromiseWithMessage:reject errorMessage:exception.description];

    }

}

# pragma mark - Utility & Helpers


RCT_EXPORT_METHOD(isValidEthAddress:(NSString *)address resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    BOOL isValid = [[_zumoKit utils] isValidEthAddress:address];
    resolve(@(isValid));
}

RCT_EXPORT_METHOD(isValidBtcAddress:(NSString *)address network:(NSString *)network resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    ZKNetworkType networkType = ZKNetworkTypeMAINNET;
    if([network isEqualToString:@"TESTNET"]) {
        networkType = ZKNetworkTypeTESTNET;
    }

    BOOL isValid = [[_zumoKit utils] isValidBtcAddress:address network:networkType];
    resolve(@(isValid));
}

RCT_EXPORT_METHOD(ethToGwei:(NSString *)eth resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *gwei = [[_zumoKit utils] ethToGwei:eth];
    resolve(gwei);
}

RCT_EXPORT_METHOD(gweiToEth:(NSString *)gwei resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *eth = [[_zumoKit utils] gweiToEth:gwei];
    resolve(eth);
}

RCT_EXPORT_METHOD(ethToWei:(NSString *)eth resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *wei = [[_zumoKit utils] ethToWei:eth];
    resolve(wei);
}

RCT_EXPORT_METHOD(weiToEth:(NSString *)wei resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *eth = [[_zumoKit utils] weiToEth:wei];
    resolve(eth);
}

RCT_EXPORT_METHOD(generateMnemonic:(int)wordLength resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *mnemonic = [[_zumoKit utils] generateMnemonic:wordLength];
    resolve(mnemonic);
}

RCT_EXPORT_METHOD(maxSpendableEth:(NSString *)accountId gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *max = [_wallet maxSpendableEth:accountId gasPrice:gasPrice gasLimit:gasLimit];
    resolve(max);
}

RCT_EXPORT_METHOD(maxSpendableBtc:(NSString *)accountId to:(NSString *)to feeRate:(NSString *)feeRate resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *max = [_wallet maxSpendableBtc:accountId to:to feeRate:feeRate];
    resolve(max);
}

RCT_EXPORT_METHOD(clear:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    _user = NULL;
    _wallet = NULL;
    resolve(@(YES));
}

#pragma mark - Mapping

- (NSDictionary *)mapState:(ZKState *)state {

    return @{
        @"accounts": [self mapAccounts:[state accounts]],
        @"transactions": [self mapTransactions:[state transactions]],
        @"exchanges": [self mapExchanges:[state exchanges]],
        @"exchangeRates": [self mapExchangeRatesDict:[state exchangeRates]],
        @"exchangeSettings": [self mapExchangeSettingsDict:[state exchangeSettings]],
        @"feeRates": [self mapFeeRates:[state feeRates]]
    };

}

- (NSString *)mapNetworkType:(ZKNetworkType)network {

    switch (network) {
        case ZKNetworkTypeMAINNET:
            return @"MAINNET";

        case ZKNetworkTypeROPSTEN:
            return @"ROPSTEN";

        case ZKNetworkTypeRINKEBY:
            return @"RINKEBY";

        case ZKNetworkTypeGOERLI:
            return @"GOERLI";

        case ZKNetworkTypeKOVAN:
            return @"KOVAN";

        default:
            return @"TESTNET";

    }

}


- (NSString *)mapAccountType:(ZKAccountType)accountType {

    switch (accountType) {
        case ZKAccountTypeCOMPATIBILITY:
            return @"COMPATIBILITY";

        case ZKAccountTypeSEGWIT:
            return @"SEGWIT";

        default:
            return @"STANDARD";

    }

}

- (NSDictionary *)mapAccount:(ZKAccount *)account {

    NSDictionary *dict = @{
        @"id": [account id],
        @"path": [account path],
        @"symbol": [account symbol],
        @"coin": [account coin],
        @"address": [account address],
        @"balance": [account balance],
        @"nonce": [account nonce] ? [account nonce] : [NSNull null],
        @"network": [self mapNetworkType:[account network]],
        @"type": [self mapAccountType:[account type]],
        @"version": [[NSNumber alloc] initWithChar:[account version]]
    };

    return dict;

}

- (NSArray<NSDictionary *> *)mapAccounts:(NSArray<ZKAccount *>*)accounts {

    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];

    [accounts enumerateObjectsUsingBlock:^(ZKAccount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        [mapped addObject:[self mapAccount:obj]];

    }];

    return mapped;

}


- (NSDictionary *)mapComposedTransaction:(ZKComposedTransaction *)composedTransaction {

    NSMutableDictionary *dict = [@{
        @"signedTransaction": [composedTransaction signedTransaction],
        @"account": [self mapAccount:[composedTransaction account]],
        @"destination": [composedTransaction destination]  ? [composedTransaction destination] :  [NSNull null],
        @"value": [composedTransaction value] ? [composedTransaction value] :  [NSNull null],
        @"data": [composedTransaction data] ? [composedTransaction data] :  [NSNull null],
        @"fee": [composedTransaction fee]
    } mutableCopy];

    return dict;
}


- (NSDictionary *)mapComposedExchange:(ZKComposedExchange *)exchange {
    return @{
         @"signedTransaction": [exchange signedTransaction],
         @"depositAccount": [self mapAccount:[exchange depositAccount]],
         @"withdrawAccount": [self mapAccount:[exchange withdrawAccount]],
         @"exchangeRate": [self mapExchangeRate:[exchange exchangeRate]],
         @"exchangeSettings": [self mapExchangeSettings:[exchange exchangeSettings]],
         @"exchangeAddress": [exchange exchangeAddress],
         @"value": [exchange value],
         @"returnValue": [exchange returnValue],
         @"depositFee": [exchange depositFee],
         @"exchangeFee": [exchange exchangeFee],
         @"withdrawFee": [exchange withdrawFee],
    };
}


- (NSString *)mapTransactionType:(ZKTransactionType)transacationType {

    switch (transacationType) {
        case ZKTransactionTypeEXCHANGE:
            return @"EXCHANGE";

        default:
            return @"NORMAL";

    }

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
        @"type": [self mapTransactionType:[transaction type]],
        @"direction": [transaction direction] == ZKTransactionDirectionOUTGOING ? @"OUTGOING" : @"INCOMING",
        @"txHash": [transaction txHash],
        @"accountId": [transaction accountId],
        @"symbol": [transaction symbol],
        @"coin": [transaction coin],
        @"network": [self mapNetworkType:[transaction network]],
        @"status": status,
        @"fromAddress": [transaction fromAddress],
        @"toAddress": [transaction toAddress],
        @"value": [transaction value],
        @"timestamp": @([transaction timestamp])
    } mutableCopy];

    if([transaction nonce]) dict[@"nonce"] = [transaction nonce];
    if([transaction fromUserId]) dict[@"fromUserId"] = [transaction fromUserId];
    if([transaction toUserId]) dict[@"toUserId"] = [transaction toUserId];
    if([transaction data]) dict[@"data"] = [transaction data];
    if([transaction gasPrice]) dict[@"gasPrice"] = [transaction gasPrice];
    if([transaction gasLimit]) dict[@"gasLimit"] = [transaction gasLimit];
    if([transaction submittedAt]) dict[@"submittedAt"] = [transaction submittedAt];
    if([transaction confirmedAt]) dict[@"confirmedAt"] = [transaction confirmedAt];
    if([transaction fiatValue]) dict[@"fiatValue"] = [transaction fiatValue];
    if([transaction fee]) dict[@"fee"] = [transaction fee];
    if([transaction fiatFee]) dict[@"fiatFee"] = [transaction fiatFee];

    return dict;
}

- (NSDictionary *)mapExchange:(ZKExchange *)exchange {
    return @{
         @"id": [exchange id],
         @"status": [exchange status],
         @"depositCurrency": [exchange depositCurrency],
         @"depositAccountId": [exchange depositAccountId],
         @"depositTransactionId": [exchange depositTransactionId] ? [exchange depositTransactionId] : [NSNull null],
         @"withdrawCurrency": [exchange withdrawCurrency],
         @"withdrawAccountId": [exchange withdrawAccountId],
         @"withdrawTransactionId": [exchange withdrawTransactionId] ? [exchange withdrawTransactionId] : [NSNull null],
         @"amount": [exchange amount],
         @"depositFee": [exchange depositFee] ? [exchange depositFee] : [NSNull null],
         @"returnAmount": [exchange returnAmount],
         @"exchangeFee": [exchange exchangeFee],
         @"withdrawFee": [exchange withdrawFee],
         @"exchangeRate": [self mapExchangeRate:[exchange exchangeRate]],
         @"exchangeRates": [self mapExchangeRatesDict:[exchange exchangeRates]],
         @"exchangeSettings": [self mapExchangeSettings:[exchange exchangeSettings]],
         @"submittedAt": [exchange submittedAt],
         @"confirmedAt": [exchange confirmedAt] ? [exchange confirmedAt] : [NSNull null],
    };
}

- (NSDictionary *)mapFeeRates:(NSDictionary<NSString *, ZKFeeRates *>*)feeRates {

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    [feeRates enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ZKFeeRates * _Nonnull obj, BOOL * _Nonnull stop) {
        dict[key] = @{
            @"slow": [obj slow],
            @"average": [obj average],
            @"fast": [obj fast]
        };
    }];

    return dict;
}

- (NSDictionary *)mapExchangeRate:(ZKExchangeRate *)exchangeRates {

    return @{
        @"id": [exchangeRates id],
        @"depositCurrency": [exchangeRates depositCurrency],
        @"withdrawCurrency": [exchangeRates withdrawCurrency],
        @"value": [exchangeRates value],
        @"validTo": [NSNumber numberWithLongLong:[exchangeRates validTo]],
        @"timestamp": [NSNumber numberWithLongLong:[exchangeRates timestamp]]
    };
}

- (NSDictionary *)mapExchangeRatesDict:(NSDictionary<NSString *, NSDictionary<NSString *, ZKExchangeRate *> *> *)exchangeRates {

    NSMutableDictionary *outerDict = [[NSMutableDictionary alloc] init];

    [exchangeRates enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull outerKey, NSDictionary<NSString *, ZKExchangeRate *> * _Nonnull outerObj, BOOL * _Nonnull stop) {

        NSMutableDictionary *innerDict = [[NSMutableDictionary alloc] init];

        [outerObj enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull innerKey, ZKExchangeRate * _Nonnull obj, BOOL * _Nonnull stop) {
            innerDict[innerKey] = [self mapExchangeRate:obj];
        }];

        outerDict[outerKey] = innerDict;
    }];

    return outerDict;
}

 - (NSDictionary *)mapHistoricalExchangeRates:(ZKHistoricalExchangeRates) historicalRates {

     NSMutableDictionary *rates = [[NSMutableDictionary alloc] init];

     [historicalRates enumerateKeysAndObjectsUsingBlock:^(
             NSString * _Nonnull timeInterval,
             NSDictionary<NSString *, NSDictionary<NSString *, NSArray<ZKExchangeRate *> *> *> * _Nonnull exchangeRates,
             BOOL * _Nonnull stop) {

         NSMutableDictionary *outerDict = [[NSMutableDictionary alloc] init];

         [exchangeRates enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull outerKey, NSDictionary<NSString *, NSArray<ZKExchangeRate *> *> * _Nonnull outerObj, BOOL * _Nonnull stop) {

             NSMutableDictionary *innerDict = [[NSMutableDictionary alloc] init];

             [outerObj enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull innerKey, NSArray<ZKExchangeRate *> * _Nonnull array, BOOL * _Nonnull stop) {

                NSMutableArray<ZKExchangeRate *> *mapped = [[NSMutableArray alloc] init];

                [array enumerateObjectsUsingBlock:^(
                        ZKExchangeRate * _Nonnull obj,
                        NSUInteger idx,
                        BOOL * _Nonnull stop) {

                    [mapped addObject:[self mapExchangeRate:obj]];

                }];

                 innerDict[innerKey] = mapped;
             }];

             outerDict[outerKey] = innerDict;
         }];

         rates[timeInterval] = outerDict;
     }];

     return rates;
 }


- (NSDictionary *)mapExchangeSettings:(ZKExchangeSettings *)exchangeSettings {

    NSMutableDictionary *depositAddress = [[NSMutableDictionary alloc] init];

    [[exchangeSettings depositAddress] enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        ZKNetworkType networkType = (ZKNetworkType) key;
        depositAddress[[self mapNetworkType:networkType]] = value;
    }];

    return @{
        @"id": [exchangeSettings id],
        @"depositAddress": depositAddress,
        @"depositCurrency": [exchangeSettings depositCurrency],
        @"withdrawCurrency": [exchangeSettings withdrawCurrency],
        @"minExchangeAmount": [exchangeSettings minExchangeAmount],
        @"feeRate": [exchangeSettings feeRate],
        @"depositFeeRate": [exchangeSettings depositFeeRate],
        @"withdrawFee": [exchangeSettings withdrawFee],
        @"timestamp": [NSNumber numberWithLongLong:[exchangeSettings timestamp]]
    };
}

- (NSDictionary *)mapExchangeSettingsDict:(NSDictionary<NSString *, NSDictionary<NSString *, ZKExchangeSettings *> *> *)exchangeSettings {

    NSMutableDictionary *outerDict = [[NSMutableDictionary alloc] init];

    [exchangeSettings enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull outerKey, NSDictionary<NSString *, ZKExchangeSettings *> * _Nonnull outerObj, BOOL * _Nonnull stop) {

        NSMutableDictionary *innerDict = [[NSMutableDictionary alloc] init];

        [outerObj enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull innerKey, ZKExchangeSettings * _Nonnull obj, BOOL * _Nonnull stop) {
            innerDict[innerKey] = [self mapExchangeSettings: obj];
        }];

        outerDict[outerKey] = innerDict;
    }];

    return outerDict;
}

- (NSArray<NSDictionary *> *)mapTransactions:(NSArray<ZKTransaction *>*)transactions {

    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];

    [transactions enumerateObjectsUsingBlock:^(ZKTransaction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mapped addObject:[self mapTransaction:obj]];
    }];

    return mapped;

}

- (NSArray<NSDictionary *> *)mapExchanges:(NSArray<ZKExchange *>*)exchanges {

    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];

    [exchanges enumerateObjectsUsingBlock:^(ZKExchange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mapped addObject:[self mapExchange:obj]];
    }];

    return mapped;

}

#pragma mark - Unboxing

- (ZKNetworkType)unboxNetworkType:(NSString *)network {
    if ([network isEqualToString:@"MAINNET"])
        return ZKNetworkTypeMAINNET;
    else if ([network isEqualToString:@"ROPSTEN"])
        return ZKNetworkTypeROPSTEN;
    else if ([network isEqualToString:@"RINKEBY"])
        return ZKNetworkTypeRINKEBY;
    else if ([network isEqualToString:@"GOERLI"])
        return ZKNetworkTypeGOERLI;
    else if ([network isEqualToString:@"KOVAN"])
        return ZKNetworkTypeKOVAN;
    else if ([network isEqualToString:@"TESTNET"])
        return ZKNetworkTypeTESTNET;
    else {
        @throw [NSException exceptionWithName:ZKZumoKitErrorCodeINVALIDNETWORKTYPE
                                       reason:@"Network type not supported."
                                     userInfo:nil];
    }
}

- (ZKAccountType)unboxAccountType:(NSString *)type {
    if ([type isEqualToString:@"STANDARD"])
        return ZKAccountTypeSTANDARD;
    else if ([type isEqualToString:@"COMPATIBILITY"])
        return ZKAccountTypeCOMPATIBILITY;
    else if ([type isEqualToString:@"SEGWIT"])
        return ZKAccountTypeSEGWIT;
    else {
        @throw [NSException exceptionWithName:ZKZumoKitErrorCodeINVALIDACCOUNTTYPE
                                       reason:@"Account type not supported."
                                     userInfo:nil];
    }
}

- (ZKAccount *)unboxAccount:(NSDictionary *)accountData {
    NSString *accountId = accountData[@"id"];
    NSString *accountPath = accountData[@"path"];
    NSString *accountSymbol = accountData[@"symbol"];
    NSString *accountCoin = accountData[@"coin"];
    NSString *accountAddress = accountData[@"address"];
    NSString *accountBalance = accountData[@"balance"];
    NSNumber *accountNonce = (accountData[@"nonce"] == [NSNull null]) ? NULL : accountData[@"nonce"];
    NSNumber *accountVersion = accountData[@"version"];
    ZKNetworkType accountNetwork = [self unboxNetworkType:accountData[@"network"]];
    ZKAccountType accountType = [self unboxAccountType:accountData[@"type"]];

    return [[ZKAccount alloc] initWithId:accountId path:accountPath symbol:accountSymbol coin:accountCoin address:accountAddress balance:accountBalance nonce:accountNonce network:accountNetwork type:accountType version:accountVersion.charValue];
}

- (ZKExchangeRate *)unboxExchangeRate:(NSDictionary *)exchangeRate {
    NSString *exchangeRateId = exchangeRate[@"id"];
    NSString *exchangeRateDepositCurrency = exchangeRate[@"depositCurrency"];
    NSString *exchangeRateWithdrawCurrency = exchangeRate[@"withdrawCurrency"];
    NSString *exchangeRateValue = exchangeRate[@"value"];
    NSNumber *exchangeRateValidTo = exchangeRate[@"validTo"];
    NSNumber *exchangeRateTimestamp = exchangeRate[@"timestamp"];

    return [[ZKExchangeRate alloc] initWithId:exchangeRateId depositCurrency:exchangeRateDepositCurrency withdrawCurrency:exchangeRateWithdrawCurrency value:exchangeRateValue validTo:exchangeRateValidTo.longLongValue timestamp:exchangeRateTimestamp.longLongValue];
}


- (ZKExchangeSettings *)unboxExchangeSettings:(NSDictionary *)exchangeSettings {
    NSString *exchangeSettingsId = exchangeSettings[@"id"];
    NSString *exchangeSettingsDepositCurrency = exchangeSettings[@"depositCurrency"];
    NSString *exchangeSettingsWithdrawCurrency = exchangeSettings[@"withdrawCurrency"];
    NSString *minExchangeAmount = exchangeSettings[@"minExchangeAmount"];
    NSString *exchangeSettingsFeeRate = exchangeSettings[@"feeRate"];
    NSString *exchangeSettingsDepositFeeRate = exchangeSettings[@"depositFeeRate"];
    NSString *exchangeSettingsWithdrawFee = exchangeSettings[@"withdrawFee"];
    NSNumber *exchangeSettingsTimestamp = exchangeSettings[@"timestamp"];

    NSMutableDictionary *depositAddress = [[NSMutableDictionary alloc] init];

    NSDictionary *depositAddressMap = exchangeSettings[@"depositAddress"];
    [depositAddressMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        ZKNetworkType networkType = [self unboxNetworkType:key];
        depositAddress[@(networkType)] = value;
    }];

    return [[ZKExchangeSettings alloc] initWithId:exchangeSettingsId depositAddress:depositAddress depositCurrency:exchangeSettingsDepositCurrency withdrawCurrency:exchangeSettingsWithdrawCurrency minExchangeAmount:minExchangeAmount feeRate:exchangeSettingsFeeRate depositFeeRate:exchangeSettingsDepositFeeRate withdrawFee:exchangeSettingsWithdrawFee timestamp:exchangeSettingsTimestamp.longLongValue];
}

@end
