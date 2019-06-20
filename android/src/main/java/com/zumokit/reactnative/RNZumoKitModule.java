package com.zumokit.reactnative;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;

import com.facebook.react.modules.core.DeviceEventManagerModule;

import money.zumo.zumokit.ZumoKit;
import money.zumo.zumokit.Store;
import money.zumo.zumokit.State;
import money.zumo.zumokit.Currency;
import money.zumo.zumokit.Keystore;
import money.zumo.zumokit.AndroidHttp;
import money.zumo.zumokit.HttpImpl;
import money.zumo.zumokit.WalletManagement;
import money.zumo.zumokit.CreateWalletCallback;
import money.zumo.zumokit.SendTransactionCallback;
import money.zumo.zumokit.Transaction;
import money.zumo.zumokit.StoreObserver;
import money.zumo.zumokit.AuthCallback;
import money.zumo.zumokit.Utils;

import java.util.ArrayList;
import java.text.SimpleDateFormat;
import java.util.Locale;
import java.util.Date;

public class RNZumoKitModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  private ZumoKit zumoKit;

  public RNZumoKitModule(ReactApplicationContext reactContext) {
    super(reactContext);

    this.reactContext = reactContext;
  }

  @ReactMethod
  public void init(String apiKey, String appId, String apiRoot, String txServiceUrl) {

    String dbPath = this.reactContext
      .getFilesDir()
      .getAbsolutePath();

    this.zumoKit = new ZumoKit(dbPath, txServiceUrl, apiKey, appId, apiRoot);
    
    this.subscribeToEvents();

  }

  private void subscribeToEvents() {
    RNZumoKitModule module = this;

    this.zumoKit.store().subscribe(new StoreObserver() {
      @Override
      public void update(State state) {
        
        module.reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit("onZumoKitUpdated", "hello");

      }
    });
  }

  // - Wallet Management

  @ReactMethod
  public void createWallet(String password, Integer mnemonicCount, Promise promise) {
    
    // Generate a mnemonic phrase.
    WalletManagement wm = this.zumoKit.walletManagement();
    String mnemonic = wm.generateMnemonic(mnemonicCount);
    
    wm.createWallet(Currency.ETH, password, mnemonic, new CreateWalletCallback() {
      
      @Override
      public void onError(String errorName, String errorMessage) {
        
        // If there was a problem creating the wallet then we reject the promise.
        promise.reject(errorName, errorMessage);

      }

      @Override
      public void onSuccess(Keystore keystore) {
        
        boolean unlockedStatus = wm.unlockWallet(keystore, password);

        // Create a map to resolve the promise
        WritableMap map = Arguments.createMap();
        map.putString("mnemonic", mnemonic);

        // Add some idems from the keystore to a writeable map.
        // The map is automatically translated into a JS object.
        WritableMap ksMap = Arguments.createMap();
        ksMap.putString("id", keystore.getId());
        ksMap.putString("address", keystore.getAddress());
        ksMap.putBoolean("unlocked", keystore.getUnlocked());
        map.putMap("keystore", ksMap);

        // Resolve the promise if everything was okay.
        promise.resolve(map);

      }

    });

  }

  @ReactMethod
  public void getWallet(Promise promise) {
    
    // Fetch the keystores from the state
    State state = this.zumoKit.store().getState();
    ArrayList<Keystore> keystores = state.getKeystores();

    try {
      
      Keystore keystore = keystores.get(0);

      // Create a map to resolve the promise
      WritableMap map = Arguments.createMap();
      map.putString("id", keystore.getId());
      map.putString("address", keystore.getAddress());
      map.putBoolean("unlocked", keystore.getUnlocked());

      // Resolve the promise with the map
      promise.resolve(map);

    } catch(Exception e) {

      promise.reject("No wallet found.");

    }

  }

  @ReactMethod
  public void unlockWallet(String walletId, String password, Promise promise) {
    
    // Fetch the keystore from the store
    Store store = this.zumoKit.store();
    Keystore keystore = store.getKeystore(walletId);

    if(keystore == null) {
      promise.reject("A wallet with that ID was not found.");
      return;
    }

    boolean unlockedStatus = this
      .zumoKit
      .walletManagement()
      .unlockWallet(keystore, password);

    promise.resolve(unlockedStatus);

  }

  // - Transactions

  @ReactMethod
  public void sendTransaction(String walletId, String address, String amount, String gasPrice, String gasLimit, Promise promise) {

    // Fetch the keystore from the store
    Store store = this.zumoKit.store();
    Keystore keystore = store.getKeystore(walletId);

    // Get the wallet management instance
    WalletManagement wm = this.zumoKit.walletManagement();

    // Get a timestamp for when the transaction was sent
    RNZumoKitModule module = this;

    wm.sendTransaction(keystore, address, amount, gasPrice, gasLimit, "", new SendTransactionCallback() {
      
      @Override
      public void onError(String errorName, String errorMessage) {
        promise.reject(errorName, errorMessage);
      }

      @Override
      public void onSuccess(Transaction txn) {
        WritableMap map = module.getMap(txn, keystore.getAddress());
        promise.resolve(map);
      }

    });

  }

  @ReactMethod
  public void getTransactions(String walletId, Promise promise) {

    // Load the wallet from the store
    Store store = this.zumoKit.store();
    Keystore keystore = store.getKeystore(walletId);
    String address = keystore.getAddress().toLowerCase();
    
    // Load the the transactions from the state
    State state = store.getState();
    ArrayList<Transaction> transactions = state.getTransactions();

    // Create an array for the response
    WritableArray response = Arguments.createArray();

    // Loop through the transactions looking for address matches
    for (Transaction txn : transactions) {
      WritableMap map = this.getMap(txn, address);
      response.pushMap(map);
    }

    // Resolve the promise with our response array
    promise.resolve(response);

  }

  // HELPERS

  private String getTimestamp(Long epoch) {
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", Locale.UK);
    return sdf.format(new Date(epoch * 1000));
  }

  private WritableMap getMap(Transaction txn, String address) {
    WritableMap map = Arguments.createMap();

    Boolean incoming = txn.getToAddress().toLowerCase().equals(address);
    String type = (incoming) ? "INCOMING" : "OUTGOING";

    map.putString("value", txn.getAmount());
    map.putString("hash", txn.getTxHash());
    map.putString("status", txn.getStatus().name());
    map.putString("to", txn.getToAddress());
    map.putString("from", txn.getFromAddress());
    map.putString("timestamp", this.getTimestamp(txn.getTimestamp()));
    map.putString("gas_price", txn.getGasPrice());
    map.putString("type", type);

    return map;
  }

  // API

  @ReactMethod
  public void auth(String email, Promise promise) {

    if(this.zumoKit == null) {
      promise.reject("ZumoKit not initialized.");
      return;
    }

    this.zumoKit.auth(email, new AuthCallback() {
      @Override
      public void onError(short httpCode, String data) {
        promise.reject(data);
      }

      @Override
      public void onSuccess() {
        promise.resolve(true);
      }
    });

  }

  // UTILITY

  @ReactMethod
  public void getBalance(String address, Promise promise) {

    String balance = this.zumoKit.utils()
      .ethGetBalance(address);

    promise.resolve(balance);

  }

  @ReactMethod
  public void getExchangeRates(Promise promise) {

    Store store = this.zumoKit.store();
    State state = store.getState();

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

  @Override
  public String getName() {
    return "RNZumoKit";
  }

}