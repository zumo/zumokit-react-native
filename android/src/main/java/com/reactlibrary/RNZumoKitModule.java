package com.reactlibrary;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import java.util.Date;
import java.util.TimeZone;
import java.text.SimpleDateFormat;

import com.blockstar.zumokit.Currency;
import com.blockstar.zumokit.Keystore;

public class RNZumoKitModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public RNZumoKitModule(ReactApplicationContext reactContext) {
    super(reactContext);
    
    this.reactContext = reactContext;

    Keystore newKeystore = new Keystore("c6800133-79b2-44d8-b5e8-168a04652886", Currency.ETH,
      "7357589f8e367c2c31f51242fb77b350a11830f3", "keystore_json");

  }

  @ReactMethod
  public void initialize() {

    // THis method is callable from the JS side.

  }

  @Override
  public String getName() {
    return "RNZumoKit";
  }

}