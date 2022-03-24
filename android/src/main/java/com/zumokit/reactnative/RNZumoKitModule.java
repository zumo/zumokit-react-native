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
import money.zumo.zumokit.Exchange;
import money.zumo.zumokit.ExchangeSetting;
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
import money.zumo.zumokit.ComposedTransaction;
import money.zumo.zumokit.ComposeTransactionCallback;
import money.zumo.zumokit.SubmitTransactionCallback;
import money.zumo.zumokit.AccountDataListener;
import money.zumo.zumokit.AccountCallback;
import money.zumo.zumokit.TransactionFeeRate;
import money.zumo.zumokit.ExchangeRate;
import money.zumo.zumokit.Quote;
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
        String notificationServiceUrl) {
        this.user = null;
        this.wallet = null;
        this.zumokit = new ZumoKit(
            apiKey, 
            apiUrl, 
            transactionServiceUrl, 
            cardServiceUrl,
            notificationServiceUrl);

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
    public void isFiatCustomer(String network, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        promise.resolve(this.user.isFiatCustomer(network));
    }

    @ReactMethod
    public void makeFiatCustomer(
            String network,
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
                network,
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
    public void createFiatAccount(String network, String currencyCode, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        this.user.createFiatAccount(network, currencyCode, new AccountCallback() {
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
    public void getAccount(String symbol, String network, String type, Promise promise) {
        if (this.user == null) {
            rejectPromise(promise, "User not found.");
            return;
        }

        Account account = this.user.getAccount(symbol, network, type);

        if (account == null) {
            rejectPromise(promise, "Account not found.");
            return;
        }

        WritableMap response = RNZumoKitModule.mapAccount(account);
        promise.resolve(response);
    }

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
    public void submitTransaction(ReadableMap composedTransactionMap, String metadata, Promise promise) {
        if (this.wallet == null) {
            rejectPromise(promise, "Wallet not found.");
            return;
        }

        String type = composedTransactionMap.getString("type");
        String signedTransaction = composedTransactionMap.getString("signedTransaction");
        Account account = RNZumoKitModule.unboxAccount(composedTransactionMap.getMap("account"));
        String destination = composedTransactionMap.getString("destination");
        BigDecimal amount = new BigDecimal(composedTransactionMap.getString("amount"));
        String data = composedTransactionMap.getString("data");
        BigDecimal fee = new BigDecimal(composedTransactionMap.getString("fee"));
        String nonce = composedTransactionMap.getString("nonce");

        ComposedTransaction composedTransaction =
                new ComposedTransaction(
                        type,
                        signedTransaction,
                        account,
                        destination,
                        amount,
                        data,
                        fee,
                        nonce
                );

        this.wallet.submitTransaction(composedTransaction, metadata, new SubmitTransactionCallback() {

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
    public void composeTransaction(
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
    public void composeInternalFiatTransaction(
            String fromAccountId,
            String toAccountId,
            String amount,
            Boolean sendMax,
            Promise promise
    ) {
        if (this.wallet == null) {
            rejectPromise(promise, "Wallet not found.");
            return;
        }

        this.wallet.composeInternalFiatTransaction(
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
    public void composeTransactionToNominatedAccount(
            String fromAccountId,
            String amount,
            Boolean sendMax,
            Promise promise
    ) {
        if (this.wallet == null) {
            rejectPromise(promise, "Wallet not found.");
            return;
        }

        this.wallet.composeTransactionToNominatedAccount(
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
    public void composeExchange(
            String fromAccountId,
            String toAccountId,
            String amount,
            Boolean sendMax,
            Promise promise
    ) {
        if (this.wallet == null) {
            rejectPromise(promise, "Wallet not found.");
            return;
        }

        this.wallet.composeExchange(
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
        if (this.wallet == null) {
            rejectPromise(promise, "Wallet not found.");
            return;
        }

        String signedTransaction = composedExchangeMap.getString("signedTransaction");
        Account fromAccount =
                RNZumoKitModule.unboxAccount(composedExchangeMap.getMap("fromAccount"));
        Account toAccount =
                RNZumoKitModule.unboxAccount(composedExchangeMap.getMap("toAccount"));
        Quote quote =
                RNZumoKitModule.unboxQuote(composedExchangeMap.getMap("quote"));
        ExchangeSetting exchangeSetting =
                RNZumoKitModule.unboxExchangeSetting(composedExchangeMap.getMap("exchangeSetting"));
        String exchangeAddress = composedExchangeMap.getString("exchangeAddress");
        BigDecimal amount = new BigDecimal(composedExchangeMap.getString("amount"));
        BigDecimal returnAmount = new BigDecimal(composedExchangeMap.getString("returnAmount"));
        BigDecimal outgoingTransactionFee = new BigDecimal(composedExchangeMap.getString("outgoingTransactionFee"));
        BigDecimal exchangeFee = new BigDecimal(composedExchangeMap.getString("exchangeFee"));
        BigDecimal returnTransactionFee = new BigDecimal(composedExchangeMap.getString("returnTransactionFee"));
        String nonce = composedExchangeMap.getString("nonce");

        ComposedExchange composedExchange = new ComposedExchange(
                signedTransaction,
                fromAccount,
                toAccount,
                quote,
                exchangeSetting,
                exchangeAddress,
                amount,
                returnAmount,
                outgoingTransactionFee,
                exchangeFee,
                returnTransactionFee,
                nonce
        );

        this.wallet.submitExchange(composedExchange, new SubmitExchangeCallback() {
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
    public void getExchangeSettings(Promise promise) {
        if (this.zumokit == null) {
            rejectPromise(promise, "ZumoKit not initialized.");
            return;
        }

        promise.resolve(mapExchangeSettings(this.zumokit.getExchangeSettings()));
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
        map.putString("balance", account.getBalance().toPlainString());
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

    public static WritableArray mapTransactions(ArrayList<Transaction> transactions) {
        WritableArray response = Arguments.createArray();

        for (Transaction transaction : transactions) {
            WritableMap map = RNZumoKitModule.mapTransaction(transaction);
            response.pushMap(map);
        }

        return response;
    }

    public static WritableMap mapTransaction(Transaction transaction) {
        WritableMap map = Arguments.createMap();

        map.putString("id", transaction.getId());
        map.putString("type", transaction.getType());
        map.putString("currencyCode", transaction.getCurrencyCode());
        map.putString("direction", transaction.getDirection());

        if (transaction.getFromUserId() == null) {
            map.putNull("fromUserId");
        } else {
            map.putString("fromUserId", transaction.getFromUserId());
        }

        if (transaction.getToUserId() == null) {
            map.putNull("toUserId");
        } else {
            map.putString("toUserId", transaction.getToUserId());
        }

        if (transaction.getFromAccountId() == null) {
            map.putNull("fromAccountId");
        } else {
            map.putString("fromAccountId", transaction.getFromAccountId());
        }

        if (transaction.getToAccountId() == null) {
            map.putNull("toAccountId");
        } else {
            map.putString("toAccountId", transaction.getToAccountId());
        }

        map.putString("network", transaction.getNetwork());
        map.putString("status", transaction.getStatus());

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

            WritableMap fiatAmounts = Arguments.createMap();
            for (HashMap.Entry entry :
                    transaction.getCryptoProperties().getFiatAmount().entrySet()) {
                fiatAmounts.putString((String) entry.getKey(),
                        ((BigDecimal) entry.getValue()).toPlainString());
            }
            cryptoProperties.putMap("fiatAmount", fiatAmounts);

            WritableMap fiatFee = Arguments.createMap();
            for (HashMap.Entry entry :
                    transaction.getCryptoProperties().getFiatFee().entrySet()) {
                fiatFee.putString((String) entry.getKey(),
                        ((BigDecimal) entry.getValue()).toPlainString());
            }
            cryptoProperties.putMap("fiatFee", fiatFee);

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

        map.putString("signedTransaction", exchange.getSignedTransaction());
        map.putMap("fromAccount", RNZumoKitModule.mapAccount(exchange.getFromAccount()));
        map.putMap("toAccount", RNZumoKitModule.mapAccount(exchange.getToAccount()));
        map.putMap("quote", RNZumoKitModule.mapQuote(exchange.getQuote()));
        map.putMap("exchangeSetting", RNZumoKitModule.mapExchangeSetting(
                exchange.getExchangeSetting()));

        if (exchange.getExchangeAddress() == null) {
            map.putNull("exchangeAddress");
        } else {
            map.putString("exchangeAddress", exchange.getExchangeAddress());
        }

        map.putString("amount", exchange.getAmount().toPlainString());
        map.putString("returnAmount", exchange.getReturnAmount().toPlainString());
        map.putString("outgoingTransactionFee",
                exchange.getOutgoingTransactionFee().toPlainString());
        map.putString("exchangeFee", exchange.getExchangeFee().toPlainString());
        map.putString("returnTransactionFee", exchange.getReturnTransactionFee().toPlainString());

        if (exchange.getNonce() == null) {
            map.putNull("nonce");
        } else {
            map.putString("nonce", exchange.getNonce());
        }

        return map;
    }

    public static WritableMap mapExchange(Exchange exchange) {
        WritableMap map = Arguments.createMap();

        map.putString("id", exchange.getId());
        map.putString("status", exchange.getStatus());
        map.putString("fromCurrency", exchange.getFromCurrency());
        map.putString("fromAccountId", exchange.getFromAccountId());
        map.putString("outgoingTransactionId", exchange.getOutgoingTransactionId());
        map.putString("toCurrency", exchange.getToCurrency());
        map.putString("toAccountId", exchange.getToAccountId());

        if (exchange.getReturnTransactionId() == null) {
            map.putNull("returnTransactionId");
        } else {
            map.putString("returnTransactionId", exchange.getReturnTransactionId());
        }

        map.putString("amount", exchange.getAmount().toPlainString());

        if (exchange.getOutgoingTransactionFee() == null) {
            map.putNull("outgoingTransactionFee");
        } else {
            map.putString("outgoingTransactionFee",
                    exchange.getOutgoingTransactionFee().toPlainString());
        }

        map.putString("returnAmount", exchange.getReturnAmount().toPlainString());
        map.putString("exchangeFee", exchange.getExchangeFee().toPlainString());
        map.putString("returnTransactionFee", exchange.getReturnTransactionFee().toPlainString());
        map.putMap("quote", RNZumoKitModule.mapQuote(exchange.getQuote()));
        map.putMap("exchangeRates", RNZumoKitModule.mapExchangeRates(exchange.getExchangeRates()));
        map.putMap("exchangeSetting",
                RNZumoKitModule.mapExchangeSetting(exchange.getExchangeSetting()));

        if (exchange.getNonce() == null) {
            map.putNull("nonce");
        } else {
            map.putString("nonce", exchange.getNonce());
        }

        map.putInt("submittedAt", exchange.getSubmittedAt());

        if (exchange.getConfirmedAt() == null) {
            map.putNull("confirmedAt");
        } else {
            map.putInt("confirmedAt", exchange.getConfirmedAt());
        }

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

    public static WritableMap mapExchangeSetting(ExchangeSetting setting) {
        WritableMap mappedSettings = Arguments.createMap();

        mappedSettings.putString("id", setting.getId());
        mappedSettings.putString("fromCurrency", setting.getFromCurrency());
        mappedSettings.putString("toCurrency", setting.getToCurrency());
        mappedSettings.putString("minExchangeAmount",
                setting.getMinExchangeAmount().toPlainString());
        mappedSettings.putString("exchangeFeeRate",
                setting.getExchangeFeeRate().toPlainString());
        mappedSettings.putString("outgoingTransactionFeeRate",
                setting.getOutgoingTransactionFeeRate().toPlainString());
        mappedSettings.putString("returnTransactionFee",
                setting.getReturnTransactionFee().toPlainString());

        WritableMap exchangeAddress = Arguments.createMap();
        for (HashMap.Entry entry : setting.getExchangeAddress().entrySet()) {
          exchangeAddress.putString(entry.getKey().toString(), (String) entry.getValue());
        }

        mappedSettings.putMap("exchangeAddress", exchangeAddress);

        return mappedSettings;
    }

    public static WritableMap mapExchangeSettings(
            HashMap<String, HashMap<String, ExchangeSetting>> exchangeSettings
    ) {
        WritableMap outerMap = Arguments.createMap();

        for (HashMap.Entry<String, HashMap<String, ExchangeSetting>> outerEntry :
                exchangeSettings.entrySet()) {
            String fromCurrency = outerEntry.getKey();
            WritableMap innerMap = Arguments.createMap();

            for (HashMap.Entry<String, ExchangeSetting> innerEntry :
                    outerEntry.getValue().entrySet()) {
                String toCurrency = innerEntry.getKey();
                WritableMap settings = RNZumoKitModule.mapExchangeSetting(innerEntry.getValue());
                innerMap.putMap(toCurrency, settings);
            }

            outerMap.putMap(fromCurrency, innerMap);
        }

        return outerMap;
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
        mappedQuote.putInt("expireTime", quote.getExpireTime());
        mappedQuote.putString("fromCurrency", quote.getFromCurrency());
        mappedQuote.putString("toCurrency", quote.getToCurrency());
        mappedQuote.putString("depositAmount", quote.getDepositAmount().toPlainString());
        mappedQuote.putString("value", quote.getValue().toPlainString());

        if (quote.getExpiresIn() == null) {
            mappedQuote.putNull("expiresIn");
        } else {
            mappedQuote.putInt("expiresIn", quote.getExpiresIn());
        }

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
            String path = cryptoPropertiesData.getString("path");

            Integer nonce = null;
            if (!cryptoPropertiesData.isNull("nonce")) {
                nonce = cryptoPropertiesData.getInt("nonce");
            }

            cryptoProperties = new AccountCryptoProperties(address, path, nonce);
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
        BigDecimal balance = new BigDecimal(map.getString("balance"));
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
                balance,
                hasNominatedAccount,
                cryptoProperties,
                fiatProperties,
                cards
        );
    }

    public static Quote unboxQuote(ReadableMap map) {
        String id = map.getString("id");
        int expireTime = map.getInt("expireTime");
        String fromCurrency = map.getString("fromCurrency");
        String toCurrency = map.getString("toCurrency");
        BigDecimal depositAmount = new BigDecimal(map.getString("depositAmount"));
        BigDecimal value = new BigDecimal(map.getString("value"));

        Integer expiresIn = null;
        if (!map.isNull("expiresIn")) {
            expiresIn = map.getInt("expiresIn");
        }

        return new Quote(id, expireTime, expiresIn, fromCurrency, toCurrency, depositAmount, value);
    }

    public static ExchangeSetting unboxExchangeSetting(ReadableMap map) {
        String id = map.getString("id");
        String fromCurrency = map.getString("fromCurrency");
        String toCurrency = map.getString("toCurrency");
        BigDecimal minExchangeAmount = new BigDecimal(map.getString("minExchangeAmount"));
        BigDecimal exchangeFeeRate = new BigDecimal(map.getString("exchangeFeeRate"));
        BigDecimal outgoingTransactionFeeRate =
                new BigDecimal(map.getString("outgoingTransactionFeeRate"));
        BigDecimal returnTransactionFee = new BigDecimal(map.getString("returnTransactionFee"));

        HashMap<String, String> exchangeAddress = new HashMap<>();

        ReadableMap exchangeAddressMap = map.getMap("exchangeAddress");
        ReadableMapKeySetIterator iterator = exchangeAddressMap.keySetIterator();
        while (iterator.hasNextKey()) {
            String network = iterator.nextKey();
            String address = exchangeAddressMap.getString(network);

            exchangeAddress.put(network, address);
        }

        return new ExchangeSetting(
                id,
                exchangeAddress,
                fromCurrency,
                toCurrency,
                minExchangeAmount,
                exchangeFeeRate,
                outgoingTransactionFeeRate,
                returnTransactionFee
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