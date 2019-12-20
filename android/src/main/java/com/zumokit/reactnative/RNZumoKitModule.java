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

import money.zumo.zumokit.ZumoKit;
import money.zumo.zumokit.User;
import money.zumo.zumokit.Wallet;
import money.zumo.zumokit.WalletCallback;
import money.zumo.zumokit.MnemonicCallback;
import money.zumo.zumokit.AuthCallback;
import money.zumo.zumokit.State;
import money.zumo.zumokit.Account;
import money.zumo.zumokit.Transaction;
import money.zumo.zumokit.SendTransactionCallback;
import money.zumo.zumokit.StateListener;
import money.zumo.zumokit.UserListener;
import money.zumo.zumokit.AccountListener;
import money.zumo.zumokit.TransactionListener;
import money.zumo.zumokit.NetworkType;

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

  @ReactMethod
  public void init(String apiKey, String apiRoot, String myRoot, String txServiceUrl) {

    this.zumoKit = new ZumoKit(txServiceUrl, apiKey, apiRoot, myRoot);

    this.addStateListener();

  }

  // - Authentication

  @ReactMethod
  public void auth(String token, ReadableMap headers, Promise promise) {

    if(this.zumoKit == null) {
      promise.reject("ZumoKit not initialized.");
      return;
    }

    RNZumoKitModule module = this;

    HashMap<String, String> headerMap = this.toHashMap(headers);

    this.zumoKit.auth(token, headerMap, new AuthCallback() {
      
      @Override
      public void onError(short errorCode, String errorMessage) {
        promise.reject(errorMessage);
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
    
    if(this.zumoKit == null) {
      promise.reject("ZumoKit not initialized.");
      return;
    }

    RNZumoKitModule module = this;

    this.user.createWallet(mnemonic, password, new WalletCallback() {

      @Override
      public void onError(String errorName, String errorMessage) {
        promise.reject(errorMessage);
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

    if(this.zumoKit == null) {
      promise.reject("ZumoKit not initialized.");
      return;
    }

    RNZumoKitModule module = this;

    this.user.unlockWallet(password, new WalletCallback() {

      @Override
      public void onError(String errorName, String errorMessage) {
        promise.reject(errorMessage);
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

    if(this.zumoKit == null) {
      promise.reject("ZumoKit not initialized.");
      return;
    }

    this.user.revealMnemonic(password, new MnemonicCallback() {
      @Override
      public void onError(String errorName, String errorMessage) {
        promise.reject(errorMessage);
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

    if(this.zumoKit == null) {
      promise.reject("ZumoKit not initialized.");
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
      promise.reject("User not found.");
      return;
    }

    ArrayList<Transaction> transactions = this.zumoKit.getState().getTransactions();
    WritableArray response = RNZumoKitModule.mapTransactions(transactions);

    promise.resolve(response);

  }

  @ReactMethod
  public void sendEthTransaction(String accountId, String gasPrice, String gasLimit, String to, String value, String data, String nonce, Promise promise) {

    if(this.wallet == null) {
      promise.reject("Wallet not found.");
      return;
    }

    Long nonceValue = null;
    if(nonce != null) {
      nonceValue = Long.parseLong(nonce);
    }

    this.wallet.sendEthTransaction(accountId, gasPrice, gasLimit, to, value, data, nonceValue, new SendTransactionCallback() {

      @Override
      public void onError(String errorName, String errorMessage) {
        promise.reject(errorMessage);
      }

      @Override
      public void onSuccess(Transaction transaction) {
        WritableMap map = RNZumoKitModule.mapTransaction(transaction);
        promise.resolve(map);
      }

    });

  }

  @ReactMethod
  public void sendBtcTransaction(String accountId, String changeAccountId, String to, String value, String feeRate, Promise promise) {

    if(this.wallet == null) {
      promise.reject("Wallet not found.");
      return;
    }

    Long feeRateValue = Long.parseLong(feeRate);

    this.wallet.sendBtcTransaction(accountId, changeAccountId, to, value, feeRateValue, new SendTransactionCallback() {

      @Override
      public void onError(String errorName, String errorMessage) {
        promise.reject(errorMessage);
      }

      @Override
      public void onSuccess(Transaction transaction) {
        WritableMap map = RNZumoKitModule.mapTransaction(transaction);
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
      promise.reject("User not found.");
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
      promise.reject("User not found.");
      return;
    }

    if(this.txListener == null) {
      promise.reject("Transaction listener not found.");
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
      promise.reject("User not found.");
      return;
    }

    Boolean validation = this.user.isRecoveryMnemonic(mnemonic);
    promise.resolve(validation);

  }

  @ReactMethod
  public void recoverWallet(String mnemonic, String password, Promise promise) {

    if(this.user == null) {
      promise.reject("User not found.");
      return;
    }

    RNZumoKitModule module = this;

    this.user.recoverWallet(mnemonic, password, new WalletCallback() {

      @Override
      public void onError(String errorName, String errorMessage) {
        promise.reject(errorMessage);
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
  public void generateMnemonic(int wordLength, Promise promise) {

    if(this.zumoKit == null) {
      promise.reject("ZumoKit not initialized.");
      return;
    }

    String mnemonic = this.zumoKit.utils().generateMnemonic(wordLength);

    promise.resolve(mnemonic);

  }

  @ReactMethod
  public void isValidEthAddress(String address, Promise promise) {

    Boolean valid = this.zumoKit.utils()
      .isValidEthAddress(address);

    promise.resolve(valid);

  }

  @ReactMethod
  public void isValidBtcAddress(String address, String network, Promise promise) {
    
    Boolean valid = this.zumoKit.utils()
      .isValidBtcAddress(address, NetworkType.valueOf(network));

    promise.resolve(valid);

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
  public void maxSpendableEth(String accountId, String gasPrice, String gasLimit, Promise promise) {
    
    String max = this.wallet.maxSpendableEth(accountId, gasPrice, getGasLimit);
    promise.resolve(max);

  }

  @ReactMethod
  public void maxSpendableBtc(String accountId, String to, String feeRate, Promise promise) {

    String max = this.wallet.maxSpendableBtc(accountId, to, feeRate);
    promise.resolve(max);

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

  public static WritableArray mapAccounts(ArrayList<Account> accounts) {
    
    WritableArray response = Arguments.createArray();

    for (Account account : accounts) {
      WritableMap map = Arguments.createMap();

      map.putString("id", account.getId());
      map.putString("path", account.getPath());
      map.putString("symbol", account.getSymbol());
      map.putString("coin", account.getCoin());
      map.putString("address", account.getAddress());
      map.putString("balance", account.getBalance());
      map.putInt("chainId", (account.getChainId() != null) ? account.getChainId() : 0);

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

  public static WritableMap mapTransaction(Transaction transaction) {

    WritableMap map = Arguments.createMap();
    
    map.putString("id", transaction.getId());
    map.putString("txHash", transaction.getTxHash());
    map.putString("accountId", transaction.getAccountId());
    map.putString("symbol", transaction.getSymbol());
    map.putString("coin", transaction.getCoin());

    if(transaction.getChainId() != null) {
      map.putInt("chainId", transaction.getChainId());
    }
    
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
    map.putString("cost", transaction.getCost());

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

    return map;

  }

  public static WritableMap mapState(State state) {

      WritableMap map = Arguments.createMap();

      WritableArray accounts = RNZumoKitModule.mapAccounts(state.getAccounts());
      map.putArray("accounts", accounts);

      WritableArray transactions = RNZumoKitModule.mapTransactions(state.getTransactions());
      map.putArray("transactions", transactions);

      map.putString("exchangeRates", state.getExchangeRates());

      return map;

  }

  @Override
  public Map<String, Object> getConstants() {
    final Map<String, Object> constants = new HashMap<>();
    constants.put("VERSION", ZumoKit.getVersion());
    return constants;
  }

  @Override
  public String getName() {
    return "RNZumoKit";
  }

}