import { NativeModules } from 'react-native';
import { Network } from 'zumokit/src/types';
import { Utils as IUtils } from './interfaces';
import { tryCatchProxy } from './utility/errorProxy';

const { RNZumoKit } = NativeModules;

@tryCatchProxy
export class Utils implements IUtils {
  async generateMnemonic(wordCount: number): Promise<string> {
    return RNZumoKit.generateMnemonic(wordCount);
  }

  async isValidEthAddress(address: string): Promise<boolean> {
    return RNZumoKit.isValidEthAddress(address);
  }

  async isValidBtcAddress(address: string, network: Network): Promise<boolean> {
    return RNZumoKit.isValidBtcAddress(address, network);
  }
}
