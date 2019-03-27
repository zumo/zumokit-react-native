package com.zumokit.reactnative;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;

import com.blockstar.zumokit.ZumoKit;
import com.blockstar.zumokit.Store;
import com.blockstar.zumokit.State;
import com.blockstar.zumokit.Currency;
import com.blockstar.zumokit.Keystore;
import com.blockstar.zumokit.AndroidHttp;
import com.blockstar.zumokit.HttpImpl;

public class RNZumoKitModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  private ZumoKit zumoKit;
  private Store zumoStore;
  private State zumoState;

  public RNZumoKitModule(ReactApplicationContext reactContext) {
    super(reactContext);

    this.reactContext = reactContext;
  }

  @ReactMethod
  public void initialize() {

    String dbPath = this.reactContext
      .getFilesDir()
      .getAbsolutePath();

    this.zumoKit = new ZumoKit(dbPath);
    this.zumoStore = zumoKit.store();
    this.zumoState = zumoStore.getState();
    
  }

  @Override
  public String getName() {
    return "RNZumoKit";
  }

}