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
import com.facebook.react.bridge.ReadableMapKeySetIterator;

import com.facebook.react.modules.core.DeviceEventManagerModule;

import money.zumo.zumokit.ZumoKit;
import money.zumo.zumokit.User;
import money.zumo.zumokit.Wallet;
import money.zumo.zumokit.WalletCallback;
import money.zumo.zumokit.MnemonicCallback;
import money.zumo.zumokit.AuthCallback;
import money.zumo.zumokit.Store;
import money.zumo.zumokit.State;
import money.zumo.zumokit.Account;
import money.zumo.zumokit.Transaction;
import money.zumo.zumokit.SendTransactionCallback;

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

  private State state;

  public RNZumoKitModule(ReactApplicationContext reactContext) {
    super(reactContext);

    this.reactContext = reactContext;
  }

  @ReactMethod
  public void init(String apiKey, String apiRoot, String myRoot, String txServiceUrl) {

    String dbPath = this.reactContext
      .getFilesDir()
      .getAbsolutePath();

    this.zumoKit = new ZumoKit(dbPath, txServiceUrl, apiKey, apiRoot, myRoot);

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

    ArrayList<Account> accounts = this.zumoKit.store().getState().getAccounts();

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

    // TODO: user.getTransactions

    WritableArray response = Arguments.createArray();
    promise.resolve(response);

  }

  @ReactMethod
  public void sendEthTransaction(String gasPrice, String gasLimit, String to, String value, String data, int chainId, int nonce, Promise promise) {

    if(this.wallet == null) {
      promise.reject("Wallet not found.");
      return;
    }

    this.wallet.sendEthTransaction(nonce, gasPrice, gasLimit, to, value, data, chainId, new SendTransactionCallback() {

      @Override
      public void onError(String errorName, String errorMessage) {
        promise.reject(errorMessage);
      }

      @Override
      public void onSuccess(Transaction transaction) {
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
  public void getExchangeRates(Promise promise) {

    State store = this.zumoKit.store().getState();
    String rates = state.getExchangeRates();

    promise.resolve(rates);

  }

  @ReactMethod
  public void isValidEthAddress(String address, Promise promise) {

    Boolean valid = this.zumoKit.utils()
      .isValidEthAddress(address);

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

  @Override
  public String getName() {
    return "RNZumoKit";
  }

}