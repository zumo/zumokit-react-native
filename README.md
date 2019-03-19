
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
  - Add `import com.reactlibrary.RNZumoKitPackage;` to the imports at the top of the file
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
```javascript
import RNZumoKit from 'react-native-zumo-kit';

// TODO: What to do with the module?
RNZumoKit;
```
  