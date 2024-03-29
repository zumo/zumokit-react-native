package com.zumokit.reactnative;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;

import com.facebook.react.modules.core.DeviceEventManagerModule;

import money.zumo.zumokit.AuthenticationConfig;
import money.zumo.zumokit.AuthenticationConfigCallback;
import money.zumo.zumokit.KbaAnswer;
import money.zumo.zumokit.KbaQuestion;
import money.zumo.zumokit.LogListener;
import money.zumo.zumokit.AccountDataSnapshot;
import money.zumo.zumokit.AccountFiatPropertiesCallback;
import money.zumo.zumokit.Address;
import money.zumo.zumokit.Card;
import money.zumo.zumokit.CardCallback;
import money.zumo.zumokit.CardDetails;
import money.zumo.zumokit.CardDetailsCallback;
import money.zumo.zumokit.ChangeListener;
import money.zumo.zumokit.ComposeExchangeCallback;
import money.zumo.zumokit.ComposedExchange;
import money.zumo.zumokit.CustodyOrder;
import money.zumo.zumokit.Exchange;
import money.zumo.zumokit.AccountCryptoProperties;
import money.zumo.zumokit.AccountFiatProperties;
import money.zumo.zumokit.HistoricalExchangeRatesCallback;
import money.zumo.zumokit.PinCallback;
import money.zumo.zumokit.SubmitExchangeCallback;
import money.zumo.zumokit.SuccessCallback;
import money.zumo.zumokit.ZumoKit;
import money.zumo.zumokit.ZumoKitErrorType;
import money.zumo.zumokit.ZumoKitErrorCode;
import money.zumo.zumokit.User;
import money.zumo.zumokit.Wallet;
import money.zumo.zumokit.WalletCallback;
import money.zumo.zumokit.MnemonicCallback;
import money.zumo.zumokit.UserCallback;
import money.zumo.zumokit.Account;
import money.zumo.zumokit.Transaction;
import money.zumo.zumokit.TransactionAmount;
import money.zumo.zumokit.InternalTransaction;
import money.zumo.zumokit.ComposedTransaction;
import money.zumo.zumokit.ComposeTransactionCallback;
import money.zumo.zumokit.SubmitTransactionCallback;
import money.zumo.zumokit.AccountDataListener;
import money.zumo.zumokit.AccountCallback;
import money.zumo.zumokit.TransactionFeeRate;
import money.zumo.zumokit.ExchangeRate;
import money.zumo.zumokit.Quote;
import money.zumo.zumokit.StringifiedJsonCallback;
import money.zumo.zumokit.exceptions.ZumoKitException;

import java.math.BigDecimal;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;

