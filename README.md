
# react-native-zumo-kit

## Getting started

`$ npm install react-native-zumo-kit --save`

### Mostly automatic installation

`$ react-native link react-native-zumo-kit`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-zumo-kit` and add `RNZumoKit.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNZumoKit.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.zumokit.reactnative.RNZumoKitPackage;` to the imports at the top of the file
  - Add `new RNZumoKitPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-zumo-kit'
  	project(':react-native-zumo-kit').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-zumo-kit/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-zumo-kit')
  	```

## Usage

ZumoKit provides three core classes that offer a variety of methods when interacting with the Zumo network. The classes can be imported into your codebase using the following:

```javascript
import ZumoKit from 'react-native-zumo-kit';
import { ZKUtility, ZKAPI } from 'react-native-zumo-kit';
```

### `ZumoKit`

This is the core class that offers the most interaction with the Zumo network and will be how a wallet is created or retreived.

### `ZKUtility`

The `ZKUtility` class offers a few helpful methods that will help fully integrate ZumoKit into your app.

### `ZKAPI`

You'll need to interface with the Zumo API to fully integrate ZumoKit. There are a few methods that the `ZKAPI` class offer that can help with this.

  