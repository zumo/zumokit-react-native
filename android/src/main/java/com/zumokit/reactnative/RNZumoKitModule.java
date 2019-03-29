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

import java.util.ArrayList;

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

    this.zumoKit = new ZumoKit(dbPath);
    
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
      response.pushMap(map);
    }

    // Resolve the promise with the array
    promise.resolve(response);

  }

  @Override
  public String getName() {
    return "RNZumoKit";
  }

}