public class RNZumoKitModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;

    private ZumoKit zumokit;

    private User user;

    private Wallet wallet;

    public RNZumoKitModule(ReactApplicationContext reactContext) {
        super(reactContext);

        this.reactContext = reactContext;
    }

    private void rejectPromise(
            Promise promise,
            String errorType,
            String errorCode,
            String errorMessage
    ) {
        WritableMap userInfo = Arguments.createMap();
        userInfo.putString("type", errorType);

        promise.reject(errorCode, errorMessage, userInfo);
    }

    private void rejectPromise(Promise promise, Exception e) {
        ZumoKitException error = (ZumoKitException) e;

        rejectPromise(
                promise,
                error.getErrorType(),
                error.getErrorCode(),
                error.getMessage()
        );
    }

    private void rejectPromise(Promise promise, String errorMessage) {
        rejectPromise(
                promise,
                ZumoKitErrorType.INVALID_REQUEST_ERROR,
                ZumoKitErrorCode.UNKNOWN_ERROR,
                errorMessage
        );
    }

    @ReactMethod
    public void setLogLevel(String logLevel) {
        ZumoKit.setLogLevel(logLevel);
    }

    @ReactMethod
    public void addLogListener(String logLevel) {
        RNZumoKitModule module = this;
        ZumoKit.onLog(
                new LogListener() {
                    @Override
                    public void onLog(String message) {
                        module.reactContext
                                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                                .emit("OnLog", message);
                    }
                },
                logLevel
        );
    }

    @ReactMethod
    public void init(
        String apiKey, 
        String apiUrl, 
        String transactionServiceUrl, 
        String cardServiceUrl,
        String notificationServiceUrl,
        String exchangeServiceUrl,
        String custodyServiceUrl) {
        this.user = null;
        this.wallet = null;
        this.zumokit = new ZumoKit(
            apiKey, 
            apiUrl, 
            transactionServiceUrl, 
            cardServiceUrl,
            notificationServiceUrl,
                exchangeServiceUrl,
                custodyServiceUrl);

        RNZumoKitModule module = this;
        this.zumokit.addChangeListener(new ChangeListener() {
            @Override
            public void onChange() {
                module.reactContext
                        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("AuxDataChanged", null);
            }
        });
    }

    // - Authentication

    @ReactMethod
    public void signIn(String userTokenSet, Promise promise) {
        if (this.zumokit == null) {
            rejectPromise(promise, "ZumoKit not initialized.");
            return;
        }

        RNZumoKitModule module = this;
        this.zumokit.signIn(userTokenSet, new UserCallback() {
            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(User user) {
                module.user = user;

                WritableMap map = Arguments.createMap();

                map.putString("id", user.getId());
                map.putString("integratorId", user.getIntegratorId());
                map.putBoolean("hasWallet", user.hasWallet());
                map.putArray("accounts", RNZumoKitModule.mapAccounts(user.getAccounts()));

                promise.resolve(map);
            }
        });
    }

    @ReactMethod
    public void signOut(Promise promise) {
        if (this.zumokit == null) {
            rejectPromise(promise, "ZumoKit not initialized.");
            return;
        }

        this.zumokit.signOut();
        this.user = null;
        this.wallet = null;
        promise.resolve(true);
    }

    // - Listeners
    @ReactMethod
    public void addAccountDataListener(Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        RNZumoKitModule module = this;
        this.user.addAccountDataListener(new AccountDataListener() {
            @Override
            public void onDataChange(ArrayList<AccountDataSnapshot> snapshots) {
                WritableArray array = RNZumoKitModule.mapAccountData(snapshots);

                module.reactContext
                        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("AccountDataChanged", array);
            }
        });
    }

    // - Wallet Management

    @ReactMethod
    public void createWallet(String mnemonic, String password, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        RNZumoKitModule module = this;
        this.user.createWallet(mnemonic, password, new WalletCallback() {
            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(Wallet wallet) {
                module.wallet = wallet;
                promise.resolve(true);
            }
        });
    }

    @ReactMethod
    public void unlockWallet(String password, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        RNZumoKitModule module = this;
        this.user.unlockWallet(password, new WalletCallback() {
            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(Wallet wallet) {
                module.wallet = wallet;
                promise.resolve(true);
            }
        });
    }

    @ReactMethod
    public void isFiatCustomer(Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        promise.resolve(this.user.isFiatCustomer());
    }

    @ReactMethod
    public void makeFiatCustomer(
            String firstName,
            String middleName,
            String lastName,
            String dateOfBirth,
            String email,
            String phone,
            ReadableMap addressData,
            Promise promise
    ) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.makeFiatCustomer(
                firstName,
                middleName,
                lastName,
                dateOfBirth,
                email,
                phone,
                RNZumoKitModule.unboxAddress(addressData),
                new SuccessCallback() {
                    @Override
                    public void onError(Exception e) {
                        rejectPromise(promise, e);
                    }

                    @Override
                    public void onSuccess() {
                        promise.resolve(true);
                    }
                });
    }

    @ReactMethod
    public void createAccount(String currencyCode, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.createAccount(currencyCode, new AccountCallback() {
            @Override
            public void onError(Exception e) {
                rejectPromise(promise, e);
            }

            @Override
            public void onSuccess(Account account) {
                promise.resolve(mapAccount(account));
            }
        });
    }

    @ReactMethod
    public void getNominatedAccountFiatProperties(String accountId, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.getNominatedAccountFiatProperties(accountId, new AccountFiatPropertiesCallback() {
            @Override
            public void onError(Exception e) {
                rejectPromise(promise, e);
            }

            @Override
            public void onSuccess(AccountFiatProperties accountFiatProperties) {
                promise.resolve(accountFiatProperties == null ?
                        null : mapAccountFiatProperties(accountFiatProperties));
            }
        });
    }

    @ReactMethod
    public void fetchAuthenticationConfig(
            Promise promise
    ) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.fetchAuthenticationConfig(
                new AuthenticationConfigCallback() {
                    @Override
                    public void onError(Exception e) {
                        rejectPromise(promise, e);
                    }

                    @Override
                    public void onSuccess(AuthenticationConfig config) {
                        promise.resolve(RNZumoKitModule.mapAuthenticationConfig(config));
                    }
                });
    }

    @ReactMethod
    public void createCard(
            String fiatAccountId,
            String cardType,
            String mobileNumber,
            ReadableArray knowledgeBase,
            Promise promise
    ) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.createCard(
                fiatAccountId,
                cardType,
                mobileNumber,
                RNZumoKitModule.unboxKnowledgeBase(knowledgeBase),
                new CardCallback() {
                    @Override
                    public void onError(Exception e) {
                        rejectPromise(promise, e);
                    }

                    @Override
                    public void onSuccess(Card card) {
                        promise.resolve(RNZumoKitModule.mapCard(card));
                    }
                });
    }

    @ReactMethod
    public void setCardStatus(
            String cardId,
            String cardStatus,
            String pan,
            String cvv2,
            Promise promise
    ) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.setCardStatus(cardId, cardStatus, pan, cvv2, new SuccessCallback() {
                    @Override
                    public void onError(Exception e) { rejectPromise(promise, e); }

                    @Override
                    public void onSuccess() { promise.resolve(true); }
                });
    }

    @ReactMethod
    public void revealCardDetails(String cardId, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.revealCardDetails(cardId, new CardDetailsCallback() {
            @Override
            public void onError(Exception e) { rejectPromise(promise, e); }

            @Override
            public void onSuccess(CardDetails cardDetails) {
                WritableMap map = Arguments.createMap();

                map.putString("pan", cardDetails.getPan());
                map.putString("cvv2", cardDetails.getCvv2());

                promise.resolve(map);
            }
        });
    }

    @ReactMethod
    public void revealPin(String cardId, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.revealPin(cardId, new PinCallback() {
            @Override
            public void onError(Exception e) { rejectPromise(promise, e); }

            @Override
            public void onSuccess(int pin) { promise.resolve(pin); }
        });
    }

    @ReactMethod
    public void unblockPin(String cardId, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.unblockPin(cardId, new SuccessCallback() {
            @Override
            public void onError(Exception e) { rejectPromise(promise, e); }

            @Override
            public void onSuccess() { promise.resolve(true); }
        });
    }

    @ReactMethod
    public void setAuthentication(String cardId, ReadableArray knowledgeBase, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.setAuthentication(cardId, unboxKnowledgeBase(knowledgeBase), new SuccessCallback() {
            @Override
            public void onError(Exception e) { rejectPromise(promise, e); }

            @Override
            public void onSuccess() { promise.resolve(true); }
        });
    }

    @ReactMethod
    public void revealMnemonic(String password, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.revealMnemonic(password, new MnemonicCallback() {
            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(String mnemonic) {
                promise.resolve(mnemonic);
            }
        });
    }

    // - Account Management

    @ReactMethod
    public void getAccounts(Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        ArrayList<Account> accounts = this.user.getAccounts();
        WritableArray response = RNZumoKitModule.mapAccounts(accounts);

        // Resolve the promise with our response array
        promise.resolve(response);
    }

    // - Transactions

    @ReactMethod
    public void submitTransaction(ReadableMap composedTransactionMap, String toAccountId, String metadata, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        String type = composedTransactionMap.getString("type");
        Account account = RNZumoKitModule.unboxAccount(composedTransactionMap.getMap("account"));
        String destination = composedTransactionMap.getString("destination");
        BigDecimal amount = new BigDecimal(composedTransactionMap.getString("amount"));
        BigDecimal fee = new BigDecimal(composedTransactionMap.getString("fee"));
        String nonce = composedTransactionMap.getString("nonce");
        String signedTransaction = composedTransactionMap.getString("signedTransaction");
        String custodyOrderId = composedTransactionMap.getString("custodyOrderId");
        String data = composedTransactionMap.getString("data");

        ComposedTransaction composedTransaction =
                new ComposedTransaction(
                        type,
                        account,
                        destination,
                        amount,
                        fee,
                        nonce,
                        signedTransaction,
                        custodyOrderId,
                        data
                );

        this.user.submitTransaction(composedTransaction, toAccountId, metadata, new SubmitTransactionCallback() {

            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(Transaction transaction) {
                WritableMap map = RNZumoKitModule.mapTransaction(transaction);
                promise.resolve(map);
            }
        });
    }

    @ReactMethod
    public void composeEthTransaction(
            String accountId,
            String gasPrice,
            int gasLimit,
            String destination,
            String amount,
            String data,
            String nonce,
            Boolean sendMax,
            Promise promise
    ) {
        if (this.wallet == null) {
            rejectPromise(promise, "Wallet not found.");
            return;
        }

        Integer nonceValue = null;
        if (nonce != null) {
            nonceValue = Integer.parseInt(nonce);
        }

        this.wallet.composeEthTransaction(
                accountId,
                new BigDecimal(gasPrice),
                gasLimit,
                destination,
                (amount == null) ? null : new BigDecimal(amount),
                data,
                nonceValue,
                sendMax,
                new ComposeTransactionCallback() {
            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(ComposedTransaction transaction) {
                WritableMap map = RNZumoKitModule.mapComposedTransaction(transaction);
                promise.resolve(map);
            }
        });
    }

    @ReactMethod
    public void composeBtcTransaction(
            String accountId,
            String changeAccountId,
            String destination,
            String amount,
            String feeRate,
            Boolean sendMax,
            Promise promise
    ) {
        if (this.wallet == null) {
            rejectPromise(promise, "Wallet not found.");
            return;
        }

        this.wallet.composeTransaction(
                accountId,
                changeAccountId,
                destination,
                (amount == null) ? null : new BigDecimal(amount),
                new BigDecimal(feeRate),
                sendMax,
                new ComposeTransactionCallback() {
                    @Override
                    public void onError(Exception error) {
                        rejectPromise(promise, error);
                    }

                    @Override
                    public void onSuccess(ComposedTransaction transaction) {
                        WritableMap map = RNZumoKitModule.mapComposedTransaction(transaction);
                        promise.resolve(map);
                    }
                });
    }

    @ReactMethod
    public void composeTransaction(
            String fromAccountId,
            String toAccountId,
            String amount,
            Boolean sendMax,
            Promise promise
    ) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.composeTransaction(
                fromAccountId,
                toAccountId,
                (amount == null) ? null : new BigDecimal(amount),
                sendMax,
                new ComposeTransactionCallback() {
            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(ComposedTransaction transaction) {
                WritableMap map = RNZumoKitModule.mapComposedTransaction(transaction);
                promise.resolve(map);
            }
        });
    }

    @ReactMethod
    public void composeCustodyWithdrawTransaction(
            String fromAccountId,
            String destination,
            String amount,
            Boolean sendMax,
            Promise promise
    ) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.composeCustodyWithdrawTransaction(
                fromAccountId,
                destination,
                (amount == null) ? null : new BigDecimal(amount),
                sendMax,
                new ComposeTransactionCallback() {
                    @Override
                    public void onError(Exception error) {
                        rejectPromise(promise, error);
                    }

                    @Override
                    public void onSuccess(ComposedTransaction transaction) {
                        WritableMap map = RNZumoKitModule.mapComposedTransaction(transaction);
                        promise.resolve(map);
                    }
                });
    }

    @ReactMethod
    public void composeNominatedTransaction(
            String fromAccountId,
            String amount,
            Boolean sendMax,
            Promise promise
    ) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.composeNominatedTransaction(
                fromAccountId,
                (amount == null) ? null : new BigDecimal(amount),
                sendMax,
                new ComposeTransactionCallback() {
            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(ComposedTransaction transaction) {
                WritableMap map = RNZumoKitModule.mapComposedTransaction(transaction);
                promise.resolve(map);
            }
        });
    }

    @ReactMethod
    public void fetchTradingPairs(Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.fetchTradingPairs(new StringifiedJsonCallback() {
            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(String stringifiedJson) {
                promise.resolve(stringifiedJson);
            }
        });
    }

    @ReactMethod
    public void composeExchange(
            String fromAccountId,
            String toAccountId,
            String amount,
            Boolean sendMax,
            Promise promise
    ) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.composeExchange(
                fromAccountId,
                toAccountId,
                (amount == null) ? null : new BigDecimal(amount),
                sendMax,
                new ComposeExchangeCallback() {
            @Override
            public void onError(Exception e) {
                rejectPromise(promise, e);
            }

            @Override
            public void onSuccess(ComposedExchange composedExchange) {
                WritableMap map = RNZumoKitModule.mapComposedExchange(composedExchange);
                promise.resolve(map);
            }
        });
    }

    @ReactMethod
    public void submitExchange(ReadableMap composedExchangeMap, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        Account fromAccount =
                RNZumoKitModule.unboxAccount(composedExchangeMap.getMap("debitAccount"));
        Account toAccount =
                RNZumoKitModule.unboxAccount(composedExchangeMap.getMap("creditAccount"));
        Quote quote =
                RNZumoKitModule.unboxQuote(composedExchangeMap.getMap("quote"));

        ComposedExchange composedExchange = new ComposedExchange(
                fromAccount,
                toAccount,
                quote
        );

        this.user.submitExchange(composedExchange, new SubmitExchangeCallback() {
            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(Exchange exchange) {
                WritableMap map = RNZumoKitModule.mapExchange(exchange);
                promise.resolve(map);
            }
        });
    }

    // - Wallet Recovery

    @ReactMethod
    public void isRecoveryMnemonic(String mnemonic, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        Boolean validation = this.user.isRecoveryMnemonic(mnemonic);
        promise.resolve(validation);
    }

    @ReactMethod
    public void recoverWallet(String mnemonic, String password, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        RNZumoKitModule module = this;
        this.user.recoverWallet(mnemonic, password, new WalletCallback() {
            @Override
            public void onError(Exception error) {
                rejectPromise(promise, error);
            }

            @Override
            public void onSuccess(Wallet wallet) {
                module.wallet = wallet;
                promise.resolve(true);
            }
        });
    }

    // - Utility

    @ReactMethod
    public void getExchangeRates(Promise promise) {
        if (this.zumokit == null) {
            rejectPromise(promise, "ZumoKit not initialized.");
            return;
        }

        promise.resolve(mapExchangeRates(this.zumokit.getExchangeRates()));
    }

    @ReactMethod
    public void getTransactionFeeRates(Promise promise) {
        if (this.zumokit == null) {
            rejectPromise(promise, "ZumoKit not initialized.");
            return;
        }

        promise.resolve(mapTransactionFeeRates(this.zumokit.getTransactionFeeRates()));
    }

    @ReactMethod
    public void fetchHistoricalExchangeRates(Promise promise) {
        if (this.zumokit == null) {
            rejectPromise(promise, "ZumoKit not initialized.");
            return;
        }

        this.zumokit.fetchHistoricalExchangeRates(new HistoricalExchangeRatesCallback() {
            @Override
            public void onError(Exception e) {
                rejectPromise(promise, e);
            }

            @Override
            public void onSuccess(
                    HashMap<String, HashMap<String, HashMap<String, ArrayList<ExchangeRate>>>> historicalExchangeRates
            ) {
                promise.resolve(RNZumoKitModule.mapHistoricalExchangeRates(historicalExchangeRates));
            }
        });
    }

    @ReactMethod
    public void generateMnemonic(int wordLength, Promise promise) {
        if (this.zumokit == null) {
            rejectPromise(promise, "ZumoKit not initialized.");
            return;
        }

        try {
            String mnemonic = this.zumokit.getUtils().generateMnemonic(wordLength);
            promise.resolve(mnemonic);
        } catch (Exception e) {
            rejectPromise(promise, e);
        }
    }

    @ReactMethod
    public void isValidAddress(String currencyCode, String address, String network, Promise promise) {
        try {
            Boolean valid = this.zumokit.getUtils().isValidAddress(currencyCode, address, network);
            promise.resolve(valid);
        } catch (Exception e) {
            rejectPromise(promise, e);
        }
    }

    // - Helpers

    public static HashMap<String, String> toHashMap(ReadableMap readableMap) {
        HashMap<String, String> result = new HashMap<String, String>();

        if (readableMap == null) {
            return result;
        }

        ReadableMapKeySetIterator iterator = readableMap.keySetIterator();

        if (!iterator.hasNextKey()) {
            return result;
        }

        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            result.put(key, readableMap.getString(key));
        }

        return result;
    }

    public static WritableMap mapAccountFiatProperties(AccountFiatProperties accountFiatProperties) {
        WritableMap fiatProperties = Arguments.createMap();
        if (accountFiatProperties.getProviderId() == null) {
            fiatProperties.putNull("providerId");
        } else {
            fiatProperties.putString("providerId", accountFiatProperties.getProviderId());
        }

        if (accountFiatProperties.getAccountNumber() == null) {
            fiatProperties.putNull("accountNumber");
        } else {
            fiatProperties.putString("accountNumber", accountFiatProperties.getAccountNumber());
        }

        if (accountFiatProperties.getSortCode() == null) {
            fiatProperties.putNull("sortCode");
        } else {
            fiatProperties.putString("sortCode", accountFiatProperties.getSortCode());
        }

        if (accountFiatProperties.getBic() == null) {
            fiatProperties.putNull("bic");
        } else {
            fiatProperties.putString("bic", accountFiatProperties.getBic());
        }

        if (accountFiatProperties.getIban() == null) {
            fiatProperties.putNull("iban");
        } else {
            fiatProperties.putString("iban", accountFiatProperties.getIban());
        }

        if (accountFiatProperties.getCustomerName() == null) {
            fiatProperties.putNull("customerName");
        } else {
            fiatProperties.putString("customerName", accountFiatProperties.getCustomerName());
        }

        return fiatProperties;
    }

    public static WritableMap mapCard(Card card) {
        WritableMap map = Arguments.createMap();

        map.putString("id", card.getId());
        map.putString("accountId", card.getAccountId());
        map.putString("cardType", card.getCardType());
        map.putString("cardStatus", card.getCardStatus());
        map.putInt("limit", card.getLimit());
        if (card.getMaskedPan() == null) {
            map.putNull("maskedPan");
        } else {
            map.putString("maskedPan", card.getMaskedPan());
        }
        map.putString("expiry", card.getExpiry());
        map.putBoolean("sca", card.getSca());

        return map;
    }

    public static WritableMap mapAccount(Account account) {
        WritableMap cryptoProperties = Arguments.createMap();
        if (account.getCryptoProperties() != null) {
            cryptoProperties.putString("path", account.getCryptoProperties().getPath());
            cryptoProperties.putString("address", account.getCryptoProperties().getAddress());

            if (account.getCryptoProperties().getDirectDepositAddress() == null) {
                cryptoProperties.putNull("directDepositAddress");
            } else {
                cryptoProperties.putString("directDepositAddress", account.getCryptoProperties().getDirectDepositAddress());
            }

            if (account.getCryptoProperties().getNonce() == null) {
                cryptoProperties.putNull("nonce");
            } else {
                cryptoProperties.putInt("nonce", account.getCryptoProperties().getNonce());
            }
        }

        WritableMap map = Arguments.createMap();

        map.putString("id", account.getId());
        map.putString("currencyType", account.getCurrencyType());
        map.putString("currencyCode", account.getCurrencyCode());
        map.putString("network", account.getNetwork());
        map.putString("type", account.getType());
        map.putString("custodyType", account.getCustodyType());
        map.putString("balance", account.getBalance().toPlainString());
        map.putString("ledgerBalance", account.getLedgerBalance().toPlainString());
        map.putString("availableBalance", account.getAvailableBalance().toPlainString());
        map.putString("overdraftLimit", account.getOverdraftLimit().toPlainString());
        map.putBoolean("hasNominatedAccount", account.getHasNominatedAccount());

        if (account.getCryptoProperties() == null) {
            map.putNull("cryptoProperties");
        } else {
            map.putMap("cryptoProperties", cryptoProperties);
        }

        if (account.getFiatProperties() == null) {
            map.putNull("fiatProperties");
        } else {
            map.putMap("fiatProperties", mapAccountFiatProperties(account.getFiatProperties()));
        }

        WritableArray cards = Arguments.createArray();
        for (Card card : account.getCards()) {
            cards.pushMap(RNZumoKitModule.mapCard(card));
        }
        map.putArray("cards", cards);

        return map;
    }

    public static WritableArray mapAccounts(ArrayList<Account> accounts) {
        WritableArray response = Arguments.createArray();

        for (Account account : accounts) {
            response.pushMap(mapAccount(account));
        }

        return response;
    }

    public static WritableMap mapComposedTransaction(ComposedTransaction transaction) {
        WritableMap map = Arguments.createMap();

        map.putString("type", transaction.getType());

        if (transaction.getCustodyOrderId() == null) {
            map.putNull("custodyOrderId");
        } else {
            map.putString("custodyOrderId", transaction.getCustodyOrderId());
        }

        if (transaction.getSignedTransaction() == null) {
            map.putNull("signedTransaction");
        } else {
            map.putString("signedTransaction", transaction.getSignedTransaction());
        }

        map.putMap("account", mapAccount(transaction.getAccount()));
        map.putString("fee", transaction.getFee().toPlainString());

        if (transaction.getDestination() == null) {
            map.putNull("destination");
        } else {
            map.putString("destination", transaction.getDestination());
        }

        if (transaction.getAmount() == null) {
            map.putNull("amount");
        } else {
            map.putString("amount", transaction.getAmount().toPlainString());
        }

        if (transaction.getData() == null) {
            map.putNull("data");
        } else {
            map.putString("data", transaction.getData());
        }

        map.putString("nonce", transaction.getNonce());

        return map;
    }

    public static WritableArray mapTransactionAmounts(ArrayList<TransactionAmount> transactionAmounts) {
        WritableArray response = Arguments.createArray();

        for (TransactionAmount transactionAmount : transactionAmounts) {
            WritableMap map = RNZumoKitModule.mapTransactionAmount(transactionAmount);
            response.pushMap(map);
        }

        return response;
    }

    public static WritableArray mapInternalTransactions(ArrayList<InternalTransaction> internalTransactions) {
        WritableArray response = Arguments.createArray();

        for (InternalTransaction internalTransaction : internalTransactions) {
            WritableMap map = RNZumoKitModule.mapInternalTransaction(internalTransaction);
            response.pushMap(map);
        }

        return response;
    }

    public static WritableArray mapTransactions(ArrayList<Transaction> transactions) {
        WritableArray response = Arguments.createArray();

        for (Transaction transaction : transactions) {
            WritableMap map = RNZumoKitModule.mapTransaction(transaction);
            response.pushMap(map);
        }

        return response;
    }

    public static WritableMap mapTransactionAmount(TransactionAmount transactionAmount) {
        WritableMap map = Arguments.createMap();

        map.putString("direction", transactionAmount.getDirection());

        if (transactionAmount.getUserId() == null) {
            map.putNull("userId");
        } else {
            map.putString("userId", transactionAmount.getUserId());
        }

        if (transactionAmount.getUserIntegratorId() == null) {
            map.putNull("userIntegratorId");
        } else {
            map.putString("userIntegratorId", transactionAmount.getUserIntegratorId());
        }

        if (transactionAmount.getAccountId() == null) {
            map.putNull("accountId");
        } else {
            map.putString("accountId", transactionAmount.getAccountId());
        }

        if (transactionAmount.getAmount() == null) {
            map.putNull("amount");
        } else {
            map.putString("amount", transactionAmount.getAmount().toPlainString());
        }

        if (transactionAmount.getFiatAmount() == null) {
            map.putNull("fiatAmount");
        } else {
            WritableMap fiatAmounts = Arguments.createMap();
            for (HashMap.Entry entry : transactionAmount.getFiatAmount().entrySet()) {
                fiatAmounts.putDouble((String) entry.getKey(), ((Double) entry.getValue()));
            }
            map.putMap("fiatAmount", fiatAmounts);
        }

        if (transactionAmount.getAddress() == null) {
            map.putNull("address");
        } else {
            map.putString("address", transactionAmount.getAddress());
        }

        map.putBoolean("isChange", transactionAmount.getIsChange());

        if (transactionAmount.getAccountNumber() == null) {
            map.putNull("accountNumber");
        } else {
            map.putString("accountNumber", transactionAmount.getAccountNumber());
        }

        if (transactionAmount.getSortCode() == null) {
            map.putNull("sortCode");
        } else {
            map.putString("sortCode", transactionAmount.getSortCode());
        }

        if (transactionAmount.getBic() == null) {
            map.putNull("bic");
        } else {
            map.putString("bic", transactionAmount.getBic());
        }

        if (transactionAmount.getIban() == null) {
            map.putNull("iban");
        } else {
            map.putString("iban", transactionAmount.getIban());
        }

        return map;
    }

    public static WritableMap mapInternalTransaction(InternalTransaction internalTransaction) {
        WritableMap map = Arguments.createMap();

        if (internalTransaction.getFromUserId() == null) {
            map.putNull("fromUserId");
        } else {
            map.putString("fromUserId", internalTransaction.getFromUserId());
        }

        if (internalTransaction.getFromUserIntegratorId() == null) {
            map.putNull("fromUserIntegratorId");
        } else {
            map.putString("fromUserIntegratorId", internalTransaction.getFromUserIntegratorId());
        }

        if (internalTransaction.getFromAccountId() == null) {
            map.putNull("fromAccountId");
        } else {
            map.putString("fromAccountId", internalTransaction.getFromAccountId());
        }

        if (internalTransaction.getFromAddress() == null) {
            map.putNull("fromAddress");
        } else {
            map.putString("fromAddress", internalTransaction.getFromAddress());
        }

        if (internalTransaction.getToUserId() == null) {
            map.putNull("toUserId");
        } else {
            map.putString("toUserId", internalTransaction.getToUserId());
        }

        if (internalTransaction.getToUserIntegratorId() == null) {
            map.putNull("toUserIntegratorId");
        } else {
            map.putString("toUserIntegratorId", internalTransaction.getToUserIntegratorId());
        }

        if (internalTransaction.getToAccountId() == null) {
            map.putNull("toAccountId");
        } else {
            map.putString("toAccountId", internalTransaction.getToAccountId());
        }

        if (internalTransaction.getToAddress() == null) {
            map.putNull("toAddress");
        } else {
            map.putString("toAddress", internalTransaction.getToAddress());
        }

        if (internalTransaction.getAmount() == null) {
            map.putNull("amount");
        } else {
            map.putString("amount", internalTransaction.getAmount().toPlainString());
        }

        if (internalTransaction.getFiatAmount() == null) {
            map.putNull("fiatAmount");
        } else {
            WritableMap fiatAmounts = Arguments.createMap();
            for (HashMap.Entry entry : internalTransaction.getFiatAmount().entrySet()) {
                fiatAmounts.putDouble((String) entry.getKey(), ((Double) entry.getValue()));
            }
            map.putMap("fiatAmount", fiatAmounts);
        }

        return map;
    }

    public static WritableMap mapTransaction(Transaction transaction) {
        WritableMap map = Arguments.createMap();

        map.putString("id", transaction.getId());
        map.putString("type", transaction.getType());
        map.putString("currencyCode", transaction.getCurrencyCode());
        map.putString("direction", transaction.getDirection());
        map.putString("network", transaction.getNetwork());
        map.putString("status", transaction.getStatus());

        WritableArray senders = RNZumoKitModule.mapTransactionAmounts(transaction.getSenders());
        map.putArray("senders", senders);

        WritableArray recipients = RNZumoKitModule.mapTransactionAmounts(transaction.getRecipients());
        map.putArray("recipients", recipients);

        WritableArray internalTransactions = RNZumoKitModule.mapInternalTransactions(transaction.getInternalTransactions());
        map.putArray("internalTransactions", internalTransactions);

        if (transaction.getAmount() == null) {
            map.putNull("amount");
        } else {
            map.putString("amount", transaction.getAmount().toPlainString());
        }

        if (transaction.getFee() == null) {
            map.putNull("fee");
        } else {
            map.putString("fee", transaction.getFee().toPlainString());
        }

        if (transaction.getNonce() == null) {
            map.putNull("nonce");
        } else {
            map.putString("nonce", transaction.getNonce());
        }

        if (transaction.getMetadata() == null) {
            map.putNull("metadata");
        } else {
            map.putString("metadata", transaction.getMetadata());
        }

        if (transaction.getSubmittedAt() == null) {
            map.putNull("submittedAt");
        } else {
            map.putInt("submittedAt", transaction.getSubmittedAt());
        }

        if (transaction.getConfirmedAt() == null) {
            map.putNull("confirmedAt");
        } else {
            map.putInt("confirmedAt", transaction.getConfirmedAt());
        }

        map.putInt("timestamp", transaction.getTimestamp());

        if (transaction.getCryptoProperties() == null) {
            map.putNull("cryptoProperties");
        } else {
            WritableMap cryptoProperties = Arguments.createMap();

            if (transaction.getCryptoProperties().getTxHash() == null) {
                cryptoProperties.putNull("txHash");
            } else {
                cryptoProperties.putString("txHash", transaction.getCryptoProperties().getTxHash());
            }

            if (transaction.getCryptoProperties().getNonce() == null) {
                cryptoProperties.putNull("nonce");
            } else {
                cryptoProperties.putInt("nonce",
                        transaction.getCryptoProperties().getNonce());
            }

            cryptoProperties.putString("fromAddress",
                    transaction.getCryptoProperties().getFromAddress());

            if (transaction.getCryptoProperties().getToAddress() == null) {
                cryptoProperties.putNull("toAddress");
            } else {
                cryptoProperties.putString("toAddress",
                        transaction.getCryptoProperties().getToAddress());
            }

            if (transaction.getCryptoProperties().getData() == null) {
                cryptoProperties.putNull("data");
            } else {
                cryptoProperties.putString("data",
                        transaction.getCryptoProperties().getData());
            }

            if (transaction.getCryptoProperties().getGasPrice() == null) {
                cryptoProperties.putNull("gasPrice");
            } else {
                cryptoProperties.putString("gasPrice",
                        transaction.getCryptoProperties().getGasPrice().toPlainString());
            }

            if (transaction.getCryptoProperties().getGasLimit() == null) {
                cryptoProperties.putNull("gasLimit");
            } else {
                cryptoProperties.putInt("gasLimit",
                        transaction.getCryptoProperties().getGasLimit());
            }

            if (transaction.getCryptoProperties().getFiatAmount() == null) {
                cryptoProperties.putNull("fiatAmount");
            } else {
                WritableMap fiatAmounts = Arguments.createMap();
                for (HashMap.Entry entry :
                        transaction.getCryptoProperties().getFiatAmount().entrySet()) {
                    fiatAmounts.putDouble((String) entry.getKey(), ((Double) entry.getValue()));
                }
                cryptoProperties.putMap("fiatAmount", fiatAmounts);
            }

            if (transaction.getCryptoProperties().getFiatFee() == null) {
                cryptoProperties.putNull("fiatFee");
            } else {
                WritableMap fiatFee = Arguments.createMap();
                for (HashMap.Entry entry :
                        transaction.getCryptoProperties().getFiatFee().entrySet()) {
                    fiatFee.putDouble((String) entry.getKey(), ((Double) entry.getValue()));
                }
                cryptoProperties.putMap("fiatFee", fiatFee);
            }

            map.putMap("cryptoProperties", cryptoProperties);
        }

        if (transaction.getFiatProperties() == null) {
            map.putNull("fiatProperties");
        } else {
            WritableMap fiatProperties = Arguments.createMap();

            if (transaction.getFiatProperties().getFromFiatAccount() == null) {
                fiatProperties.putNull("fromFiatAccount");
            } else {
                fiatProperties.putMap("fromFiatAccount",
                        mapAccountFiatProperties(
                                transaction.getFiatProperties().getFromFiatAccount()));
            }

            if (transaction.getFiatProperties().getToFiatAccount() == null) {
                fiatProperties.putNull("toFiatAccount");
            } else {
                fiatProperties.putMap("toFiatAccount",
                        mapAccountFiatProperties(
                                transaction.getFiatProperties().getToFiatAccount()));
            }

            map.putMap("fiatProperties", fiatProperties);
        }

        if (transaction.getCardProperties() == null) {
            map.putNull("cardProperties");
        } else {
            WritableMap cardProperties = Arguments.createMap();

            cardProperties.putString("cardId", transaction.getCardProperties().getCardId());
            cardProperties.putString("transactionAmount",
                    transaction.getCardProperties().getTransactionAmount().toPlainString());
            cardProperties.putString("transactionCurrency",
                    transaction.getCardProperties().getTransactionCurrency());
            cardProperties.putString("billingAmount",
                    transaction.getCardProperties().getBillingAmount().toPlainString());
            cardProperties.putString("billingCurrency",
                    transaction.getCardProperties().getBillingCurrency());
            cardProperties.putString("exchangeRateValue",
                    transaction.getCardProperties().getExchangeRateValue().toPlainString());

            if (transaction.getCardProperties().getMcc() == null) {
                cardProperties.putNull("mcc");
            } else {
                cardProperties.putString("mcc", transaction.getCardProperties().getMcc());
            }

            if (transaction.getCardProperties().getMcc() == null) {
                cardProperties.putNull("mcc");
            } else {
                cardProperties.putString("mcc", transaction.getCardProperties().getMcc());
            }

            if (transaction.getCardProperties().getMerchantName() == null) {
                cardProperties.putNull("merchantName");
            } else {
                cardProperties.putString("merchantName",
                        transaction.getCardProperties().getMerchantName());
            }

            if (transaction.getCardProperties().getMerchantCountry() == null) {
                cardProperties.putNull("merchantCountry");
            } else {
                cardProperties.putString("merchantCountry",
                        transaction.getCardProperties().getMerchantCountry());
            }

            map.putMap("cardProperties", cardProperties);
        }

        if (transaction.getCustodyOrder() == null) {
            map.putNull("custodyOrder");
        } else {
            WritableMap custodyOrder = Arguments.createMap();

            custodyOrder.putString("id", transaction.getCustodyOrder().getId());
            custodyOrder.putString("type", transaction.getCustodyOrder().getType());
            custodyOrder.putString("status", transaction.getCustodyOrder().getStatus());

            if (transaction.getCustodyOrder().getAmount() == null) {
                custodyOrder.putNull("amount");
            } else {
                custodyOrder.putString("amount",
                        transaction.getCustodyOrder().getAmount().toPlainString());
            }

            custodyOrder.putBoolean("feeInAmount", transaction.getCustodyOrder().getFeeInAmount());

            if (transaction.getCustodyOrder().getEstimatedFees() == null) {
                custodyOrder.putNull("estimatedFees");
            } else {
                custodyOrder.putString("estimatedFees",
                        transaction.getCustodyOrder().getEstimatedFees().toPlainString());
            }

            if (transaction.getCustodyOrder().getFees() == null) {
                custodyOrder.putNull("fees");
            } else {
                custodyOrder.putString("fees",
                        transaction.getCustodyOrder().getFees().toPlainString());
            }

            if (transaction.getCustodyOrder().getFromAddresses() == null) {
                custodyOrder.putNull("fromAddresses");
            } else {
                WritableArray fromAddresses = Arguments.createArray();

                for (String address : transaction.getCustodyOrder().getFromAddresses()) {
                    fromAddresses.pushString(address);
                }

                custodyOrder.putArray("fromAddresses", fromAddresses);
            }

            if (transaction.getCustodyOrder().getFromAccountId() == null) {
                custodyOrder.putNull("fromAccountId");
            } else {
                custodyOrder.putString("fromAccountId",
                        transaction.getCustodyOrder().getFromAccountId());
            }

            if (transaction.getCustodyOrder().getFromUserId() == null) {
                custodyOrder.putNull("fromUserId");
            } else {
                custodyOrder.putString("fromUserId", transaction.getCustodyOrder().getFromUserId());
            }

            if (transaction.getCustodyOrder().getFromUserIntegratorId() == null) {
                custodyOrder.putNull("fromUserIntegratorId");
            } else {
                custodyOrder.putString("fromUserIntegratorId",
                        transaction.getCustodyOrder().getFromUserIntegratorId());
            }

            if (transaction.getCustodyOrder().getToAddress() == null) {
                custodyOrder.putNull("toAddress");
            } else {
                custodyOrder.putString("toAddress", transaction.getCustodyOrder().getToAddress());
            }

            if (transaction.getCustodyOrder().getToAccountId() == null) {
                custodyOrder.putNull("toAccountId");
            } else {
                custodyOrder.putString("toAccountId", transaction.getCustodyOrder().getToAccountId());
            }

            if (transaction.getCustodyOrder().getToUserId() == null) {
                custodyOrder.putNull("toUserId");
            } else {
                custodyOrder.putString("toUserId", transaction.getCustodyOrder().getToUserId());
            }

            if (transaction.getCustodyOrder().getToUserIntegratorId() == null) {
                custodyOrder.putNull("toUserIntegratorId");
            } else {
                custodyOrder.putString("toUserIntegratorId",
                        transaction.getCustodyOrder().getToUserIntegratorId());
            }

            custodyOrder.putInt("createdAt", transaction.getCustodyOrder().getCreatedAt());
            custodyOrder.putInt("updatedAt", transaction.getCustodyOrder().getUpdatedAt());

            map.putMap("custodyOrder", custodyOrder);
        }

        if (transaction.getExchange() == null) {
            map.putNull("exchange");
        } else {
            map.putMap("exchange", mapExchange(transaction.getExchange()));
        }

        return map;
    }

    public static WritableMap mapTransactionFeeRate(TransactionFeeRate rate) {
       WritableMap mappedRates = Arguments.createMap();

       mappedRates.putString("slow", rate.getSlow().toPlainString());
       mappedRates.putString("average", rate.getAverage().toPlainString());
       mappedRates.putString("fast", rate.getFast().toPlainString());
       mappedRates.putDouble("slowTime", rate.getSlowTime());
       mappedRates.putDouble("averageTime", rate.getAverageTime());
       mappedRates.putDouble("fastTime", rate.getFastTime());
       mappedRates.putString("source", rate.getSource());

       return mappedRates;
    }

    public static WritableMap mapTransactionFeeRates(HashMap<String, TransactionFeeRate> feeRates) {
        WritableMap map = Arguments.createMap();

        for (HashMap.Entry<String, TransactionFeeRate> entry : feeRates.entrySet()) {
            String currency = entry.getKey();
            TransactionFeeRate feeRate = entry.getValue();

            map.putMap(currency, mapTransactionFeeRate(feeRate));
        }

        return map;
    }

    public static WritableMap mapComposedExchange(ComposedExchange exchange) {
        WritableMap map = Arguments.createMap();

        map.putMap("debitAccount", RNZumoKitModule.mapAccount(exchange.getDebitAccount()));
        map.putMap("creditAccount", RNZumoKitModule.mapAccount(exchange.getCreditAccount()));
        map.putMap("quote", RNZumoKitModule.mapQuote(exchange.getQuote()));

        return map;
    }

    public static WritableMap mapExchange(Exchange exchange) {
        WritableMap map = Arguments.createMap();

        map.putString("id", exchange.getId());
        map.putString("status", exchange.getStatus());
        map.putString("pair", exchange.getPair());
        map.putString("side", exchange.getSide());
        map.putString("price", exchange.getPrice().toPlainString());
        map.putString("amount", exchange.getAmount().toPlainString());
        map.putString("debitAccountId", exchange.getDebitAccountId());
        map.putString("creditAccountId", exchange.getCreditAccountId());

        if (exchange.getDebitTransactionId() == null) {
            map.putNull("debitTransactionId");
        } else {
            map.putString("debitTransactionId", exchange.getDebitTransactionId());
        }

        if (exchange.getCreditTransactionId() == null) {
            map.putNull("creditTransactionId");
        } else {
            map.putString("creditTransactionId", exchange.getCreditTransactionId());
        }

        map.putMap("quote", RNZumoKitModule.mapQuote(exchange.getQuote()));

        WritableMap rates = Arguments.createMap();
        for (HashMap.Entry<String, HashMap<String, BigDecimal>> outerEntry :
                exchange.getRates().entrySet()) {
            String fromCurrency = outerEntry.getKey();
            WritableMap innerMap = Arguments.createMap();

            for (HashMap.Entry<String, BigDecimal> innerEntry :
                    outerEntry.getValue().entrySet()) {
                String toCurrency = innerEntry.getKey();
                String rate = innerEntry.getValue().toPlainString();
                innerMap.putString(toCurrency, rate);
            }

            rates.putMap(fromCurrency, innerMap);
        }
        map.putMap("rates", rates);

        if (exchange.getNonce() == null) {
            map.putNull("nonce");
        } else {
            map.putString("nonce", exchange.getNonce());
        }

        map.putString("createdAt", exchange.getCreatedAt());
        map.putString("updatedAt", exchange.getUpdatedAt());

        return map;
    }

    public static WritableArray mapExchanges(ArrayList<Exchange> exchanges) {
        WritableArray response = Arguments.createArray();

        for (Exchange exchange : exchanges) {
            WritableMap map = RNZumoKitModule.mapExchange(exchange);
            response.pushMap(map);
        }

        return response;
    }

    public static WritableMap mapExchangeRate(ExchangeRate rate) {
        WritableMap mappedRate = Arguments.createMap();

        mappedRate.putString("id", rate.getId());
        mappedRate.putString("fromCurrency", rate.getFromCurrency());
        mappedRate.putString("toCurrency", rate.getToCurrency());
        mappedRate.putString("value", rate.getValue().toPlainString());
        mappedRate.putInt("timestamp", rate.getTimestamp());

        return mappedRate;
    }

    public static WritableMap mapQuote(Quote quote) {
        WritableMap mappedQuote = Arguments.createMap();

        mappedQuote.putString("id", quote.getId());
        mappedQuote.putInt("ttl", quote.getTtl());
        mappedQuote.putString("createdAt", quote.getCreatedAt());
        mappedQuote.putString("expiresAt", quote.getExpiresAt());
        mappedQuote.putString("debitCurrency", quote.getDebitCurrency());
        mappedQuote.putString("creditCurrency", quote.getCreditCurrency());
        mappedQuote.putString("price", quote.getPrice().toPlainString());
        mappedQuote.putString("feeRate", quote.getFeeRate().toPlainString());
        mappedQuote.putString("debitAmount", quote.getDebitAmount().toPlainString());
        mappedQuote.putString("feeAmount", quote.getFeeAmount().toPlainString());
        mappedQuote.putString("creditAmount", quote.getCreditAmount().toPlainString());

        return mappedQuote;
    }

    public static WritableMap mapExchangeRates(
            HashMap<String, HashMap<String, ExchangeRate>> exchangeRates
    ) {
        WritableMap outerMap = Arguments.createMap();

        for (HashMap.Entry<String, HashMap<String, ExchangeRate>> outerEntry :
                exchangeRates.entrySet()) {
            String fromCurrency = outerEntry.getKey();
            WritableMap innerMap = Arguments.createMap();

            for (HashMap.Entry<String, ExchangeRate> innerEntry :
                    outerEntry.getValue().entrySet()) {
                String toCurrency = innerEntry.getKey();
                WritableMap rate = RNZumoKitModule.mapExchangeRate(innerEntry.getValue());
                innerMap.putMap(toCurrency, rate);
            }

            outerMap.putMap(fromCurrency, innerMap);
        }

        return outerMap;
    }


    public static WritableMap mapHistoricalExchangeRates(HashMap<String, HashMap<String, HashMap<String, ArrayList<ExchangeRate>>>> historicalExchangeRates) {
        WritableMap outerOuterMap = Arguments.createMap();

        for (HashMap.Entry<String, HashMap<String, HashMap<String, ArrayList<ExchangeRate>>>> outerOuterEntry : historicalExchangeRates.entrySet()) {

            String timeInterval = outerOuterEntry.getKey();
            WritableMap outerMap = Arguments.createMap();

            for (HashMap.Entry<String, HashMap<String, ArrayList<ExchangeRate>>> outerEntry : outerOuterEntry.getValue().entrySet()) {

                String fromCurrency = outerEntry.getKey();
                WritableMap innerMap = Arguments.createMap();

                for (HashMap.Entry<String, ArrayList<ExchangeRate>> innerEntry : outerEntry.getValue().entrySet()) {

                    String toCurrency = innerEntry.getKey();

                    WritableArray array = Arguments.createArray();

                    for (ExchangeRate rate : innerEntry.getValue()) {
                        WritableMap map = RNZumoKitModule.mapExchangeRate(rate);
                        array.pushMap(map);
                    }

                    innerMap.putArray(toCurrency, array);
                }

                outerMap.putMap(fromCurrency, innerMap);
            }

            outerOuterMap.putMap(timeInterval, outerMap);
        }

        return outerOuterMap;
    }

  public static WritableMap mapAccountDataSnapshot(AccountDataSnapshot snapshot) {
      WritableMap map = Arguments.createMap();

      WritableMap account = RNZumoKitModule.mapAccount(snapshot.getAccount());
      map.putMap("account", account);

      WritableArray transactions = RNZumoKitModule.mapTransactions(snapshot.getTransactions());
      map.putArray("transactions", transactions);

      return map;
  }


  public static WritableArray mapAccountData(ArrayList<AccountDataSnapshot> snapshots) {
      WritableArray res = Arguments.createArray();

      for (AccountDataSnapshot snapshot : snapshots) {
        res.pushMap(mapAccountDataSnapshot(snapshot));
      }

      return res;
    }

    public static WritableMap mapKbaQuestion(KbaQuestion question) {
        WritableMap mappedQuestion = Arguments.createMap();

        mappedQuestion.putString("type", question.getType());
        mappedQuestion.putString("question", question.getQuestion());

        return mappedQuestion;
    }

    public static WritableMap mapAuthenticationConfig(AuthenticationConfig config) {
        WritableArray knowledgeBase = Arguments.createArray();

        for (KbaQuestion question : config.getKnowledgeBase()) {
            knowledgeBase.pushMap(mapKbaQuestion(question));
        }

        WritableMap mappedConfig = Arguments.createMap();

        mappedConfig.putArray("knowledgeBase", knowledgeBase);

        return mappedConfig;
    }

    public static Account unboxAccount(ReadableMap map) {
        AccountCryptoProperties cryptoProperties = null;
        if (!map.isNull("cryptoProperties")) {
            ReadableMap cryptoPropertiesData = map.getMap("cryptoProperties");

            String address = cryptoPropertiesData.getString("address");

            String directDepositAddress = null;
            if (!cryptoPropertiesData.isNull("directDepositAddress")) {
                directDepositAddress = cryptoPropertiesData.getString("directDepositAddress");
            }

            String path = cryptoPropertiesData.getString("path");

            Integer nonce = null;
            if (!cryptoPropertiesData.isNull("nonce")) {
                nonce = cryptoPropertiesData.getInt("nonce");
            }

            cryptoProperties = new AccountCryptoProperties(address, directDepositAddress, path, nonce);
        }

        AccountFiatProperties fiatProperties = null;
        if (!map.isNull("fiatProperties")) {
            ReadableMap fiatPropertiesData = map.getMap("fiatProperties");

            String providerId = fiatPropertiesData.getString("providerId");
            String accountNumber = fiatPropertiesData.getString("accountNumber");
            String sortCode = fiatPropertiesData.getString("sortCode");
            String bic = fiatPropertiesData.getString("bic");
            String iban = fiatPropertiesData.getString("iban");
            String customerName = fiatPropertiesData.getString("customerName");

            fiatProperties = new AccountFiatProperties(providerId, accountNumber, sortCode, bic, iban, customerName);
        }

        String accountId = map.getString("id");
        String currencyType = map.getString("currencyType");
        String currencyCode = map.getString("currencyCode");
        String network = map.getString("network");
        String type = map.getString("type");
        String custodyType = map.getString("custodyType");
        BigDecimal balance = new BigDecimal(map.getString("balance"));
        BigDecimal ledgerBalance = new BigDecimal(map.getString("ledgerBalance"));
        BigDecimal availableBalance = new BigDecimal(map.getString("availableBalance"));
        BigDecimal overdraftLimit = new BigDecimal(map.getString("overdraftLimit"));
        Boolean hasNominatedAccount = map.getBoolean("hasNominatedAccount");

        ReadableArray cardsArray =  map.getArray("cards");
        ArrayList<Card> cards = new ArrayList<Card>();
        for (int i = 0; i < cards.size(); i++) {
            cards.add(RNZumoKitModule.unboxCard(cardsArray.getMap(i)));
        }

        return new Account(
                accountId,
                currencyType,
                currencyCode,
                network,
                type,
                custodyType,
                balance,
                ledgerBalance,
                availableBalance,
                overdraftLimit,
                hasNominatedAccount,
                cryptoProperties,
                fiatProperties,
                cards
        );
    }

    public static Quote unboxQuote(ReadableMap map) {
        String id = map.getString("id");
        int ttl = map.getInt("ttl");
        String createdAt = map.getString("createdAt");
        String expiresAt = map.getString("expiresAt");
        String debitCurrency = map.getString("debitCurrency");
        String creditCurrency = map.getString("creditCurrency");
        BigDecimal price = new BigDecimal(map.getString("price"));
        BigDecimal feeRate = new BigDecimal(map.getString("feeRate"));
        BigDecimal debitAmount = new BigDecimal(map.getString("debitAmount"));
        BigDecimal feeAmount = new BigDecimal(map.getString("feeAmount"));
        BigDecimal creditAmount = new BigDecimal(map.getString("creditAmount"));

        return new Quote(
                id,
                ttl,
                createdAt,
                expiresAt,
                debitCurrency,
                creditCurrency,
                price,
                feeRate,
                debitAmount,
                feeAmount,
                creditAmount
        );
    }

    public static Address unboxAddress(ReadableMap map) {
        String houseNumber = map.getString("houseNumber");
        String addressLine1 = map.getString("addressLine1");
        String addressLine2 = map.getString("addressLine2");
        String country = map.getString("country");
        String postCode = map.getString("postCode");
        String postTown = map.getString("postTown");

        return new Address(
                houseNumber,
                addressLine1,
                addressLine2,
                country,
                postCode,
                postTown
        );
    }

    public static Card unboxCard(ReadableMap map) {
        String cardId = map.getString("cardId");
        String accountId = map.getString("accountId");
        String cardType = map.getString("cardType");
        String cardStatus = map.getString("cardStatus");
        int limit = map.getInt("limit");
        String maskedPan = map.getString("maskedPan");
        String expiry = map.getString("expiry");
        Boolean sca = map.getBoolean("sca");

        return new Card(
                cardId,
                accountId,
                cardType,
                cardStatus,
                limit,
                maskedPan,
                expiry,
                sca
        );
    }

    public static KbaAnswer unboxKbaAnswer(ReadableMap map) {
        String type = map.getString("type");
        String answer = map.getString("answer");

        return new KbaAnswer(type, answer);
    }

    public static ArrayList<KbaAnswer> unboxKnowledgeBase(ReadableArray knowledgeBase) {
        ArrayList<KbaAnswer> res = new ArrayList<KbaAnswer>();
        for (int i = 0; i < knowledgeBase.size(); i++) {
            res.add(RNZumoKitModule.unboxKbaAnswer(knowledgeBase.getMap(i)));
        }

        return res;
    }

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put("version", ZumoKit.getVersion());
        return constants;
    }

    @Override
    public String getName() {
        return "RNZumoKit";
    }
}