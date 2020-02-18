
# react-native-zumo-kit

## Setup

Install the package:

```
yarn add zumo/zumokit-react-native
```

Link the library (not required for React Native 0.60 and up):

```
react-native link react-native-zumo-kit
```

### Extra step for iOS

As ZumoKit is not yet distributed via CocoaPods Trunk, you'll need to include the [ZumoKit Spec](https://github.com/zumo/zumokit-specs) repo in your app's `Podfile` (usually located in the `ios` directory). You'll also need to ensure that the minimum iOS target is 10.0 or higher.

```ruby
platform :ios, '10.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/zumo/zumokit-specs.git'

target 'Demo' do
  # ...

  pod 'RNZumoKit', :path => '../node_modules/react-native-zumo-kit'

end
```

You will also need to execute `pod install` manually from the `ios` directory.

### Extra step for Android

Set `minSdkVersion` to 21 in your `android/build.gradle` settings.

## Usage

Import `ZumoKit` module from `react-native-zumo-kit` package:

```js
import ZumoKit from 'react-native-zumo-kit';
```

ZumoKit module is your entrypoint to ZumoKit SDK. Check your SDK version by calling:

```js
console.log(ZumoKit.VERSION);
```

Refer to ZumoKit SDK developer [documentation](https://developers.zumo.money/docs/intro/intro.html) and [reference](https://developers.zumo.money/docs/reference/react-native/overview.html) for usage details.