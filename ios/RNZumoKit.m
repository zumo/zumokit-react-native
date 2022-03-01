
#import "RNZumoKit.h"
#import <ZumoKit/ZumoKit.h>

@interface RNZumoKit ()

@property (strong, nonatomic) ZumoKit *zumoKit;

@property (strong, nonatomic) ZKUser *user;

@property (strong, nonatomic) ZKWallet *wallet;

@end

@implementation RNZumoKit

RCT_EXPORT_MODULE()

static id _instance;

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

-  (NSDictionary *)decimalLocale
{
    return [NSDictionary dictionaryWithObject:@"." forKey:NSLocaleDecimalSeparator];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_queue_create("money.zumo.zumokit", DISPATCH_QUEUE_SERIAL);
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

# pragma mark - Events

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"OnLog", @"AuxDataChanged", @"AccountDataChanged"];
}

- (void)onLog:(nonnull NSString *)message
{
    [self sendEventWithName:@"OnLog" body:message];
}


- (void)onChange
{
    [self sendEventWithName:@"AuxDataChanged" body:[NSNull null]];
}

- (void)onDataChange:(nonnull NSArray<ZKAccountDataSnapshot *> *)snapshots
{
    [self sendEventWithName:@"AccountDataChanged" body:[self mapAccountData:snapshots]];
}

# pragma mark - Logging

RCT_EXPORT_METHOD(setLogLevel:(NSString *)logLevel)
{
    
    [ZumoKit setLogLevel:logLevel];
}

RCT_EXPORT_METHOD(addLogListener:(NSString *)logLevel)
{
    [ZumoKit onLog:self logLevel:logLevel];
}

# pragma mark - Initialization + Authentication

RCT_EXPORT_METHOD(init:(NSString *)apiKey apiUrl:(NSString *)apiUrl transactionServiceUrl:(NSString *)transactionServiceUrl cardServiceUrl:(NSString *)cardServiceUrl notificationServiceUrl:(NSString *)notificationServiceUrl)
{
    _user = nil;
    _wallet = nil;
    _zumoKit = [[ZumoKit alloc] initWithApiKey:apiKey apiUrl:apiUrl transactionServiceUrl:transactionServiceUrl cardServiceUrl:cardServiceUrl notificationServiceUrl:notificationServiceUrl];
    [_zumoKit addChangeListener:self];
}

RCT_EXPORT_METHOD(signIn:(NSString *)userTokenSet resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_zumoKit signIn:userTokenSet completion:^(ZKUser * _Nullable user, NSError * _Nullable error) {
            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            self->_user = user;

            resolve(@{
                @"id": [user getId],
                @"hasWallet": @([user hasWallet]),
                @"accounts": [self mapAccounts:[user getAccounts]]
            });
        }];
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(signOut:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_zumoKit signOut];
        _user = nil;
        _wallet = nil;
        resolve(@(YES));
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

# pragma mark - Listeners

RCT_EXPORT_METHOD(addAccountDataListener:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user addAccountDataListener:self];
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

