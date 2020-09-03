
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

If your project does not yet support typescript, you will have to enable it:
```
yarn add --dev typescript @types/jest @types/react @types/react-native @types/react-test-renderer
```

ZumoKit React Native SDK uses experimental TypeScript decorators, support for which has to be enabled:
```
yarn add @babel/plugin-proposal-decorators -D
```

Then, modify `compilerOptions` in _tsconfig.json_:
```
"experimentalDecorators": true
```
and enable plugin `@babel/plugin-proposal-decorators` in _babel.config.json_:
```
plugins: [["@babel/plugin-proposal-decorators", { "legacy": true }]]
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

Import `ZumoKit` module from `react-native-zumo-kit` package:

```typescript
import ZumoKit from 'react-native-zumo-kit';
```

ZumoKit module is your entrypoint to ZumoKit SDK. Check your SDK version by calling:

```typescript
console.log(ZumoKit.version);
```

Once `ZumoKit` class is initialized via `ZumoKit.init` method, `ZKUtility` class with crypto utility classes can be globally accessed:

```typescript
import { ZKUtility } from 'react-native-zumo-kit';
```