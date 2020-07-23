
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

RCT_EXPORT_METHOD(getUser:(NSString *)tokenSet resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_zumoKit getUser:tokenSet completion:^(ZKUser * _Nullable user, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(isModulrCustomer:(NSString *)network resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        if ([_user isModulrCustomer:network]){
            resolve(@(YES));
        } else {
            resolve(@(NO));
        }
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(makeModulrCustomer:(NSString *)network data:(NSDictionary *)data resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        NSString *firstName = data[@"firstName"];
        NSString *middleName = data[@"middleName"];
        NSString *lastName = data[@"lastName"];
        NSString *dateOfBirth = data[@"dateOfBirth"];
        NSString *email = data[@"email"];
        NSString *phone = data[@"phone"];
        NSString *addressLine1 = data[@"addressLine1"];
        NSString *addressLine2 = data[@"addressLine2"];
        NSString *country = data[@"country"];
        NSString *postCode = data[@"postCode"];
        NSString *postTown = data[@"postTown"];

        [_user makeModulrCustomer:network firstName:firstName middleName:middleName lastName:lastName dateOfBirth:dateOfBirth email:email phone:phone addressLine1:addressLine1 addressLine2:addressLine2 country:country postCode:postCode postTown:postTown completion:^(NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve(@(YES));
        }];
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(createFiatAccount:(NSString *)network currencyCode:(NSString *)currencyCode resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user createFiatAccount:network currencyCode:currencyCode completion:^(ZKAccount * _Nullable account, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve([self mapAccount:account]);
        }];
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}


RCT_EXPORT_METHOD(getNominatedAccountFiatPoperties:(NSString *)accountId resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user getNominatedAccountFiatProperties:accountId completion:^(ZKAccountFiatProperties * _Nullable accountFiatProperties, NSError * _Nullable error) {

            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve(accountFiatProperties ? [self mapAccountFiatProperties:accountFiatProperties] : nil);
        }];
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(getAccountTransactions:(NSString *)accountId  resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        resolve([self mapTransactions:[_user getAccountTransactions:accountId]]);
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(submitTransaction:(NSDictionary *)composedTransactionData resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        NSString * type = composedTransactionData[@"type"];
        NSString * signedTransaction = (composedTransactionData[@"signedTransaction"] == [NSNull null]) ? NULL : composedTransactionData[@"signedTransaction"];
        ZKAccount *account = [self unboxAccount:composedTransactionData[@"account"]];
        NSString * destination = (composedTransactionData[@"destination"] == [NSNull null]) ? NULL : composedTransactionData[@"destination"];
        NSString * amount = (composedTransactionData[@"amount"] == [NSNull null]) ? NULL : composedTransactionData[@"amount"];
        NSString * data = (composedTransactionData[@"data"] == [NSNull null]) ? NULL : composedTransactionData[@"data"];
        NSString * fee = composedTransactionData[@"fee"];
        NSString * nonce = composedTransactionData[@"nonce"];

        ZKComposedTransaction * composedTransaction = [[ZKComposedTransaction alloc] initWithType:type signedTransaction:signedTransaction account:account destination:destination amount:amount data:data fee:fee nonce:nonce];

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


RCT_EXPORT_METHOD(composeEthTransaction:(NSString *)accountId gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit destination:(NSString *)destination amount:(NSString *)amount data:(NSString *)data nonce:(NSString *)nonce sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_wallet composeEthTransaction:accountId gasPrice:gasPrice gasLimit:gasLimit destination:destination amount:amount data:data nonce:nonce ? @([nonce integerValue]) : NULL sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeBtcTransaction:(NSString *)accountId changeAccountId:(NSString *)changeAccountId destination:(NSString *)destination amount:(NSString *)amount feeRate:(NSString *)feeRate sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_wallet composeBtcTransaction:accountId changeAccountId:changeAccountId destination:destination amount:amount feeRate:feeRate sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeInternalFiatTransaction:(NSString *)fromAccountId toAccountId:(NSString *)toAccountId amount:(NSString *)amount sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_wallet composeInternalFiatTransaction:fromAccountId toAccountId:toAccountId amount:amount sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeTransactionToNominatedAccount:(NSString *)fromAccountId amount:(NSString *)amount sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {

        [_wallet composeTransactionToNominatedAccount:fromAccountId amount:amount sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeExchange:(NSString *)depositAccountId withdrawAccountId:(NSString *)withdrawAccountId exchangeRate:(NSDictionary *)exchangeRate exchangeSettings:(NSDictionary *)exchangeSettings value:(NSString *)value sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{

    @try {
        ZKExchangeRate *rate = [self unboxExchangeRate:exchangeRate];
        ZKExchangeSettings *fees = [self unboxExchangeSettings:exchangeSettings];

        [_wallet composeExchange:depositAccountId withdrawAccountId:withdrawAccountId exchangeRate:rate exchangeSettings:fees value:value sendMax:sendMax completion:^(ZKComposedExchange * _Nullable exchange, NSError * _Nullable error) {

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
        NSString *nonce = (composedExchangeData[@"nonce"] == [NSNull null]) ? NULL : composedExchangeData[@"nonce"];

        ZKComposedExchange * composedExchange = [[ZKComposedExchange alloc] initWithSignedTransaction:signedTransaction depositAccount:depositAccount withdrawAccount:withdrawAccount exchangeRate:exchangeRate exchangeSettings:exchangeSettings exchangeAddress:exchangeAddress value:value returnValue:returnValue depositFee:depositFee exchangeFee:exchangeFee withdrawFee:withdrawFee nonce:nonce];

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
        ZKAccount * account = [_user getAccount:symbol network:network type:type];

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
    BOOL isValid = [[_zumoKit utils] isValidBtcAddress:address network:network];
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

- (NSDictionary *)mapAccountFiatProperties:(ZKAccountFiatProperties *)accountFiatProperties {

    return @{
        @"accountNumber": accountFiatProperties.accountNumber ? accountFiatProperties.accountNumber : [NSNull null],
        @"sortCode": accountFiatProperties.sortCode ? accountFiatProperties.sortCode : [NSNull null],
        @"bic": accountFiatProperties.bic ? accountFiatProperties.bic : [NSNull null],
        @"iban": accountFiatProperties.iban ? accountFiatProperties.iban : [NSNull null],
        @"customerName": accountFiatProperties.customerName ? accountFiatProperties.customerName : [NSNull null]
    };

}

- (NSDictionary *)mapAccount:(ZKAccount *)account {

    NSMutableDictionary *cryptoProperties = [[NSMutableDictionary alloc] init];
    if ([account cryptoProperties]){
        cryptoProperties[@"path"] = account.cryptoProperties.path;
        cryptoProperties[@"address"] = account.cryptoProperties.address;
        cryptoProperties[@"nonce"] = account.cryptoProperties.nonce ? account.cryptoProperties.nonce : [NSNull null];
        cryptoProperties[@"utxoPool"] = account.cryptoProperties.utxoPool ? account.cryptoProperties.utxoPool : [NSNull null];
        cryptoProperties[@"version"] = [[NSNumber alloc] initWithChar:[account.cryptoProperties version]];
    }

    NSDictionary *dict = @{
        @"id": [account id],
        @"currencyType": [account currencyType],
        @"currencyCode": [account currencyCode],
        @"network": [account network],
        @"type": [account type],
        @"balance": [account balance],
        @"cryptoProperties": [account cryptoProperties] ? cryptoProperties : [NSNull null],
        @"fiatProperties": [account fiatProperties] ? [self mapAccountFiatProperties:account.fiatProperties] : [NSNull null]
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
        @"type": [composedTransaction type],
        @"signedTransaction": [composedTransaction signedTransaction] ? [composedTransaction signedTransaction] : [NSNull null],
        @"account": [self mapAccount:[composedTransaction account]],
        @"destination": [composedTransaction destination] ? [composedTransaction destination] : [NSNull null],
        @"amount": [composedTransaction amount] ? [composedTransaction amount] : [NSNull null],
        @"data": [composedTransaction data] ? [composedTransaction data] : [NSNull null],
        @"fee": [composedTransaction fee],
        @"nonce": [composedTransaction nonce]
    } mutableCopy];

    return dict;
}


- (NSDictionary *)mapComposedExchange:(ZKComposedExchange *)exchange {
    return @{
        @"signedTransaction": [exchange signedTransaction] ? [exchange signedTransaction] : [NSNull null],
         @"depositAccount": [self mapAccount:[exchange depositAccount]],
         @"withdrawAccount": [self mapAccount:[exchange withdrawAccount]],
         @"exchangeRate": [self mapExchangeRate:[exchange exchangeRate]],
         @"exchangeSettings": [self mapExchangeSettings:[exchange exchangeSettings]],
         @"exchangeAddress": [exchange exchangeAddress] ? [exchange exchangeAddress] : [NSNull null],
         @"value": [exchange value],
         @"returnValue": [exchange returnValue],
         @"depositFee": [exchange depositFee],
         @"exchangeFee": [exchange exchangeFee],
         @"withdrawFee": [exchange withdrawFee],
         @"nonce": [exchange nonce] ? [exchange nonce] : [NSNull null]
    };
}

- (NSDictionary *)mapTransaction:(ZKTransaction *)transaction {
    NSMutableDictionary *cryptoProperties = [[NSMutableDictionary alloc] init];
    if ([transaction cryptoProperties]) {
        cryptoProperties[@"txHash"] = transaction.cryptoProperties.txHash ? transaction.cryptoProperties.txHash : [NSNull null];
        cryptoProperties[@"nonce"] = transaction.cryptoProperties.nonce ? transaction.cryptoProperties.nonce : [NSNull null];
        cryptoProperties[@"fromAddress"] = transaction.cryptoProperties.fromAddress;
        cryptoProperties[@"toAddress"] = transaction.cryptoProperties.toAddress ? transaction.cryptoProperties.toAddress : [NSNull null];
        cryptoProperties[@"data"] = transaction.cryptoProperties.data ? transaction.cryptoProperties.data : [NSNull null];
        cryptoProperties[@"gasPrice"] = transaction.cryptoProperties.gasPrice ? transaction.cryptoProperties.gasPrice : [NSNull null];
        cryptoProperties[@"gasLimit"] = transaction.cryptoProperties.gasLimit ? transaction.cryptoProperties.gasLimit : [NSNull null];
        cryptoProperties[@"fiatAmount"] = transaction.cryptoProperties.fiatAmount ? transaction.cryptoProperties.fiatAmount : [NSNull null];
        cryptoProperties[@"fiatFee"] = transaction.cryptoProperties.fiatFee ? transaction.cryptoProperties.fiatFee : [NSNull null];
    }

    NSMutableDictionary *fiatProperties = [[NSMutableDictionary alloc] init];
    if ([transaction fiatProperties]) {
        fiatProperties[@"fromFiatAccount"] = transaction.fiatProperties.fromFiatAccount ? [self mapAccountFiatProperties:transaction.fiatProperties.fromFiatAccount] : [NSNull null];
        fiatProperties[@"toFiatAccount"] = transaction.fiatProperties.toFiatAccount ? [self mapAccountFiatProperties:transaction.fiatProperties.toFiatAccount] : [NSNull null];
    }

    NSMutableDictionary *dict = [@{
        @"id": [transaction id],
        @"type": [transaction type],
        @"currencyCode": [transaction currencyCode],
        @"fromUserId": [transaction fromUserId] ? [transaction fromUserId] : [NSNull null],
        @"toUserId": [transaction toUserId] ? [transaction toUserId] : [NSNull null],
        @"fromAccountId": [transaction fromAccountId] ? [transaction fromAccountId] : [NSNull null],
        @"toAccountId": [transaction toAccountId] ? [transaction toAccountId] : [NSNull null],
        @"network": [transaction network],
        @"status": [transaction status],
        @"amount": [transaction amount] ? [transaction amount] : [NSNull null],
        @"fee": [transaction fee] ? [transaction fee] : [NSNull null],
        @"nonce": [transaction nonce] ? [transaction nonce] : [NSNull null],
        @"cryptoProperties": [transaction cryptoProperties] ? cryptoProperties : [NSNull null],
        @"fiatProperties": [transaction fiatProperties] ? fiatProperties : [NSNull null],
        @"submittedAt": [transaction submittedAt] ? [transaction submittedAt] : [NSNull null],
        @"confirmedAt": [transaction confirmedAt] ? [transaction confirmedAt] : [NSNull null],
        @"timestamp": @([transaction timestamp])
    } mutableCopy];

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
         @"nonce": [exchange nonce] ? [exchange nonce] : [NSNull null],
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

    [[exchangeSettings depositAddress] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull network, NSString * _Nonnull address, BOOL * _Nonnull stop) {
        depositAddress[network] = address;
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

- (ZKAccount *)unboxAccount:(NSDictionary *)accountData {
    ZKAccountCryptoProperties *cryptoProperties;
    if (accountData[@"cryptoProperties"] != [NSNull null]){
        NSDictionary *cryptoPropertiesData = accountData[@"cryptoProperties"];

        NSString *accountAddress = cryptoPropertiesData[@"address"];
        NSString *accountPath = cryptoPropertiesData[@"path"];
        NSNumber *accountNonce = (cryptoPropertiesData[@"nonce"] == [NSNull null]) ? NULL : cryptoPropertiesData[@"nonce"];
        NSString *accountUtxoPool = (cryptoPropertiesData[@"utxoPool"] == [NSNull null]) ? NULL : cryptoPropertiesData[@"utxoPool"];
        NSNumber *accountVersion = cryptoPropertiesData[@"version"];

        cryptoProperties = [[ZKAccountCryptoProperties alloc] initWithAddress:accountAddress path:accountPath nonce:accountNonce utxoPool:accountUtxoPool version:accountVersion.charValue];
    }

    ZKAccountFiatProperties *fiatProperties;
    if (accountData[@"fiatProperties"] != [NSNull null]){
        NSDictionary *fiatPropertiesData = accountData[@"fiatProperties"];

        NSString *accountNumber = (fiatPropertiesData[@"accountNumber"] == [NSNull null]) ? NULL : fiatPropertiesData[@"accountNumber"];
        NSString *sortCode = (fiatPropertiesData[@"sortCode"] == [NSNull null]) ? NULL : fiatPropertiesData[@"sortCode"];
        NSString *bic = (fiatPropertiesData[@"bic"] == [NSNull null]) ? NULL : fiatPropertiesData[@"bic"];
        NSString *iban = (fiatPropertiesData[@"iban"] == [NSNull null]) ? NULL : fiatPropertiesData[@"iban"];
        NSString *customerName = (fiatPropertiesData[@"customerName"] == [NSNull null]) ? NULL : fiatPropertiesData[@"customerName"];

        fiatProperties = [[ZKAccountFiatProperties alloc] initWithAccountNumber:accountNumber sortCode:sortCode bic:bic iban:iban customerName:customerName];
    }

    NSString *accountId = accountData[@"id"];
    NSString *accountCurrencyType = accountData[@"currencyType"];
    NSString *accountCurrencyCode = accountData[@"currencyCode"];
    NSString *accountNetwork = accountData[@"network"];
    NSString *accountType = accountData[@"type"];
    NSString *accountBalance = accountData[@"balance"];

    return [[ZKAccount alloc] initWithId:accountId currencyType:accountCurrencyType currencyCode:accountCurrencyCode network:accountNetwork type:accountType balance:accountBalance cryptoProperties:cryptoProperties fiatProperties:fiatProperties];
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
    [depositAddressMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull network, NSString * _Nonnull address, BOOL * _Nonnull stop) {
        depositAddress[network] = address;
    }];

    return [[ZKExchangeSettings alloc] initWithId:exchangeSettingsId depositAddress:depositAddress depositCurrency:exchangeSettingsDepositCurrency withdrawCurrency:exchangeSettingsWithdrawCurrency minExchangeAmount:minExchangeAmount feeRate:exchangeSettingsFeeRate depositFeeRate:exchangeSettingsDepositFeeRate withdrawFee:exchangeSettingsWithdrawFee timestamp:exchangeSettingsTimestamp.longLongValue];
}

@end
