
# ZumoKit React Native SDK

ZumoKit is a state of the art wallet architecture underpinning our flagship product [Zumo](https://www.zumo.money/) that provides secure transfer and exchange of fiat and cryptocurrency funds.

## Docs

Refer to ZumoKit SDK developer [documentation](https://developers.zumo.money/docs/) and [reference](https://zumo.github.io/react-native/) for usage details.

## Installation

Install the package:

```
yarn add zumo/zumokit-react-native
```

Link the library (not required for React Native 0.60 and up):

```
react-native link react-native-zumo-kit
```

ZumoKit React Native SDK uses experimental TypeScript decorators, support for which has to be enabled:

```
yarn add @babel/plugin-proposal-decorators -D
```

Then, enable plugin `@babel/plugin-proposal-decorators` in _babel.config.json_:

```
plugins: [["@babel/plugin-proposal-decorators", { "legacy": true }]]
```

If your project uses typescript, modify `compilerOptions` in _tsconfig.json_:

```
"experimentalDecorators": true
```

### Extra step for iOS

As ZumoKit is not yet distributed via CocoaPods Trunk, you'll need to include the [ZumoKit Spec](https://github.com/zumo/zumokit-specs) repo in your app's _Podfile_ (usually located in the _ios_ directory). You'll also need to ensure that the minimum iOS target is 10.0 or higher.

```ruby
platform :ios, '10.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/zumo/zumokit-specs.git'

target 'Demo' do
  # ...

  pod 'RNZumoKit', :path => '../node_modules/react-native-zumo-kit'

end
```

You will also need to execute `pod install` manually from the _ios_ directory.

### Extra step for Android

Set `minSdkVersion` to 21 in your _android/build.gradle_ settings.

## Usage

Entry point to ZumoKit SDK is `loadZumoKit` function. This function returns a Promise that resolves with a newly created ZumoKit object once ZumoKit SDK has loaded.

```typescript
import { loadZumoKit } from 'react-native-zumo-kit';

const zumokit = await loadZumoKit(API_KEY, API_ROOT, TX_SERVICE_URL);
console.log(zumokit.version)
```

 Ask your [account manager](mailto:support@zumo.money) to provide you with neccesarry credentials.