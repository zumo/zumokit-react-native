package com.zumokit.reactnative;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMapKeySetIterator;

import com.facebook.react.modules.core.DeviceEventManagerModule;

import money.zumo.zumokit.ComposeExchangeCallback;
import money.zumo.zumokit.ComposedExchange;
import money.zumo.zumokit.Exchange;
import money.zumo.zumokit.ExchangeSettings;
import money.zumo.zumokit.HistoricalExchangeRatesCallback;
import money.zumo.zumokit.SubmitExchangeCallback;
import money.zumo.zumokit.ZumoKit;
import money.zumo.zumokit.ZumoKitErrorType;
import money.zumo.zumokit.ZumoKitErrorCode;
import money.zumo.zumokit.User;
import money.zumo.zumokit.Wallet;
import money.zumo.zumokit.WalletCallback;
import money.zumo.zumokit.MnemonicCallback;
import money.zumo.zumokit.UserCallback;
import money.zumo.zumokit.State;
import money.zumo.zumokit.Account;
import money.zumo.zumokit.Transaction;
import money.zumo.zumokit.ComposedTransaction;
import money.zumo.zumokit.ComposeTransactionCallback;
import money.zumo.zumokit.SubmitTransactionCallback;
import money.zumo.zumokit.StateListener;
import money.zumo.zumokit.UserListener;
import money.zumo.zumokit.TransactionListener;
import money.zumo.zumokit.AccountType;
import money.zumo.zumokit.NetworkType;
import money.zumo.zumokit.FeeRates;
import money.zumo.zumokit.ExchangeRate;
import money.zumo.zumokit.exceptions.ZumoKitException;

import android.util.Log;

import java.util.Map;
import java.util.ArrayList;
import java.text.SimpleDateFormat;
import java.util.Locale;
import java.util.Date;
import java.util.HashMap;

