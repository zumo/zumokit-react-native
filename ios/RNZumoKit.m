
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

RCT_EXPORT_METHOD(init:(NSString *)apiKey apiUrl:(NSString *)apiUrl transactionServiceUrl:(NSString *)transactionServiceUrl cardServiceUrl:(NSString *)cardServiceUrl  notificationServiceUrl:(NSString *)notificationServiceUrl exchangeServiceUrl:(NSString *)exchangeServiceUrl custodyServiceUrl:(NSString *)custodyServiceUrl)
{
    _user = nil;
    _wallet = nil;
    _zumoKit = [[ZumoKit alloc] initWithApiKey:apiKey apiUrl:apiUrl transactionServiceUrl:transactionServiceUrl cardServiceUrl:cardServiceUrl notificationServiceUrl:notificationServiceUrl exchangeServiceUrl:exchangeServiceUrl custodyServiceUrl:custodyServiceUrl];
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
                @"integratorId": [user getIntegratorId],
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

RCT_EXPORT_METHOD(fetchTradingPairs:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user fetchTradingPairsWithCompletionHandler:^(NSString * _Nullable stringifiedJson, NSError * _Nullable error) {
            if(error != nil) {
                [self rejectPromiseWithNSError:reject error:error];
                return;
            }

            resolve(stringifiedJson);
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

RCT_EXPORT_METHOD(isFiatCustomer:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        if ([_user isFiatCustomer]){
            resolve(@(YES));
        } else {
            resolve(@(NO));
        }
    } @catch (NSException *exception) {
        [self rejectPromiseWithMessage:reject errorMessage:exception.description];
    }
}

RCT_EXPORT_METHOD(makeFiatCustomer:(NSString *)firstName middleName:(NSString *)middleName lastName:(NSString *)lastName dateOfBirth:(NSString *)dateOfBirth email:(NSString *)email phone:(NSString *)phone addressData:(NSDictionary *)addressData resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user makeFiatCustomer:firstName middleName:middleName lastName:lastName dateOfBirth:dateOfBirth email:email phone:phone address:[self unboxAddress:addressData] completion:^(NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(createAccount:(NSString *)currencyCode resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user createAccount:currencyCode completion:^(ZKAccount * _Nullable account, NSError * _Nullable error) {

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
        ZKAccount *account = [self unboxAccount:composedTransactionData[@"account"]];
        NSString * destination = (composedTransactionData[@"destination"] == [NSNull null]) ? NULL : composedTransactionData[@"destination"];
        NSDecimalNumber * amount = (composedTransactionData[@"amount"] == [NSNull null]) ? NULL : [NSDecimalNumber decimalNumberWithString:composedTransactionData[@"amount"] locale:[self decimalLocale]];
        NSDecimalNumber * fee = [NSDecimalNumber decimalNumberWithString:composedTransactionData[@"fee"] locale:[self decimalLocale]];
        NSString * nonce = composedTransactionData[@"nonce"];
        NSString * signedTransaction = (composedTransactionData[@"signedTransaction"] == [NSNull null]) ? NULL : composedTransactionData[@"signedTransaction"];
        NSString * custodyOrderId = (composedTransactionData[@"custodyOrderId"] == [NSNull null]) ? NULL : composedTransactionData[@"custodyOrderId"];
        NSString * data = (composedTransactionData[@"data"] == [NSNull null]) ? NULL : composedTransactionData[@"data"];

        ZKComposedTransaction * composedTransaction = [[ZKComposedTransaction alloc] initWithType:type account:account destination:destination amount:amount fee:fee nonce:nonce signedTransaction:signedTransaction custodyOrderId:custodyOrderId data:data];

        [_user submitTransaction:composedTransaction metadata:metadata completion:^(ZKTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeBtcTransaction:(NSString *)accountId changeAccountId:(NSString *)changeAccountId destination:(NSString *)destination amount:(NSString *)amount feeRate:(NSString *)feeRate sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
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

RCT_EXPORT_METHOD(composeTransaction:(NSString *)fromAccountId toAccountId:(NSString *)toAccountId amount:(NSString *)amount sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user composeTransaction:fromAccountId toAccountId:toAccountId amount:amount ? [NSDecimalNumber decimalNumberWithString:amount locale:[self decimalLocale]] : NULL sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeCustodyWithdrawTransaction:(NSString *)fromAccountId destination:(NSString *)destination amount:(NSString *)amount sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user composeCustodyWithdrawTransaction:fromAccountId destination:destination amount:amount ? [NSDecimalNumber decimalNumberWithString:amount locale:[self decimalLocale]] : NULL sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeNominatedTransaction:(NSString *)fromAccountId amount:(NSString *)amount sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user composeNominatedTransaction:fromAccountId amount:amount ? [NSDecimalNumber decimalNumberWithString:amount locale:[self decimalLocale]] : NULL sendMax:sendMax completion:^(ZKComposedTransaction * _Nullable transaction, NSError * _Nullable error) {

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

RCT_EXPORT_METHOD(composeExchange:(NSString *)debitAccountId creditAccountId:(NSString *)creditAccountId amount:(NSString *)amount sendMax:(BOOL)sendMax resolver:(RCTPromiseResolveBlock)resolve rejector:(RCTPromiseRejectBlock)reject)
{
    @try {
        [_user composeExchange:debitAccountId creditAccountId:creditAccountId  amount:amount ? [NSDecimalNumber decimalNumberWithString:amount locale:[self decimalLocale]] : NULL sendMax:sendMax completion:^(ZKComposedExchange * _Nullable exchange, NSError * _Nullable error) {

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
        ZKAccount *debitAccount = [self unboxAccount:composedExchangeData[@"debitAccount"]];
        ZKAccount *creditAccount = [self unboxAccount:composedExchangeData[@"creditAccount"]];
        ZKQuote *quote = [self unboxQuote:composedExchangeData[@"quote"]];

        ZKComposedExchange * composedExchange = [[ZKComposedExchange alloc] initWithDebitAccount:debitAccount creditAccount:creditAccount quote:quote];

       [_user submitExchange:composedExchange completion:^(ZKExchange * _Nullable exchange, NSError * _Nullable error) {

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
        @"custodyType": [account custodyType],
        @"balance": [[account balance] descriptionWithLocale:[self decimalLocale]],
        @"ledgerBalance": [[account ledgerBalance] descriptionWithLocale:[self decimalLocale]],
        @"availableBalance": [[account availableBalance] descriptionWithLocale:[self decimalLocale]],
        @"overdraftLimit": [[account overdraftLimit] descriptionWithLocale:[self decimalLocale]],
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
        @"custodyOrderId": [composedTransaction custodyOrderId] ? [composedTransaction custodyOrderId] : [NSNull null],
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
         @"debitAccount": [self mapAccount:[exchange debitAccount]],
         @"creditAccount": [self mapAccount:[exchange creditAccount]],
         @"quote": [self mapQuote:[exchange quote]]
    };
}

- (NSDictionary *)mapTransactionAmount:(ZKTransactionAmount *)transactionAmount
{
    return @{
        @"direction": [transactionAmount direction],
        @"userId": [transactionAmount userId] ? [transactionAmount userId] : [NSNull null],
        @"userIntegratorId": [transactionAmount userIntegratorId] ? [transactionAmount userIntegratorId] : [NSNull null],
        @"accountId": [transactionAmount accountId] ? [transactionAmount accountId] : [NSNull null],
        @"amount": [transactionAmount amount] ? [[transactionAmount amount] descriptionWithLocale:[self decimalLocale]] : [NSNull null],
        @"fiatAmount": [transactionAmount fiatAmount] ? [transactionAmount fiatAmount] : [NSNull null],
        @"address": [transactionAmount address] ? [transactionAmount address] : [NSNull null],
        @"isChange": @([transactionAmount isChange]),
        @"accountNumber": [transactionAmount accountNumber] ? [transactionAmount accountNumber] : [NSNull null],
        @"sortCode": [transactionAmount sortCode] ? [transactionAmount sortCode] : [NSNull null],
        @"bic": [transactionAmount bic] ? [transactionAmount bic] : [NSNull null],
        @"iban": [transactionAmount iban] ? [transactionAmount iban] : [NSNull null]
    };
}

- (NSDictionary *)mapInternalTransaction:(ZKInternalTransaction *)internalTransaction
{
    return @{
        @"fromUserId": [internalTransaction fromUserId] ? [internalTransaction fromUserId] : [NSNull null],
        @"fromUserIntegratorId": [internalTransaction fromUserIntegratorId] ? [internalTransaction fromUserIntegratorId] : [NSNull null],
        @"fromAccountId": [internalTransaction fromAccountId] ? [internalTransaction fromAccountId] : [NSNull null],
        @"fromAddress": [internalTransaction fromAddress] ? [internalTransaction fromAddress] : [NSNull null],
        @"toUserId": [internalTransaction toUserId] ? [internalTransaction toUserId] : [NSNull null],
        @"toUserIntegratorId": [internalTransaction toUserIntegratorId] ? [internalTransaction toUserIntegratorId] : [NSNull null],
        @"toAccountId": [internalTransaction toAccountId] ? [internalTransaction toAccountId] : [NSNull null],
        @"toAddress": [internalTransaction toAddress] ? [internalTransaction toAddress] : [NSNull null],
        @"amount": [[internalTransaction amount] descriptionWithLocale:[self decimalLocale]],
        @"fiatAmount": [internalTransaction fiatAmount] ? [internalTransaction fiatAmount] : [NSNull null]
    };
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
        cryptoProperties[@"fiatAmount"] = transaction.cryptoProperties.fiatAmount ? transaction.cryptoProperties.fiatAmount : [NSNull null];
        cryptoProperties[@"fiatFee"] = transaction.cryptoProperties.fiatFee ? transaction.cryptoProperties.fiatFee : [NSNull null];
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
    
    NSMutableDictionary *custodyOrder = [[NSMutableDictionary alloc] init];
    if ([transaction custodyOrder]) {
        custodyOrder[@"id"] = transaction.custodyOrder.id;
        custodyOrder[@"type"] = transaction.custodyOrder.type;
        custodyOrder[@"status"] = transaction.custodyOrder.status;
        custodyOrder[@"amount"] = transaction.custodyOrder.amount ? [transaction.custodyOrder.amount descriptionWithLocale:[self decimalLocale]] : [NSNull null];
        custodyOrder[@"feeInAmount"] = @(transaction.custodyOrder.feeInAmount);
        custodyOrder[@"estimatedFees"] = transaction.custodyOrder.estimatedFees ? [transaction.custodyOrder.estimatedFees descriptionWithLocale:[self decimalLocale]] : [NSNull null];
        custodyOrder[@"fees"] = transaction.custodyOrder.fees ? [transaction.custodyOrder.fees descriptionWithLocale:[self decimalLocale]] : [NSNull null];
        custodyOrder[@"fromAddresses"] = transaction.custodyOrder.fromAddresses ?  transaction.custodyOrder.fromAddresses : [NSNull null];
        custodyOrder[@"fromAccountId"] = transaction.custodyOrder.fromAccountId ?  transaction.custodyOrder.fromAccountId : [NSNull null];
        custodyOrder[@"toAddress"] = transaction.custodyOrder.toAddress ?  transaction.custodyOrder.toAddress : [NSNull null];
        custodyOrder[@"toAccountId"] = transaction.custodyOrder.toAccountId ?  transaction.custodyOrder.toAccountId : [NSNull null];
        custodyOrder[@"createdAt"] = @(transaction.custodyOrder.createdAt);
        custodyOrder[@"updatedAt"] = @(transaction.custodyOrder.updatedAt);
    }

    NSMutableDictionary *dict = [@{
        @"id": [transaction id],
        @"type": [transaction type],
        @"currencyCode": [transaction currencyCode],
        @"direction": [transaction direction],
        @"network": [transaction network],
        @"status": [transaction status],
        @"amount": [transaction amount] ? [[transaction amount] descriptionWithLocale:[self decimalLocale]] : [NSNull null],
        @"fee": [transaction fee] ? [[transaction fee] descriptionWithLocale:[self decimalLocale]] : [NSNull null],
        @"nonce": [transaction nonce] ? [transaction nonce] : [NSNull null],
        @"senders": [self mapTransactionAmounts:[transaction senders]],
        @"recipients": [self mapTransactionAmounts:[transaction recipients]],
        @"internalTransactions": [self mapInternalTransactions:[transaction internalTransactions]],
        @"custodyOrder": [transaction custodyOrder] ? custodyOrder : [NSNull null],
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
    NSMutableDictionary *rates = [[NSMutableDictionary alloc] init];
    [[exchange rates] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull fromCurrency, NSDictionary<NSString *, NSDecimalNumber *> * _Nonnull outerObj, BOOL * _Nonnull stop) {

        NSMutableDictionary *innerDict = [[NSMutableDictionary alloc] init];

        [outerObj enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull toCurrency, NSDecimalNumber * _Nonnull rate, BOOL * _Nonnull stop) {
            innerDict[toCurrency] = [rate descriptionWithLocale:[self decimalLocale]];
        }];

        rates[fromCurrency] = innerDict;
    }];
    
    return @{
         @"id": [exchange id],
         @"status": [exchange status],
         @"pair": [exchange pair],
         @"side": [exchange side],
         @"price": [[exchange price] descriptionWithLocale:[self decimalLocale]],
         @"amount": [[exchange amount] descriptionWithLocale:[self decimalLocale]],
         @"debitAccountId": [exchange debitAccountId],
         @"debitTransactionId": [exchange debitTransactionId] ? [exchange debitTransactionId] : [NSNull null],
         @"creditAccountId": [exchange creditAccountId],
         @"creditTransactionId": [exchange creditTransactionId] ? [exchange creditTransactionId] : [NSNull null],
         @"quote": [self mapQuote:[exchange quote]],
         @"rates": rates,
         @"nonce": [exchange nonce] ? [exchange nonce] : [NSNull null],
         @"createdAt": [exchange createdAt],
         @"updatedAt": [exchange updatedAt],
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
        @"ttl": [NSNumber numberWithInt:[quote ttl]],
        @"createdAt": [quote createdAt],
        @"expiresAt": [quote expiresAt],
        @"debitCurrency": [quote debitCurrency],
        @"creditCurrency": [quote creditCurrency],
        @"price": [[quote price] descriptionWithLocale:[self decimalLocale]],
        @"feeRate": [[quote feeRate] descriptionWithLocale:[self decimalLocale]],
        @"debitAmount": [[quote debitAmount] descriptionWithLocale:[self decimalLocale]],
        @"feeAmount": [[quote feeAmount] descriptionWithLocale:[self decimalLocale]],
        @"creditAmount": [[quote creditAmount] descriptionWithLocale:[self decimalLocale]]
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

- (NSArray<NSDictionary *> *)mapTransactionAmounts:(NSArray<ZKTransactionAmount *>*)transactionAmounts
{
    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];

    [transactionAmounts enumerateObjectsUsingBlock:^(ZKTransactionAmount * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mapped addObject:[self mapTransactionAmount:obj]];
    }];

    return mapped;
}

- (NSArray<NSDictionary *> *)mapInternalTransactions:(NSArray<ZKInternalTransaction *>*)internalTransactions
{
    NSMutableArray<NSDictionary *> *mapped = [[NSMutableArray alloc] init];

    [internalTransactions enumerateObjectsUsingBlock:^(ZKInternalTransaction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mapped addObject:[self mapInternalTransaction:obj]];
    }];

    return mapped;
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
    NSString *accountCustodyType = accountData[@"custodyType"];
    NSString *accountBalance = accountData[@"balance"];
    NSString *accountLedgerBalance = accountData[@"ledgerBalance"];
    NSString *accountAvailableBalance = accountData[@"availableBalance"];
    NSString *accountOverdraftLimit = accountData[@"overdraftLimit"];
    BOOL accountHasNominatedAccount = accountData[@"hasNominatedAccount"];

    return [[ZKAccount alloc] initWithId:accountId currencyType:accountCurrencyType currencyCode:accountCurrencyCode network:accountNetwork type:accountType custodyType:accountCustodyType balance:[NSDecimalNumber decimalNumberWithString:accountBalance locale:[self decimalLocale]] ledgerBalance:[NSDecimalNumber decimalNumberWithString:accountLedgerBalance locale:[self decimalLocale]] availableBalance:[NSDecimalNumber decimalNumberWithString:accountAvailableBalance locale:[self decimalLocale]] overdraftLimit:[NSDecimalNumber decimalNumberWithString:accountOverdraftLimit locale:[self decimalLocale]] hasNominatedAccount:accountHasNominatedAccount cryptoProperties:cryptoProperties fiatProperties:fiatProperties cards:cards];
}

- (ZKQuote *)unboxQuote:(NSDictionary *)quote
{
    NSString *quoteId = quote[@"id"];
    NSNumber *ttl = quote[@"ttl"];
    NSString *createdAt = quote[@"createdAt"];
    NSString *expiresAt = quote[@"expiresAt"];
    NSString *debitCurrency = quote[@"debitCurrency"];
    NSString *creditCurrency = quote[@"creditCurrency"];
    NSString *price = quote[@"price"];
    NSString *feeRate = quote[@"feeRate"];
    NSString *debitAmount = quote[@"debitAmount"];
    NSString *feeAmount = quote[@"feeAmount"];
    NSString *creditAmount = quote[@"creditAmount"];

    return [[ZKQuote alloc] initWithId:quoteId ttl:ttl.intValue createdAt:createdAt expiresAt:expiresAt debitCurrency:debitCurrency creditCurrency:creditCurrency price:[NSDecimalNumber decimalNumberWithString:price locale:[self decimalLocale]] feeRate:[NSDecimalNumber decimalNumberWithString:price locale:[self decimalLocale]] debitAmount:[NSDecimalNumber decimalNumberWithString:price locale:[self decimalLocale]] feeAmount:[NSDecimalNumber decimalNumberWithString:price locale:[self decimalLocale]] creditAmount:[NSDecimalNumber decimalNumberWithString:price locale:[self decimalLocale]]];
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
