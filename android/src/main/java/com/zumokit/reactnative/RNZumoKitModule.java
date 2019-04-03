package com.zumokit.reactnative;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;

import com.blockstar.zumokit.ZumoKit;
import com.blockstar.zumokit.Store;
import com.blockstar.zumokit.State;
import com.blockstar.zumokit.Currency;
import com.blockstar.zumokit.Keystore;
import com.blockstar.zumokit.AndroidHttp;
import com.blockstar.zumokit.HttpImpl;
import com.blockstar.zumokit.WalletManagement;
import com.blockstar.zumokit.SendTransactionCallback;
import com.blockstar.zumokit.Transaction;
import com.blockstar.zumoKit.StoreObserver;

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
  public void init() {

    String dbPath = this.reactContext
      .getFilesDir()
      .getAbsolutePath();

    String txServiceUrl = "wss://tx.kit.staging.zumopay.com/";
    
    this.zumoKit = new ZumoKit(dbPath, txServiceUrl);
    this.subscribeToEvents();

  }

  private void subscribeToEvents() {
    RNZumoKitModule module = this;
    RCTDeviceEventEmitter emitter = this.reactContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class);

    this.zumoKit.store().subscribe(new StoreObserver() {
      @Override
      public void update(State state) {
        
        emitter.emit("onZumoKitUpdated", "hello");

      }
    });
  }

  // - Wallet Management

  @ReactMethod
  public void createWallet(String password, Integer mnemonicCount, Promise promise) {
    
    // Generate a mnemonic phrase.
    WalletManagement wm = this.zumoKit.walletManagement();
    String mnemonic = wm.generateMnemonic(mnemonicCount);
    
    // Create the keystore and instantly unlock it so it can be used.
    Keystore keystore = wm.createWallet(Currency.ETH, password, mnemonic);
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
  public void sendTransaction(String walletId, String address, String amount, Promise promise) {

    // Fetch the keystore from the store
    Store store = this.zumoKit.store();
    Keystore keystore = store.getKeystore(walletId);

    // Get the wallet management instance
    WalletManagement wm = this.zumoKit.walletManagement();

    // Get a timestamp for when the transaction was sent
    RNZumoKitModule module = this;

    wm.sendTransaction(keystore, address, amount, "myPayload", new SendTransactionCallback() {
      
      @Override
      public void onError(String message, Transaction txn) {
        promise.reject(message);
      }

      @Override
      public void onSuccess(Transaction txn) {
        WritableMap map = module.getMap(txn);
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
      // if((txn.getFromAddress().toLowerCase().equals(address) || txn.getToAddress().toLowerCase().equals(address)) && (txn.getHash().length() > 1)) {
        WritableMap map = this.getMap(txn);
        response.pushMap(map);
      // }
    }

    // Resolve the promise with our response array
    promise.resolve(response);

  }

  // HELPERS

  private String getTimestamp(Long epoch) {
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", Locale.UK);
    return sdf.format(new Date(epoch));
  }

  private WritableMap getMap(Transaction txn) {
    WritableMap map = Arguments.createMap();

    map.putString("value", txn.getAmount());
    map.putString("hash", txn.getHash());
    map.putString("status", txn.getStatus().name());
    map.putString("to", txn.getToAddress());
    map.putString("from", txn.getFromAddress());
    map.putString("timestamp", this.getTimestamp(txn.getTimestamp()));
    map.putString("gas_price", txn.getGasPrice());

    return map;
  }

  @Override
  public String getName() {
    return "RNZumoKit";
  }

}