public class RNZumoKitModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  private ZumoKit zumoKit;

  private User user;

  private Wallet wallet;

  private TransactionListener txListener;

  public RNZumoKitModule(ReactApplicationContext reactContext) {
    super(reactContext);

    this.reactContext = reactContext;
  }

  private void rejectPromise(Promise promise, String errorType, String errorCode, String errorMessage) {
    WritableMap userInfo = Arguments.createMap();
    userInfo.putString("type", errorType);

    promise.reject(errorCode, errorMessage, userInfo);
  }

  private void rejectPromise(Promise promise, Exception e) {
    ZumoKitException error = (ZumoKitException)e;

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
  public void init(String apiKey, String apiRoot, String txServiceUrl) {

    this.zumoKit = new ZumoKit(apiKey, apiRoot, txServiceUrl);

    this.addStateListener();

  }

  // - Authentication

  @ReactMethod
  public void getUser(String tokenSet, Promise promise) {

    if(this.zumoKit == null) {
      rejectPromise(promise, "ZumoKit not initialized.");
      return;
    }

    RNZumoKitModule module = this;

    this.zumoKit.getUser(tokenSet, new UserCallback() {

      @Override
      public void onError(Exception error) {
        rejectPromise(promise, error);
      }

      @Override
      public void onSuccess(User user) {

        module.user = user;
        module.addUserListener();

        WritableMap map = Arguments.createMap();

        map.putString("id", user.getId());
        map.putBoolean("hasWallet", user.hasWallet());

        promise.resolve(map);
      }

    });

  }

  // - Wallet Management

  @ReactMethod
  public void createWallet(String mnemonic, String password, Promise promise) {

    if(this.user == null) {
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

    if(this.user == null) {
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
  public void revealMnemonic(String password, Promise promise) {

    if(this.user == null) {
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

    if(this.user == null) {
      rejectPromise(promise, "User not found.");
      return;
    }

    NetworkType network_type = NetworkType.valueOf(network);
    AccountType account_type = AccountType.valueOf(type);

    Account account = this.user.getAccount(symbol, network_type, account_type);

    if (account == null) {
      rejectPromise(promise, "Account not found.");
      return;
    }

    WritableMap response = RNZumoKitModule.mapAccount(account);
    promise.resolve(response);

  }

  @ReactMethod
  public void getAccounts(Promise promise) {

    if(this.user == null) {
      rejectPromise(promise, "User not found.");
      return;
    }

    ArrayList<Account> accounts = this.zumoKit.getState().getAccounts();
    WritableArray response = RNZumoKitModule.mapAccounts(accounts);

    // Resolve the promise with our response array
    promise.resolve(response);

  }

  // - Transactions

  @ReactMethod
  public void getTransactions(Promise promise) {

    if(this.user == null) {
      rejectPromise(promise, "User not found.");
      return;
    }

    ArrayList<Transaction> transactions = this.zumoKit.getState().getTransactions();
    WritableArray response = RNZumoKitModule.mapTransactions(transactions);

    promise.resolve(response);

  }


  @ReactMethod
  public void submitTransaction(ReadableMap composedTransactionMap, Promise promise) {
    if(this.wallet == null) {
      rejectPromise(promise, "Wallet not found.");
      return;
    }

    String signedTransaction = composedTransactionMap.getString("signedTransaction");
    Account account = RNZumoKitModule.unboxAccount(composedTransactionMap.getMap("account"));
    String destination = composedTransactionMap.getString("destination");
    String value = composedTransactionMap.getString("value");
    String data = composedTransactionMap.getString("data");
    String fee = composedTransactionMap.getString("fee");

    ComposedTransaction composedTransaction =
      new ComposedTransaction(signedTransaction, account, destination, value, data, fee);

    this.wallet.submitTransaction(composedTransaction, new SubmitTransactionCallback() {

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
  public void composeEthTransaction(String accountId, String gasPrice, String gasLimit, String to, String value, String data, String nonce, Boolean sendMax, Promise promise) {

    if(this.wallet == null) {
      rejectPromise(promise, "Wallet not found.");
      return;
    }

    Long nonceValue = null;
    if(nonce != null) {
      nonceValue = Long.parseLong(nonce);
    }

    this.wallet.composeEthTransaction(accountId, gasPrice, gasLimit, to, value, data, nonceValue, sendMax, new ComposeTransactionCallback() {

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
  public void composeBtcTransaction(String accountId, String changeAccountId, String to, String value, String feeRate, Boolean sendMax, Promise promise) {

    if(this.wallet == null) {
      rejectPromise(promise, "Wallet not found.");
      return;
    }

    this.wallet.composeBtcTransaction(accountId, changeAccountId, to, value, feeRate, sendMax, new ComposeTransactionCallback() {

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
  public void composeExchange(String fromAccountId, String toAccountId, ReadableMap exchangeRate, ReadableMap exchangeSettings, String amount, Boolean sendMax, Promise promise) {
    if(this.wallet == null) {
      rejectPromise(promise, "Wallet not found.");
      return;
    }

    ExchangeRate rate = RNZumoKitModule.unboxExchangeRate(exchangeRate);
    ExchangeSettings settings = RNZumoKitModule.unboxExchangeSettings(exchangeSettings);

    this.wallet.composeExchange(fromAccountId, toAccountId, rate, settings, amount, sendMax, new ComposeExchangeCallback() {
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
    if(this.wallet == null) {
      rejectPromise(promise, "Wallet not found.");
      return;
    }

    String signedTransaction = composedExchangeMap.getString("signedTransaction");
    Account depositAccount = RNZumoKitModule.unboxAccount(composedExchangeMap.getMap("depositAccount"));
    Account withdrawAccount = RNZumoKitModule.unboxAccount(composedExchangeMap.getMap("withdrawAccount"));
    ExchangeRate exchangeRate = RNZumoKitModule.unboxExchangeRate(composedExchangeMap.getMap("exchangeRate"));
    ExchangeSettings exchangeSettings = RNZumoKitModule.unboxExchangeSettings(composedExchangeMap.getMap("exchangeSettings"));
    String exchangeAddress = composedExchangeMap.getString("exchangeAddress");
    String value = composedExchangeMap.getString("value");
    String returnValue = composedExchangeMap.getString("returnValue");
    String depositFee = composedExchangeMap.getString("depositFee");
    String exchangeFee = composedExchangeMap.getString("exchangeFee");
    String withdrawFee = composedExchangeMap.getString("withdrawFee");

    ComposedExchange composedExchange = new ComposedExchange(
            signedTransaction,
            depositAccount,
            withdrawAccount,
            exchangeRate,
            exchangeSettings,
            exchangeAddress,
            value,
            returnValue,
            depositFee,
            exchangeFee,
            withdrawFee
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

  // - Listeners

  private void addStateListener() {
    RNZumoKitModule module = this;

    this.zumoKit.addStateListener(new StateListener() {
        @Override
        public void update(State state) {

          WritableMap map = RNZumoKitModule.mapState(state);

          module.reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit("StateChanged", map);

        }
    });
  }

  private void addUserListener() {

    if(this.user == null) {
      return;
    }

    RNZumoKitModule module = this;

    this.user.addListener(new UserListener() {
      @Override
        public void update(ArrayList<Account> accounts, ArrayList<Transaction> transactions) {

          WritableMap map = Arguments.createMap();

          WritableArray accs = RNZumoKitModule.mapAccounts(accounts);
          map.putArray("accounts", accs);

          WritableArray txns = RNZumoKitModule.mapTransactions(transactions);
          map.putArray("transactions", txns);

          module.reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit("StateChanged", map);

        }
    });

  }

  @ReactMethod
  public void addAccountListener(String accountId, Promise promise) {

    // - check if a user exists
    // - add a listener to the account
    // - bubble up events to JS
    // - remove the listener when it's all done
  }

  @ReactMethod
  public void addTransactionListener(String transactionId, Promise promise) {

    if(this.user == null) {
      rejectPromise(promise, "User not found.");
      return;
    }

    if(this.txListener != null) {
      this.user.removeTransactionListener(this.txListener);
      this.txListener = null;
    }

    RNZumoKitModule module = this;

    this.user.addTransactionListener(transactionId, new TransactionListener() {

      @Override
      public void update(Transaction transaction) {

        WritableMap map = module.mapTransaction(transaction);

        module.reactContext
          .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
          .emit("TransactionChanged", map);

      }

    });

    promise.resolve(true);

  }

  @ReactMethod
  public void removeTransactionListener(String transactionId, Promise promise) {

    if(this.user == null) {
      rejectPromise(promise, "User not found.");
      return;
    }

    if(this.txListener == null) {
      rejectPromise(promise, "Transaction listener not found.");
      return;
    }

    this.user.removeTransactionListener(this.txListener);
    this.txListener = null;

    promise.resolve(true);

  }

  // - Wallet Recovery

  @ReactMethod
  public void isRecoveryMnemonic(String mnemonic, Promise promise) {

    if(this.user == null) {
      rejectPromise(promise, "User not found.");
      return;
    }

    Boolean validation = this.user.isRecoveryMnemonic(mnemonic);
    promise.resolve(validation);

  }

  @ReactMethod
  public void recoverWallet(String mnemonic, String password, Promise promise) {

    if(this.user == null) {
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
  public void getHistoricalExchangeRates(Promise promise) {

    if(this.zumoKit == null) {
      rejectPromise(promise, "ZumoKit not initialized.");
      return;
    }

    RNZumoKitModule module = this;

    this.zumoKit.getHistoricalExchangeRates(new HistoricalExchangeRatesCallback() {
      @Override
      public void onError(Exception e) {
        rejectPromise(promise, e);
      }

      @Override
      public void onSuccess(HashMap<String, HashMap<String, HashMap<String, ArrayList<ExchangeRate>>>> historicalExchangeRates) {
        promise.resolve(RNZumoKitModule.mapHistoricalExchangeRates(historicalExchangeRates));
      }
    });
  }

  @ReactMethod
  public void generateMnemonic(int wordLength, Promise promise) {

    if(this.zumoKit == null) {
      rejectPromise(promise, "ZumoKit not initialized.");
      return;
    }

    try {
      String mnemonic = this.zumoKit.utils().generateMnemonic(wordLength);
      promise.resolve(mnemonic);
    } catch (Exception e) {
      rejectPromise(promise, e);
    }

  }

  @ReactMethod
  public void isValidEthAddress(String address, Promise promise) {

    try {
      Boolean valid = this.zumoKit.utils()
        .isValidEthAddress(address);
      promise.resolve(valid);
    } catch (Exception e) {
      rejectPromise(promise, e);
    }

  }

  @ReactMethod
  public void isValidBtcAddress(String address, String network, Promise promise) {

    try {
      Boolean valid = this.zumoKit.utils()
        .isValidBtcAddress(address, NetworkType.valueOf(network));
      promise.resolve(valid);
    } catch (Exception e) {
      rejectPromise(promise, e);
    }

  }

  @ReactMethod
  public void ethToGwei(String eth, Promise promise) {

    String gwei = this.zumoKit.utils()
      .ethToGwei(eth);

    promise.resolve(gwei);

  }

  @ReactMethod
  public void gweiToEth(String gwei, Promise promise) {

    String eth = this.zumoKit.utils()
      .gweiToEth(gwei);

    promise.resolve(eth);

  }

  @ReactMethod
  public void ethToWei(String eth, Promise promise) {

    String wei = this.zumoKit.utils()
      .ethToWei(eth);

    promise.resolve(wei);

  }

  @ReactMethod
  public void weiToEth(String wei, Promise promise) {

    String eth = this.zumoKit.utils()
      .weiToEth(wei);

    promise.resolve(eth);

  }

  @ReactMethod
  public void clear(Promise promise) {

    this.user = null;
    this.wallet = null;

    promise.resolve(true);

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

  public static WritableMap mapAccount(Account account) {

      WritableMap map = Arguments.createMap();

      map.putString("id", account.getId());
      map.putString("path", account.getPath());
      map.putString("symbol", account.getSymbol());
      map.putString("coin", account.getCoin());
      map.putString("address", account.getAddress());
      map.putString("balance", account.getBalance());
      map.putString("network", account.getNetwork().toString());
      map.putString("type", account.getType().toString());
      map.putInt("version", account.getVersion());

      if (account.getNonce() == null) {
        map.putNull("nonce");
      } else {
        map.putInt("nonce", account.getNonce().intValue());
      }

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

    map.putString("signedTransaction", transaction.getSignedTransaction());
    map.putMap("account", mapAccount(transaction.getAccount()));
    map.putString("fee", transaction.getFee());

    if (transaction.getDestination() == null){
      map.putNull("destination");
    } else {
      map.putString("destination", transaction.getDestination());
    }

    if (transaction.getValue() == null){
      map.putNull("value");
    } else {
      map.putString("value", transaction.getValue());
    }

    if (transaction.getData() == null){
      map.putNull("data");
    } else {
      map.putString("data", transaction.getData());
    }

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
    map.putString("type", transaction.getType().toString());
    map.putString("direction", transaction.getDirection().toString());
    map.putString("txHash", transaction.getTxHash());
    map.putString("accountId", transaction.getAccountId());
    map.putString("symbol", transaction.getSymbol());
    map.putString("coin", transaction.getCoin());
    map.putString("network", transaction.getNetwork().toString());

    if(transaction.getNonce() != null) {
      map.putInt("nonce", transaction.getNonce().intValue());
    }

    map.putString("status", transaction.getStatus().toString());
    map.putString("fromAddress", transaction.getFromAddress());
    map.putString("fromUserId", transaction.getFromUserId());
    map.putString("toAddress", transaction.getToAddress());
    map.putString("toUserId", transaction.getToUserId());
    map.putString("value", transaction.getValue());
    map.putString("data", transaction.getData());
    map.putString("gasPrice", transaction.getGasPrice());
    map.putString("gasLimit", transaction.getGasLimit());

    if(transaction.getFee() != null) {
      map.putString("fee", transaction.getFee());
    }

    if(transaction.getSubmittedAt() != null) {
      map.putInt("submittedAt", transaction.getSubmittedAt().intValue());
    }

    if(transaction.getConfirmedAt() != null) {
      map.putInt("confirmedAt", transaction.getConfirmedAt().intValue());
    }

    map.putInt("timestamp", (int) transaction.getTimestamp());

    WritableMap fiatValues = Arguments.createMap();

    for (HashMap.Entry entry : transaction.getFiatValue().entrySet()) {
      fiatValues.putString(
        (String) entry.getKey(),
        (String) entry.getValue()
      );
    }

    map.putMap("fiatValue", fiatValues);

    WritableMap fiatFee = Arguments.createMap();

    for (HashMap.Entry entry : transaction.getFiatFee().entrySet()) {
      fiatFee.putString(
        (String) entry.getKey(),
        (String) entry.getValue()
      );
    }

    map.putMap("fiatFee", fiatFee);

    return map;

  }

  public static WritableMap mapFeeRates(HashMap<String, FeeRates> feeRates) {

    WritableMap map = Arguments.createMap();

    for (HashMap.Entry<String, FeeRates> entry : feeRates.entrySet()) {
      String key = entry.getKey();
      FeeRates rates = entry.getValue();

      WritableMap mappedRates = Arguments.createMap();

      mappedRates.putString("slow", rates.getSlow());
      mappedRates.putString("average", rates.getAverage());
      mappedRates.putString("fast", rates.getFast());

      map.putMap(key, mappedRates);
    }

    return map;

  }

  public static WritableMap mapComposedExchange(ComposedExchange exchange) {
    WritableMap map = Arguments.createMap();

    map.putString("signedTransaction", exchange.getSignedTransaction());
    map.putMap("depositAccount", RNZumoKitModule.mapAccount(exchange.getDepositAccount()));
    map.putMap("withdrawAccount", RNZumoKitModule.mapAccount(exchange.getWithdrawAccount()));
    map.putMap("exchangeRate", RNZumoKitModule.mapExchangeRate(exchange.getExchangeRate()));
    map.putMap("exchangeSettings", RNZumoKitModule.mapExchangeSettings(exchange.getExchangeSettings()));
    map.putString("exchangeAddress", exchange.getExchangeAddress());
    map.putString("value", exchange.getValue());
    map.putString("returnValue", exchange.getReturnValue());
    map.putString("depositFee", exchange.getDepositFee());
    map.putString("exchangeFee", exchange.getExchangeFee());
    map.putString("withdrawFee", exchange.getWithdrawFee());

    return map;
  }

  public static WritableMap mapExchange(Exchange exchange) {
    WritableMap map = Arguments.createMap();

    map.putString("id", exchange.getId());
    map.putString("status", exchange.getStatus());
    map.putString("depositCurrency", exchange.getDepositCurrency());
    map.putString("depositAccountId", exchange.getDepositAccountId());
    map.putString("depositTransactionId", exchange.getDepositTransactionId());
    map.putString("withdrawCurrency", exchange.getWithdrawCurrency());
    map.putString("withdrawAccountId", exchange.getWithdrawAccountId());

    if(exchange.getWithdrawTransactionId() == null) {
      map.putNull("withdrawTransactionId");
    } else {
      map.putString("withdrawTransactionId", exchange.getWithdrawTransactionId());
    }

    map.putString("amount", exchange.getAmount());

    if (exchange.getDepositFee() == null) {
      map.putNull("depositFee");
    } else {
      map.putString("depositFee", exchange.getDepositFee());
    }

    map.putString("returnAmount", exchange.getReturnAmount());
    map.putString("exchangeFee", exchange.getExchangeFee());
    map.putString("withdrawFee", exchange.getWithdrawFee());
    map.putMap("exchangeRate",  RNZumoKitModule.mapExchangeRate(exchange.getExchangeRate()));
    map.putMap("exchangeRates",  RNZumoKitModule.mapExchangeRates(exchange.getExchangeRates()));
    map.putMap("exchangeSettings", RNZumoKitModule.mapExchangeSettings(exchange.getExchangeSettings()));
    map.putInt("submittedAt", exchange.getSubmittedAt().intValue());

    if(exchange.getConfirmedAt() == null) {
      map.putNull("confirmedAt");
    } else {
      map.putInt("confirmedAt", exchange.getConfirmedAt().intValue());
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

  public static WritableMap mapExchangeSettings(ExchangeSettings settings) {

    WritableMap mappedSettings = Arguments.createMap();

    mappedSettings.putString("id", settings.getId());
    mappedSettings.putString("depositCurrency", settings.getDepositCurrency());
    mappedSettings.putString("withdrawCurrency", settings.getWithdrawCurrency());
    mappedSettings.putString("minExchangeAmount", settings.getMinExchangeAmount());
    mappedSettings.putString("feeRate", settings.getFeeRate());
    mappedSettings.putString("depositFeeRate", settings.getDepositFeeRate());
    mappedSettings.putString("withdrawFee", settings.getWithdrawFee());
    mappedSettings.putInt("timestamp", (int) settings.getTimestamp());

    WritableMap depositAddress = Arguments.createMap();
    for (HashMap.Entry entry : settings.getDepositAddress().entrySet()) {
      depositAddress.putString(
        entry.getKey().toString(),
        (String) entry.getValue()
      );
    }

    mappedSettings.putMap("depositAddress", depositAddress);

    return mappedSettings;

  }

  public static WritableMap mapExchangeSettingsDict(HashMap<String, HashMap<String, ExchangeSettings>> exchangeSettings) {

    WritableMap outerMap = Arguments.createMap();

    for (HashMap.Entry<String, HashMap<String, ExchangeSettings>> outerEntry : exchangeSettings.entrySet()) {
      String fromCurrency = outerEntry.getKey();
      WritableMap innerMap = Arguments.createMap();

      for (HashMap.Entry<String, ExchangeSettings> innerEntry : outerEntry.getValue().entrySet()) {
        String toCurrency = innerEntry.getKey();
        WritableMap settings = RNZumoKitModule.mapExchangeSettings(innerEntry.getValue());
        innerMap.putMap(toCurrency, settings);
      }

      outerMap.putMap(fromCurrency, innerMap);
    }

    return outerMap;
  }

  public static WritableMap mapExchangeRate(ExchangeRate rate) {

    WritableMap mappedRate = Arguments.createMap();

    mappedRate.putString("id", rate.getId());
    mappedRate.putString("depositCurrency", rate.getDepositCurrency());
    mappedRate.putString("withdrawCurrency", rate.getWithdrawCurrency());
    mappedRate.putString("value", rate.getValue());
    mappedRate.putInt("validTo", (int) rate.getValidTo());
    mappedRate.putInt("timestamp", (int) rate.getTimestamp());

    return mappedRate;

  }

  public static WritableMap mapExchangeRates(HashMap<String, HashMap<String, ExchangeRate>> exchangeRates) {

    WritableMap outerMap = Arguments.createMap();

    for (HashMap.Entry<String, HashMap<String, ExchangeRate>> outerEntry : exchangeRates.entrySet()) {
      String fromCurrency = outerEntry.getKey();
      WritableMap innerMap = Arguments.createMap();

      for (HashMap.Entry<String, ExchangeRate> innerEntry : outerEntry.getValue().entrySet()) {
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

  public static WritableMap mapState(State state) {

    WritableMap map = Arguments.createMap();

    WritableArray accounts = RNZumoKitModule.mapAccounts(state.getAccounts());
    map.putArray("accounts", accounts);

    WritableArray transactions = RNZumoKitModule.mapTransactions(state.getTransactions());
    map.putArray("transactions", transactions);

    WritableArray exchanges = RNZumoKitModule.mapExchanges(state.getExchanges());
    map.putArray("exchanges", exchanges);

    WritableMap exchangeRates = RNZumoKitModule.mapExchangeRates(state.getExchangeRates());
    map.putMap("exchangeRates", exchangeRates);

    WritableMap exchangeSettings = RNZumoKitModule.mapExchangeSettingsDict(state.getExchangeSettings());
    map.putMap("exchangeSettings", exchangeSettings);

    WritableMap feeRates = RNZumoKitModule.mapFeeRates(state.getFeeRates());
    map.putMap("feeRates", feeRates);

    return map;

  }

  public static Account unboxAccount(ReadableMap map) {
    String accountId = map.getString("id");
    String path = map.getString("path");
    String symbol = map.getString("symbol");
    String coin = map.getString("coin");
    String address = map.getString("address");
    String balance = map.getString("balance");

    Long nonce = null;
    if(!map.isNull("nonce")) {
      nonce = Long.valueOf(map.getInt("nonce"));
    }

    NetworkType network = NetworkType.valueOf(map.getString("network"));
    AccountType type = AccountType.valueOf(map.getString("type"));
    byte version = Integer.valueOf(map.getInt("version")).byteValue();

    return new Account(accountId, path, symbol, coin, address, balance, nonce, network, type, version);
  }

  public static ExchangeRate unboxExchangeRate(ReadableMap map) {
    String id = map.getString("id");
    String depositCurrency = map.getString("depositCurrency");
    String withdrawCurrency = map.getString("withdrawCurrency");
    String value = map.getString("value");
    long validTo = map.getInt("validTo");
    long timestamp = map.getInt("timestamp");

    return new ExchangeRate(id, depositCurrency, withdrawCurrency, value, validTo, timestamp);
  }

  public static ExchangeSettings unboxExchangeSettings(ReadableMap map) {
    String id = map.getString("id");
    String depositCurrency = map.getString("depositCurrency");
    String withdrawCurrency = map.getString("withdrawCurrency");
    String minExchangeAmount = map.getString("minExchangeAmount");
    String feeRate = map.getString("feeRate");
    String depositFeeRate = map.getString("depositFeeRate");
    String withdrawFee = map.getString("withdrawFee");
    long timestamp = map.getInt("timestamp");

    HashMap<NetworkType, String> depositAddress = new HashMap<NetworkType, String>();

    ReadableMap depositAddressMap = map.getMap("depositAddress");
    ReadableMapKeySetIterator iterator = depositAddressMap.keySetIterator();
    while (iterator.hasNextKey()) {
      String key = iterator.nextKey();
      String value = depositAddressMap.getString(key);

      depositAddress.put(NetworkType.valueOf(key), value);
    }

    return new ExchangeSettings(id, depositAddress, depositCurrency, withdrawCurrency, minExchangeAmount, feeRate, depositFeeRate, withdrawFee, timestamp);
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