RCT_EXPORT_METHOD(isFiatCustomer:(NSString *)network resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        if ([_user isFiatCustomer:network]){
            resolve(@(YES));
        } else {
            resolve(@(NO));
        }
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(makeFiatCustomer:(NSString *)network firstName:(NSString *)firstName middleName:(NSString *)middleName lastName:(NSString *)lastName dateOfBirth:(NSString *)dateOfBirth email:(NSString *)email phone:(NSString *)phone addressData:(NSDictionary *)addressData resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user makeFiatCustomer:network firstName:firstName middleName:middleName lastName:lastName dateOfBirth:dateOfBirth email:email phone:phone address:[self unboxAddress:addressData] completion:^(NSError * _Nullable error) {

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


RCT_EXPORT_METHOD(getNominatedAccountFiatProperties:(NSString *)accountId resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
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

RCT_EXPORT_METHOD(fetchAuthenticationConfig:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user fetchAuthenticationConfigWithCompletion:^(ZKAuthenticationConfig * _Nullable config, NSError * _Nullable error) {
            
            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve([self mapAuthenticationConfig:config]);
        }];
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(createCard:(NSString *)fiatAccountId cardType:(NSString *)cardType mobileNumber:(NSString *)mobileNumber knowledgeBase:(NSArray<NSDictionary *> *)knowledgeBase resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user createCard:fiatAccountId cardType:cardType mobileNumber:mobileNumber knowledgeBase:[self unboxKnowledgeBase:knowledgeBase] completion:^(ZKCard * _Nullable card, NSError * _Nullable error) {
            
            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve([self mapCard:card]);
        }];
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(setCardStatus:(NSString *)cardId cardStatus:(NSString *)cardStatus pan:(NSString *)pan cvv2:(NSString *)cvv2 resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user setCardStatus:cardId cardStatus:cardStatus pan:pan cvv2:cvv2 completion:^(NSError * _Nullable error) {
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

RCT_EXPORT_METHOD(revealCardDetails:(NSString *)cardId resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user revealCardDetails:cardId completion:^(ZKCardDetails * _Nullable cardDetails, NSError * _Nullable error) {
            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve(@{
                @"pan": [cardDetails pan],
                @"cvv2": [cardDetails cvv2]
            });
        }];
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(revealPin:(NSString *)cardId resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user revealPin:cardId completion:^(int32_t pin, NSError * _Nullable error) {
            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve(@(pin));
        }];
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(unblockPin:(NSString *)cardId resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user unblockPin:cardId completion:^(NSError * _Nullable error) {
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

RCT_EXPORT_METHOD(setAuthentication:(NSString *)cardId knowledgeBase:(NSArray<NSDictionary *> *)knowledgeBase resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user setAuthentication:cardId knowledgeBase:[self unboxKnowledgeBase:knowledgeBase] completion:^(NSError * _Nullable error) {
            
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

RCT_EXPORT_METHOD(submitTransaction:(NSDictionary *)composedTransactionData metadata:(NSString *)metadata resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        NSString * type = composedTransactionData[@"type"];
        NSString * signedTransaction = (composedTransactionData[@"signedTransaction"] == [NSNull null]) ? NULL : composedTransactionData[@"signedTransaction"];
        ZKAccount *account = [self unboxAccount:composedTransactionData[@"account"]];
        NSString * destination = (composedTransactionData[@"destination"] == [NSNull null]) ? NULL : composedTransactionData[@"destination"];
        NSDecimalNumber * amount = (composedTransactionData[@"amount"] == [NSNull null]) ? NULL : [NSDecimalNumber decimalNumberWithString:composedTransactionData[@"amount"] locale:[self decimalLocale]];
        NSString * data = (composedTransactionData[@"data"] == [NSNull null]) ? NULL : composedTransactionData[@"data"];
        NSDecimalNumber * fee = [NSDecimalNumber decimalNumberWithString:composedTransactionData[@"fee"] locale:[self decimalLocale]];
        NSString * nonce = composedTransactionData[@"nonce"];

        ZKComposedTransaction * composedTransaction = [[ZKComposedTransaction alloc] initWithType:type signedTransaction:signedTransaction account:account destination:destination amount:amount data:data fee:fee nonce:nonce];

        [_wallet submitTransaction:composedTransaction metadata:metadata completion:^(ZKTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeEthTransaction:(NSString *)accountId gasPrice:(NSString *)gasPrice gasLimit:(int)gasLimit destination:(NSString *)destination amount:(NSString *)amount data:(NSString *)data nonce:(NSString *)nonce sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_wallet composeEthTransaction:accountId gasPrice:[NSDecimalNumber decimalNumberWithString:gasPrice locale:[self decimalLocale]] gasLimit:gasLimit destination:destination amount:amount ? [NSDecimalNumber decimalNumberWithString:amount locale:[self decimalLocale]] : NULL data:data nonce: nonce ? @([nonce integerValue]) : NULL sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeTransaction:(NSString *)accountId changeAccountId:(NSString *)changeAccountId destination:(NSString *)destination amount:(NSString *)amount feeRate:(NSString *)feeRate sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_wallet composeTransaction:accountId changeAccountId:changeAccountId destination:destination amount:amount ? [NSDecimalNumber decimalNumberWithString:amount locale:[self decimalLocale]] : NULL feeRate:[NSDecimalNumber decimalNumberWithString:feeRate locale:[self decimalLocale]] sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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
        [_wallet composeInternalFiatTransaction:fromAccountId toAccountId:toAccountId amount:amount ? [NSDecimalNumber decimalNumberWithString:amount locale:[self decimalLocale]] : NULL sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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
        [_wallet composeTransactionToNominatedAccount:fromAccountId amount:amount ? [NSDecimalNumber decimalNumberWithString:amount locale:[self decimalLocale]] : NULL sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeExchange:(NSString *)fromAccountId toAccountId:(NSString *)toAccountId amount:(NSString *)amount sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_wallet composeExchange:fromAccountId toAccountId:toAccountId  amount:amount ? [NSDecimalNumber decimalNumberWithString:amount locale:[self decimalLocale]] : NULL sendMax:sendMax completion:^(ZKComposedExchange * _Nullable exchange, NSError * _Nullable error) {

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
        NSString * signedTransaction = (composedExchangeData[@"signedTransaction"] == [NSNull null]) ? NULL : composedExchangeData[@"signedTransaction"];
        ZKAccount *fromAccount = [self unboxAccount:composedExchangeData[@"fromAccount"]];
        ZKAccount *toAccount = [self unboxAccount:composedExchangeData[@"toAccount"]];
        ZKQuote *quote = [self unboxQuote:composedExchangeData[@"quote"]];
        ZKExchangeSetting *exchangeSetting = [self unboxExchangeSetting:composedExchangeData[@"exchangeSetting"]];
        NSString * exchangeAddress = (composedExchangeData[@"exchangeAddress"] == [NSNull null]) ? NULL : composedExchangeData[@"exchangeAddress"];
        NSDecimalNumber * amount = [NSDecimalNumber decimalNumberWithString:composedExchangeData[@"amount"] locale:[self decimalLocale]];
        NSDecimalNumber * returnAmount = [NSDecimalNumber decimalNumberWithString:composedExchangeData[@"returnAmount"] locale:[self decimalLocale]];
        NSDecimalNumber * outgoingTransactionFee = [NSDecimalNumber decimalNumberWithString:composedExchangeData[@"outgoingTransactionFee"] locale:[self decimalLocale]];
        NSDecimalNumber * exchangeFee = [NSDecimalNumber decimalNumberWithString:composedExchangeData[@"exchangeFee"] locale:[self decimalLocale]];
        NSDecimalNumber * returnTransactionFee = [NSDecimalNumber decimalNumberWithString:composedExchangeData[@"returnTransactionFee"] locale:[self decimalLocale]];
        NSString *nonce = (composedExchangeData[@"nonce"] == [NSNull null]) ? NULL : composedExchangeData[@"nonce"];

        ZKComposedExchange * composedExchange = [[ZKComposedExchange alloc] initWithSignedTransaction:signedTransaction fromAccount:fromAccount toAccount:toAccount quote:quote exchangeSetting:exchangeSetting exchangeAddress:exchangeAddress amount:amount returnAmount:returnAmount outgoingTransactionFee:outgoingTransactionFee exchangeFee:exchangeFee returnTransactionFee:returnTransactionFee nonce:nonce];

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


RCT_EXPORT_METHOD(isRecoveryMnemonic:(NSString *)mnemonic resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
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

RCT_EXPORT_METHOD(getAccounts:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        NSArray<ZKAccount *> *accounts = [_user getAccounts];

        resolve([self mapAccounts:accounts]);
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

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

RCT_EXPORT_METHOD(fetchHistoricalExchangeRates:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_zumoKit fetchHistoricalExchangeRates:^(ZKHistoricalExchangeRates _Nullable historicalRates, NSError * _Nullable error) {
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

RCT_EXPORT_METHOD(getExchangeRates:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        resolve([self mapExchangeRates:[_zumoKit getExchangeRates]]);
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(getExchangeSettings:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        resolve([self mapExchangeSettings:[_zumoKit getExchangeSettings]]);
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(getTransactionFeeRates:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        resolve([self mapTransactionFeeRates:[_zumoKit getTransactionFeeRates]]);
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(isValidAddress:(NSString *)currencyCode address:(NSString *)address network:(NSString *)network resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    BOOL isValid = [[_zumoKit getUtils] isValidAddress:currencyCode address:address network:network];
    resolve(@(isValid));
}

RCT_EXPORT_METHOD(generateMnemonic:(int)wordLength resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    NSString *mnemonic = [[_zumoKit getUtils] generateMnemonic:wordLength];
    resolve(mnemonic);
}

#pragma mark - Mapping

- (NSArray<NSDictionary *> *)mapAccountData:(NSArray<ZKAccountDataSnapshot *> *)snapshots
{
    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];

    [snapshots enumerateObjectsUsingBlock:^(ZKAccountDataSnapshot * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mapped addObject:[self mapAccountDataSnapshot:obj]];
    }];

    return mapped;
}

- (NSDictionary *)mapAccountDataSnapshot:(ZKAccountDataSnapshot *)snapshot
{
    return @{
        @"account": [self mapAccount:[snapshot account]],
        @"transactions": [self mapTransactions:[snapshot transactions]]
    };
}

- (NSDictionary *)mapAccountFiatProperties:(ZKAccountFiatProperties *)accountFiatProperties
{
    return @{
        @"providerId": accountFiatProperties.providerId ? accountFiatProperties.providerId : [NSNull null],
        @"accountNumber": accountFiatProperties.accountNumber ? accountFiatProperties.accountNumber : [NSNull null],
        @"sortCode": accountFiatProperties.sortCode ? accountFiatProperties.sortCode : [NSNull null],
        @"bic": accountFiatProperties.bic ? accountFiatProperties.bic : [NSNull null],
        @"iban": accountFiatProperties.iban ? accountFiatProperties.iban : [NSNull null],
        @"customerName": accountFiatProperties.customerName ? accountFiatProperties.customerName : [NSNull null]
    };
}

- (NSDictionary *)mapAccount:(ZKAccount *)account
{
    NSMutableDictionary *cryptoProperties = [[NSMutableDictionary alloc] init];
    if ([account cryptoProperties]){
        cryptoProperties[@"path"] = account.cryptoProperties.path;
        cryptoProperties[@"address"] = account.cryptoProperties.address;
        cryptoProperties[@"nonce"] = account.cryptoProperties.nonce ? account.cryptoProperties.nonce : [NSNull null];
    }
    
    NSMutableArray<NSDictionary *> *cards = [[NSMutableArray alloc] init];
    [account.cards enumerateObjectsUsingBlock:^(
            ZKCard * _Nonnull card,
            NSUInteger idx,
            BOOL * _Nonnull stop) {

        [cards addObject:[self mapCard:card]];
    }];

    NSDictionary *dict = @{
        @"id": [account id],
        @"currencyType": [account currencyType],
        @"currencyCode": [account currencyCode],
        @"network": [account network],
        @"type": [account type],
        @"balance": [[account balance] descriptionWithLocale:[self decimalLocale]],
        @"hasNominatedAccount": @([account hasNominatedAccount]),
        @"cryptoProperties": [account cryptoProperties] ? cryptoProperties : [NSNull null],
        @"fiatProperties": [account fiatProperties] ? [self mapAccountFiatProperties:account.fiatProperties] : [NSNull null],
        @"cards": cards
    };

    return dict;
}

- (NSArray<NSDictionary *> *)mapAccounts:(NSArray<ZKAccount *>*)accounts
{
    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];

    [accounts enumerateObjectsUsingBlock:^(ZKAccount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        [mapped addObject:[self mapAccount:obj]];

    }];

    return mapped;
}

- (NSDictionary *)mapCard:(ZKCard *)card
{
    return @{
        @"id": [card id],
        @"accountId": [card accountId],
        @"cardType": [card cardType],
        @"cardStatus": [card cardStatus],
        @"limit": @([card limit]),
        @"maskedPan": [card maskedPan] ? [card maskedPan] : [NSNull null],
        @"expiry": [card expiry],
        @"sca": @([card sca])
    };
}

- (NSDictionary *)mapComposedTransaction:(ZKComposedTransaction *)composedTransaction
{
    NSMutableDictionary *dict = [@{
        @"type": [composedTransaction type],
        @"signedTransaction": [composedTransaction signedTransaction] ? [composedTransaction signedTransaction] : [NSNull null],
        @"account": [self mapAccount:[composedTransaction account]],
        @"destination": [composedTransaction destination] ? [composedTransaction destination] : [NSNull null],
        @"amount": [composedTransaction amount] ? [[composedTransaction amount] descriptionWithLocale:[self decimalLocale]] : [NSNull null],
        @"data": [composedTransaction data] ? [composedTransaction data] : [NSNull null],
        @"fee": [[composedTransaction fee] descriptionWithLocale:[self decimalLocale]],
        @"nonce": [composedTransaction nonce]
    } mutableCopy];

    return dict;
}


- (NSDictionary *)mapComposedExchange:(ZKComposedExchange *)exchange
{
    return @{
        @"signedTransaction": [exchange signedTransaction] ? [exchange signedTransaction] : [NSNull null],
         @"fromAccount": [self mapAccount:[exchange fromAccount]],
         @"toAccount": [self mapAccount:[exchange toAccount]],
         @"quote": [self mapQuote:[exchange quote]],
         @"exchangeSetting": [self mapExchangeSetting:[exchange exchangeSetting]],
         @"exchangeAddress": [exchange exchangeAddress] ? [exchange exchangeAddress] : [NSNull null],
         @"amount": [[exchange amount] descriptionWithLocale:[self decimalLocale]],
         @"returnAmount": [[exchange returnAmount] descriptionWithLocale:[self decimalLocale]],
         @"outgoingTransactionFee": [[exchange outgoingTransactionFee] descriptionWithLocale:[self decimalLocale]],
         @"exchangeFee": [[exchange exchangeFee] descriptionWithLocale:[self decimalLocale]],
         @"returnTransactionFee": [[exchange returnTransactionFee] descriptionWithLocale:[self decimalLocale]],
         @"nonce": [exchange nonce] ? [exchange nonce] : [NSNull null]
    };
}

- (NSDictionary *)mapFiatMap:(NSDictionary<NSString *, NSDecimalNumber *>*)fiatAmountsMap
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    [fiatAmountsMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDecimalNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        dict[key] = [obj descriptionWithLocale:[self decimalLocale]];
    }];

    return dict;
}

- (NSDictionary *)mapTransaction:(ZKTransaction *)transaction
{
    NSMutableDictionary *cryptoProperties = [[NSMutableDictionary alloc] init];
    if ([transaction cryptoProperties]) {
        cryptoProperties[@"txHash"] = transaction.cryptoProperties.txHash ? transaction.cryptoProperties.txHash : [NSNull null];
        cryptoProperties[@"nonce"] = transaction.cryptoProperties.nonce ? transaction.cryptoProperties.nonce : [NSNull null];
        cryptoProperties[@"fromAddress"] = transaction.cryptoProperties.fromAddress;
        cryptoProperties[@"toAddress"] = transaction.cryptoProperties.toAddress ? transaction.cryptoProperties.toAddress : [NSNull null];
        cryptoProperties[@"data"] = transaction.cryptoProperties.data ? transaction.cryptoProperties.data : [NSNull null];
        cryptoProperties[@"gasPrice"] = transaction.cryptoProperties.gasPrice ? [transaction.cryptoProperties.gasPrice descriptionWithLocale:[self decimalLocale]] : [NSNull null];
        cryptoProperties[@"gasLimit"] = transaction.cryptoProperties.gasLimit ? [transaction.cryptoProperties.gasLimit descriptionWithLocale:[self decimalLocale]] : [NSNull null];
        cryptoProperties[@"fiatAmount"] = transaction.cryptoProperties.fiatAmount ? [self mapFiatMap:transaction.cryptoProperties.fiatAmount] : [NSNull null];
        cryptoProperties[@"fiatFee"] = transaction.cryptoProperties.fiatFee ? [self mapFiatMap:transaction.cryptoProperties.fiatFee] : [NSNull null];
    }

    NSMutableDictionary *fiatProperties = [[NSMutableDictionary alloc] init];
    if ([transaction fiatProperties]) {
        fiatProperties[@"fromFiatAccount"] = transaction.fiatProperties.fromFiatAccount ? [self mapAccountFiatProperties:transaction.fiatProperties.fromFiatAccount] : [NSNull null];
        fiatProperties[@"toFiatAccount"] = transaction.fiatProperties.toFiatAccount ? [self mapAccountFiatProperties:transaction.fiatProperties.toFiatAccount] : [NSNull null];
    }
    
    NSMutableDictionary *cardProperties = [[NSMutableDictionary alloc] init];
    if ([transaction cardProperties]) {
        cardProperties[@"cardId"] = transaction.cardProperties.cardId;
        cardProperties[@"transactionAmount"] = [transaction.cardProperties.transactionAmount descriptionWithLocale:[self decimalLocale]];
        cardProperties[@"transactionCurrency"] = transaction.cardProperties.transactionCurrency;
        cardProperties[@"billingAmount"] = [transaction.cardProperties.billingAmount descriptionWithLocale:[self decimalLocale]];
        cardProperties[@"billingCurrency"] = transaction.cardProperties.billingCurrency;
        cardProperties[@"exchangeRateValue"] = [transaction.cardProperties.exchangeRateValue descriptionWithLocale:[self decimalLocale]];
        cardProperties[@"mcc"] = transaction.cardProperties.mcc ? transaction.cardProperties.mcc : [NSNull null];
        cardProperties[@"merchantName"] = transaction.cardProperties.merchantName ? transaction.cardProperties.merchantName : [NSNull null];
        cardProperties[@"merchantCountry"] = transaction.cardProperties.merchantCountry ? transaction.cardProperties.merchantCountry : [NSNull null];
    }

    NSMutableDictionary *dict = [@{
        @"id": [transaction id],
        @"type": [transaction type],
        @"currencyCode": [transaction currencyCode],
        @"direction": [transaction direction],
        @"fromUserId": [transaction fromUserId] ? [transaction fromUserId] : [NSNull null],
        @"toUserId": [transaction toUserId] ? [transaction toUserId] : [NSNull null],
        @"fromAccountId": [transaction fromAccountId] ? [transaction fromAccountId] : [NSNull null],
        @"toAccountId": [transaction toAccountId] ? [transaction toAccountId] : [NSNull null],
        @"network": [transaction network],
        @"status": [transaction status],
        @"amount": [transaction amount] ? [[transaction amount] descriptionWithLocale:[self decimalLocale]] : [NSNull null],
        @"fee": [transaction fee] ? [[transaction fee] descriptionWithLocale:[self decimalLocale]] : [NSNull null],
        @"nonce": [transaction nonce] ? [transaction nonce] : [NSNull null],
        @"cryptoProperties": [transaction cryptoProperties] ? cryptoProperties : [NSNull null],
        @"fiatProperties": [transaction fiatProperties] ? fiatProperties : [NSNull null],
        @"cardProperties": [transaction cardProperties] ? cardProperties : [NSNull null],
        @"exchange": [transaction exchange] ? [self mapExchange:[transaction exchange]] : [NSNull null],
        @"metadata": [transaction metadata] ? [transaction metadata] : [NSNull null],
        @"submittedAt": [transaction submittedAt] ? [transaction submittedAt] : [NSNull null],
        @"confirmedAt": [transaction confirmedAt] ? [transaction confirmedAt] : [NSNull null],
        @"timestamp": @([transaction timestamp])
    } mutableCopy];

    return dict;
}

- (NSDictionary *)mapExchange:(ZKExchange *)exchange
{
    return @{
         @"id": [exchange id],
         @"status": [exchange status],
         @"fromCurrency": [exchange fromCurrency],
         @"fromAccountId": [exchange fromAccountId],
         @"outgoingTransactionId": [exchange outgoingTransactionId] ? [exchange outgoingTransactionId] : [NSNull null],
         @"toCurrency": [exchange toCurrency],
         @"toAccountId": [exchange toAccountId],
         @"returnTransactionId": [exchange returnTransactionId] ? [exchange returnTransactionId] : [NSNull null],
         @"amount": [[exchange amount] descriptionWithLocale:[self decimalLocale]],
         @"outgoingTransactionFee": [exchange outgoingTransactionFee] ? [[exchange outgoingTransactionFee] descriptionWithLocale:[self decimalLocale]] : [NSNull null],
         @"returnAmount": [[exchange returnAmount] descriptionWithLocale:[self decimalLocale]],
         @"exchangeFee": [[exchange exchangeFee] descriptionWithLocale:[self decimalLocale]],
         @"returnTransactionFee": [[exchange returnTransactionFee] descriptionWithLocale:[self decimalLocale]],
         @"quote": [self mapQuote:[exchange quote]],
         @"exchangeRates": [self mapExchangeRates:[exchange exchangeRates]],
         @"exchangeSetting": [self mapExchangeSetting:[exchange exchangeSetting]],
         @"nonce": [exchange nonce] ? [exchange nonce] : [NSNull null],
         @"submittedAt": [exchange submittedAt],
         @"confirmedAt": [exchange confirmedAt] ? [exchange confirmedAt] : [NSNull null],
    };
}

- (NSDictionary *)mapTransactionFeeRate:(ZKTransactionFeeRate *)feeRates
{
    return @{
        @"slow": [[feeRates slow] descriptionWithLocale:[self decimalLocale]],
        @"average": [[feeRates average] descriptionWithLocale:[self decimalLocale]],
        @"fast": [[feeRates fast] descriptionWithLocale:[self decimalLocale]],
        @"slowTime": [NSNumber numberWithFloat:[feeRates slowTime]],
        @"averageTime": [NSNumber numberWithFloat:[feeRates averageTime]],
        @"fastTime": [NSNumber numberWithFloat:[feeRates fastTime]],
        @"source": [feeRates source]
    };
}

- (NSDictionary *)mapTransactionFeeRates:(NSDictionary<NSString *, ZKTransactionFeeRate *> *)feeRates
{
    NSMutableDictionary *res = [[NSMutableDictionary alloc] init];

    [feeRates enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull currency, ZKTransactionFeeRate * _Nonnull rate, BOOL * _Nonnull stop) {
        res[currency] = [self mapTransactionFeeRate:rate];
    }];

    return res;
}

- (NSDictionary *)mapExchangeRate:(ZKExchangeRate *)exchangeRate
{
    return @{
        @"id": [exchangeRate id],
        @"fromCurrency": [exchangeRate fromCurrency],
        @"toCurrency": [exchangeRate toCurrency],
        @"value": [[exchangeRate value] descriptionWithLocale:[self decimalLocale]],
        @"timestamp": [NSNumber numberWithInt:[exchangeRate timestamp]]
    };
}

- (NSDictionary *)mapQuote:(ZKQuote *)quote
{
    return @{
        @"id": [quote id],
        @"expireTime": [NSNumber numberWithInt:[quote expireTime]],
        @"expiresIn": [quote expiresIn] ? [quote expiresIn] : [NSNull null],
        @"fromCurrency": [quote fromCurrency],
        @"toCurrency": [quote toCurrency],
        @"depositAmount": [[quote depositAmount] descriptionWithLocale:[self decimalLocale]],
        @"value": [[quote value] descriptionWithLocale:[self decimalLocale]]
    };
}

- (NSDictionary *)mapExchangeRates:(NSDictionary<NSString *, NSDictionary<NSString *, ZKExchangeRate *> *> *)exchangeRates
{
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

 - (NSDictionary *)mapHistoricalExchangeRates:(ZKHistoricalExchangeRates) historicalRates
{
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


- (NSDictionary *)mapExchangeSetting:(ZKExchangeSetting *)exchangeSetting
{
    NSMutableDictionary *exchangeAddress = [[NSMutableDictionary alloc] init];

    [[exchangeSetting exchangeAddress] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull network, NSString * _Nonnull address, BOOL * _Nonnull stop) {
        exchangeAddress[network] = address;
    }];

    return @{
        @"id": [exchangeSetting id],
        @"exchangeAddress": exchangeAddress,
        @"fromCurrency": [exchangeSetting fromCurrency],
        @"toCurrency": [exchangeSetting toCurrency],
        @"minExchangeAmount": [[exchangeSetting minExchangeAmount] descriptionWithLocale:[self decimalLocale]],
        @"exchangeFeeRate": [[exchangeSetting exchangeFeeRate] descriptionWithLocale:[self decimalLocale]],
        @"outgoingTransactionFeeRate": [[exchangeSetting outgoingTransactionFeeRate] descriptionWithLocale:[self decimalLocale]],
        @"returnTransactionFee": [[exchangeSetting returnTransactionFee] descriptionWithLocale:[self decimalLocale]]
    };
}

- (NSDictionary *)mapExchangeSettings:(NSDictionary<NSString *, NSDictionary<NSString *, ZKExchangeSetting *> *> *)exchangeSetting
{
    NSMutableDictionary *outerDict = [[NSMutableDictionary alloc] init];

    [exchangeSetting enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull outerKey, NSDictionary<NSString *, ZKExchangeSetting *> * _Nonnull outerObj, BOOL * _Nonnull stop) {

        NSMutableDictionary *innerDict = [[NSMutableDictionary alloc] init];

        [outerObj enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull innerKey, ZKExchangeSetting * _Nonnull obj, BOOL * _Nonnull stop) {
            innerDict[innerKey] = [self mapExchangeSetting: obj];
        }];

        outerDict[outerKey] = innerDict;
    }];

    return outerDict;
}

- (NSArray<NSDictionary *> *)mapTransactions:(NSArray<ZKTransaction *>*)transactions
{
    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];

    [transactions enumerateObjectsUsingBlock:^(ZKTransaction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mapped addObject:[self mapTransaction:obj]];
    }];

    return mapped;
}

- (NSArray<NSDictionary *> *)mapExchanges:(NSArray<ZKExchange *>*)exchanges
{
    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];

    [exchanges enumerateObjectsUsingBlock:^(ZKExchange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mapped addObject:[self mapExchange:obj]];
    }];

    return mapped;
}

- (NSDictionary *)mapKbaQuestion:(ZKKbaQuestion *)question
{
    return @{
        @"type": [question type],
        @"question": [question question]
    };
}

- (NSDictionary *)mapAuthenticationConfig:(ZKAuthenticationConfig *)config
{
    NSMutableArray<NSDictionary *> *knowledgeBase = [[NSMutableArray alloc] init];

    [[config knowledgeBase] enumerateObjectsUsingBlock:^(ZKKbaQuestion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [knowledgeBase addObject:[self mapKbaQuestion:obj]];
    }];
    
    return @{
        @"knowledgeBase": knowledgeBase,
    };
}

#pragma mark - Unboxing

- (ZKAccount *)unboxAccount:(NSDictionary *)accountData
{
    ZKAccountCryptoProperties *cryptoProperties;
    if (accountData[@"cryptoProperties"] != [NSNull null]){
        NSDictionary *cryptoPropertiesData = accountData[@"cryptoProperties"];

        NSString *accountAddress = cryptoPropertiesData[@"address"];
        NSString *accountPath = cryptoPropertiesData[@"path"];
        NSNumber *accountNonce = (cryptoPropertiesData[@"nonce"] == [NSNull null]) ? NULL : cryptoPropertiesData[@"nonce"];

        cryptoProperties = [[ZKAccountCryptoProperties alloc] initWithAddress:accountAddress path:accountPath nonce:accountNonce];
    }

    ZKAccountFiatProperties *fiatProperties;
    if (accountData[@"fiatProperties"] != [NSNull null]){
        NSDictionary *fiatPropertiesData = accountData[@"fiatProperties"];

        NSString *providerId = (fiatPropertiesData[@"providerId"] == [NSNull null]) ? NULL : fiatPropertiesData[@"providerId"];
        NSString *accountNumber = (fiatPropertiesData[@"accountNumber"] == [NSNull null]) ? NULL : fiatPropertiesData[@"accountNumber"];
        NSString *sortCode = (fiatPropertiesData[@"sortCode"] == [NSNull null]) ? NULL : fiatPropertiesData[@"sortCode"];
        NSString *bic = (fiatPropertiesData[@"bic"] == [NSNull null]) ? NULL : fiatPropertiesData[@"bic"];
        NSString *iban = (fiatPropertiesData[@"iban"] == [NSNull null]) ? NULL : fiatPropertiesData[@"iban"];
        NSString *customerName = (fiatPropertiesData[@"customerName"] == [NSNull null]) ? NULL : fiatPropertiesData[@"customerName"];

        fiatProperties = [[ZKAccountFiatProperties alloc] initWithProviderId:providerId accountNumber:accountNumber sortCode:sortCode bic:bic iban:iban customerName:customerName];
    }
    
    NSMutableArray<ZKCard *> *cards = [[NSMutableArray alloc] init];
    [accountData[@"cards"] enumerateObjectsUsingBlock:^(
            NSDictionary * _Nonnull cardData,
            NSUInteger idx,
            BOOL * _Nonnull stop) {

        [cards addObject:[self unboxCard:cardData]];
    }];

    NSString *accountId = accountData[@"id"];
    NSString *accountCurrencyType = accountData[@"currencyType"];
    NSString *accountCurrencyCode = accountData[@"currencyCode"];
    NSString *accountNetwork = accountData[@"network"];
    NSString *accountType = accountData[@"type"];
    NSString *accountBalance = accountData[@"balance"];
    BOOL accountHasNominatedAccount = accountData[@"hasNominatedAccount"];

    return [[ZKAccount alloc] initWithId:accountId currencyType:accountCurrencyType currencyCode:accountCurrencyCode network:accountNetwork type:accountType balance:[NSDecimalNumber decimalNumberWithString:accountBalance locale:[self decimalLocale]] hasNominatedAccount:accountHasNominatedAccount cryptoProperties:cryptoProperties fiatProperties:fiatProperties cards:cards];
}

- (ZKQuote *)unboxQuote:(NSDictionary *)quote
{
    NSString *quoteId = quote[@"id"];
    NSNumber *expireTime = quote[@"expireTime"];
    NSNumber *expiresIn = (quote[@"expiresIn"] == [NSNull null]) ? NULL : quote[@"expiresIn"];
    NSString *fromCurrency = quote[@"fromCurrency"];
    NSString *toCurrency = quote[@"toCurrency"];
    NSString *depositAmount = quote[@"depositAmount"];
    NSString *value = quote[@"value"];

    return [[ZKQuote alloc] initWithId:quoteId expireTime:expireTime.intValue expiresIn:expiresIn fromCurrency:fromCurrency toCurrency:toCurrency depositAmount:[NSDecimalNumber decimalNumberWithString:depositAmount locale:[self decimalLocale]] value:[NSDecimalNumber decimalNumberWithString:value locale:[self decimalLocale]]];
}

- (ZKExchangeSetting *)unboxExchangeSetting:(NSDictionary *)exchangeSetting
{
    NSString *exchangeSettingId = exchangeSetting[@"id"];
    NSString *fromCurrency = exchangeSetting[@"fromCurrency"];
    NSString *toCurrency = exchangeSetting[@"toCurrency"];
    NSString *minExchangeAmount = exchangeSetting[@"minExchangeAmount"];
    NSString *exchangeFeeRate = exchangeSetting[@"exchangeFeeRate"];
    NSString *outgoingTransactionFeeRate = exchangeSetting[@"outgoingTransactionFeeRate"];
    NSString *returnTransactionFee = exchangeSetting[@"returnTransactionFee"];

    NSMutableDictionary *exchangeAddress = [[NSMutableDictionary alloc] init];

    NSDictionary *exchangeAddressMap = exchangeSetting[@"exchangeAddress"];
    [exchangeAddressMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull network, NSString * _Nonnull address, BOOL * _Nonnull stop) {
        exchangeAddress[network] = address;
    }];

    return [[ZKExchangeSetting alloc] initWithId:exchangeSettingId exchangeAddress:exchangeAddress fromCurrency:fromCurrency toCurrency:toCurrency minExchangeAmount:[NSDecimalNumber decimalNumberWithString:minExchangeAmount locale:[self decimalLocale]] exchangeFeeRate:[NSDecimalNumber decimalNumberWithString:exchangeFeeRate locale:[self decimalLocale]] outgoingTransactionFeeRate:[NSDecimalNumber decimalNumberWithString:outgoingTransactionFeeRate locale:[self decimalLocale]] returnTransactionFee:[NSDecimalNumber decimalNumberWithString:returnTransactionFee locale:[self decimalLocale]]];
}

- (ZKAddress *)unboxAddress:(NSDictionary *)data
{
    NSString *houseNumber = data[@"houseNumber"];
    NSString *addressLine1 = data[@"addressLine1"];
    NSString *addressLine2 = (data[@"addressLine2"] == [NSNull null]) ? NULL : data[@"addressLine2"];
    NSString *country = data[@"country"];
    NSString *postCode = data[@"postCode"];
    NSString *postTown = data[@"postTown"];

    return [[ZKAddress alloc] initWithHouseNumber:houseNumber addressLine1:addressLine1 addressLine2:addressLine2 country:country postCode:postCode postTown:postTown];
}

- (ZKCard *)unboxCard:(NSDictionary *)data
{
    NSString *cardId = data[@"id"];
    NSString *accountId = data[@"accountId"];
    NSString *cardType = data[@"cardType"];
    NSString *cardStatus = data[@"cardStatus"];
    NSNumber *limit = data[@"limit"];
    NSString *maskedPan = (data[@"maskedPan"] == [NSNull null]) ? NULL : data[@"maskedPan"];
    NSString *expiry = data[@"expiry"];
    BOOL sca = data[@"sca"];

    return [[ZKCard alloc] initWithId:cardId accountId:accountId cardType:cardType cardStatus:cardStatus limit:limit.intValue maskedPan:maskedPan expiry:expiry sca:sca];
}

- (ZKKbaAnswer *)unboxKbaAnswer:(NSDictionary *)data
{
    NSString *type = data[@"type"];
    NSString *answer = data[@"answer"];

    return [[ZKKbaAnswer alloc] initWithType:type answer:answer];
}

- (NSArray<ZKKbaAnswer *> *)unboxKnowledgeBase:(NSArray<NSDictionary *>*)data
{
    NSMutableArray<ZKKbaAnswer *> * knowledgeBase = [[NSMutableArray alloc] init];
    [data enumerateObjectsUsingBlock:^(
            NSDictionary * _Nonnull kbaData,
            NSUInteger idx,
            BOOL * _Nonnull stop) {

        [knowledgeBase addObject:[self unboxKbaAnswer:kbaData]];
    }];

    return knowledgeBase;
}

@end
