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

public class RNZumoKitModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public RNZumoKitModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  private WritableMap hello(String name) {
    WritableMap map = Arguments.createMap();
    
    Date date = new Date(System.currentTimeMillis());
    SimpleDateFormat sdf;
    sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX");
    sdf.setTimeZone(TimeZone.getTimeZone("CET"));
    String timestamp = sdf.format(date);

    map.putString("name", name);
    map.putString("timestamp", timestamp);

    return map;
  }

  @ReactMethod
  public void hello(String name, Promise promise) {
    promise.resolve(this.hello(name));
  }

  @Override
  public String getName() {
    return "RNZumoKit";
  }
}