
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
    return @{ @"VERSION": [ZumoKit version] };
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

    //[_zumoKit addStateListener:self];

}

RCT_EXPORT_METHOD(auth:(NSString *)token resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
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

RCT_EXPORT_METHOD(composeEthTransaction:(NSString *)accountId gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)to value:(NSString *)value data:(NSString *)data nonce:(NSString *)nonce resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_wallet composeEthTransaction:accountId gasPrice:gasPrice gasLimit:gasLimit to:to value:value data:data nonce:nonce ? @([nonce integerValue]) : NULL completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            // TODO: return composed transaction
            //resolve([self mapTransaction:transaction]);
            resolve(@"YES");

        }];

    } @catch (NSException *exception) {

       [self rejectPromiseWithMessage:reject errorMessage:exception.description];

   }

}

RCT_EXPORT_METHOD(sendBtcTransaction:(NSString *)accountId changeAccountId:(NSString *)changeAccountId to:(NSString *)to value:(NSString *)value feeRate:(NSString *)feeRate resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_wallet composeBtcTransaction:accountId changeAccountId:changeAccountId to:to value:value feeRate:feeRate completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            // TODO: return composed transaction
            //resolve([self mapTransaction:transaction]);
            resolve(@"YES");

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

        ZKNetworkType networkType;
        if ([network isEqualToString:@"MAINNET"])
            networkType = ZKNetworkTypeMAINNET;
        else if ([network isEqualToString:@"ROPSTEN"])
            networkType = ZKNetworkTypeROPSTEN;
        else if ([network isEqualToString:@"RINKEBY"])
            networkType = ZKNetworkTypeRINKEBY;
        else if ([network isEqualToString:@"GOERLI"])
            networkType = ZKNetworkTypeGOERLI;
        else if ([network isEqualToString:@"KOVAN"])
            networkType = ZKNetworkTypeKOVAN;
        else if ([network isEqualToString:@"TESTNET"])
            networkType = ZKNetworkTypeTESTNET;
        else
            [self rejectPromiseWith:reject
                          errorType:ZKZumoKitErrorTypeINVALIDARGUMENTERROR
                          errorCode:ZKZumoKitErrorCodeINVALIDNETWORKTYPE
                       errorMessage:@"Network type not supported."];

        ZKAccountType accountType;
        if ([type isEqualToString:@"STANDARD"])
            accountType = ZKAccountTypeSTANDARD;
        else if ([type isEqualToString:@"COMPATIBILITY"])
            accountType = ZKAccountTypeCOMPATIBILITY;
        else if ([type isEqualToString:@"SEGWIT"])
            accountType = ZKAccountTypeSEGWIT;
        else
            [self rejectPromiseWith:reject
                          errorType:ZKZumoKitErrorTypeINVALIDARGUMENTERROR
                          errorCode:ZKZumoKitErrorCodeINVALIDACCOUNTTYPE
                       errorMessage:@"Account type not supported."];

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
        @"exchangeRates": [state exchangeRates],
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
        @"symbol": [account symbol] ? [account symbol] : @"",
        @"coin": [account coin],
        @"address": [account address],
        @"balance": [account balance],
        @"network": [self mapNetworkType:[account network]],
        @"type": [self mapAccountType:[account type]]
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
        @"type": [transaction type] == ZKTransactionDirectionOUTGOING ? @"OUTGOING" : @"INCOMING",
        @"txHash": [transaction txHash],
        @"accountId": [transaction accountId],
        @"symbol": [transaction symbol],
        @"coin": [transaction coin],
        @"network": [self mapNetworkType:[transaction network]],
        @"status": status,
        @"fromAddress": [transaction fromAddress],
        @"toAddress": [transaction toAddress],
        @"value": [transaction value],
        @"cost": [transaction cost],
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
    if([transaction fiatCost]) dict[@"fiatCost"] = [transaction fiatCost];

    return dict;
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

- (NSArray<NSDictionary *> *)mapTransactions:(NSArray<ZKTransaction *>*)transactions {

    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];

    [transactions enumerateObjectsUsingBlock:^(ZKTransaction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mapped addObject:[self mapTransaction:obj]];
    }];

    return mapped;

}


@end
