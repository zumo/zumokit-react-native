import { NativeModules } from 'react-native';
import ZumoKit from './ZumoKit';

const { RNZumoKit } = NativeModules;

/**
 * Entry point to ZumoKit Web SDK. Should only be called once.
 * <p>
 * This function returns a Promise that resolves with a newly created ZumoKit
 * object once ZumoKit SDK has loaded.
 *
 * @param apiKey        ZumoKit Api-Key
 * @param apiUrl        ZumoKit API url
 * @param txServiceUrl  ZumoKit Transaction Service url
 * */
const loadZumoKit = async (apiKey: string, apiUrl: string, txServiceUrl: string) => {
  await RNZumoKit.init(apiKey, apiUrl, txServiceUrl);
  return ZumoKit;
};

export { loadZumoKit };
