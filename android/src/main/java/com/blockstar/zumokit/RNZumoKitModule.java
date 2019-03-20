package com.blockstar.zumokit;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;

import com.blockstar.zumokit.ZumoCore;
import com.blockstar.zumokit.Store;
import com.blockstar.zumokit.State;
import com.blockstar.zumokit.Currency;
import com.blockstar.zumokit.Keystore;

public class RNZumoKitModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  private ZumoCore zumoCore;
  private Store zumoStore;
  private State zumoState;

  public RNZumoKitModule(ReactApplicationContext reactContext) {
    super(reactContext);

    this.reactContext = reactContext;
  }

  @ReactMethod
  public void initialize() {

    // Abstracting this out into a method so it's not called before we need it.
    // Ultimately this will have URL and keys like the current JS implementation.

     String dbPath = this.reactContext
       .getFilesDir()
       .getAbsolutePath();

     HttpImpl httpImpl = new AndroidHttp();

     this.zumoCore = ZumoCore.init(dbPath, httpImpl);
     this.zumoStore = this.zumoCore.store();
     this.zumoState = zumoStore.getState();

  }

  @Override
  public String getName() {
    return "RNZumoKit";
  }

}