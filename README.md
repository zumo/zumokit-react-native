
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

#### Initialisation

The first step in getting ZumoKit integrated into your app is initialising it. Using the credentials provided to you by Zumo, you can use the `ZumoKit.init()` method do get started.

You'll need the following:

- `apiKey`
- `appId`
- `apiRoot`

```javascript
import ZumoKit from 'react-native-zumo-kit';

ZumoKit.init({
	appId: '12a3456-92de-45gh-0000-2d451a54111',
	apiKey: 'abc123456789defhij',
	apiRoot: 'https://zumokit.provider.com'
});
```

#### Wallet Creation

### `ZKUtility`

The `ZKUtility` class offers a few helpful methods that will help fully integrate ZumoKit into your app.

#### `getExchangeRates()`

Loads live exchange rates for ETH and BTC to Fiat prices. Currently this returns EUR and USD.

```js
import { ZKUtility } from 'react-native-zumo-kit';

await ZKUtility.getExchangeRates();
```

#### `getFiat(eth)`

Converts a given ETH value into GBP. This will later be expanded to support exchange into a variety of fiat currencies.

```js
import { ZKUtility } from 'react-native-zumo-kit';

await ZKUtility.getFiat(1.5);
```

#### `isValidEthAddress(address)`

Validates an etherium address.

```js
import { ZKUtility } from 'react-native-zumo-kit';

await ZKUtility.isValidEthAddress('0x14d24tdws3rfsasb1356');
```

## Models

There are a few models that are provided by ZumoKit that represent various structures on the API and blockchain.

- Transaction
- Wallet