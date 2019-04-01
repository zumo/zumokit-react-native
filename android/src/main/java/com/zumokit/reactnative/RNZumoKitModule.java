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
import com.blockstar.zumokit.BlockchainCallback;

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

    String txServiceUrl = "wss://4413eb50.ngrok.io";
    
    this.zumoKit = new ZumoKit(dbPath, txServiceUrl);

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
  public void getWallets(Promise promise) {
    
    // Fetch the keystores from the state
    State state = this.zumoKit.store().getState();
    ArrayList<Keystore> keystores = state.getKeystores();

    // Create a map to resolve the promise
    WritableArray response = Arguments.createArray();

    // Loop through the keystores and covert to maps.
    for (Keystore keystore : keystores) {
      WritableMap map = Arguments.createMap();
      map.putString("id", keystore.getId());
      map.putString("address", keystore.getAddress());
      map.putBoolean("unlocked", keystore.getUnlocked());
      response.pushMap(map);
    }

    // Resolve the promise with the array
    promise.resolve(response);

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
    String timestamp = this.getTimestamp();

    wm.sendTransaction(keystore, address, amount, "myPayload", new BlockchainCallback() {
      
      @Override
      public void onError(String error) {
        promise.reject(error);
      }

      @Override
      public void onSuccess(String response) {
        WritableMap map = Arguments.createMap();

        map.putString("amount", amount);
        map.putString("hash", response);
        map.putString("status", "PENDING");
        map.putString("to", address);
        map.putString("from", keystore.getAddress());
        map.putString("timestamp", timestamp);

        promise.resolve(map);
      }

    });

  }

  private String getTimestamp() {
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", Locale.UK);
    return sdf.format(new Date());
  }

  @Override
  public String getName() {
    return "RNZumoKit";
  }

}