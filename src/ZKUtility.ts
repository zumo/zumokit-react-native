import { NativeModules } from 'react-native';
import Decimal from 'decimal.js';
import tryCatchProxy from './ZKErrorProxy';
import { Network } from './types';

const { RNZumoKit } = NativeModules;

@tryCatchProxy
export default class ZKUtility {
  async generateMnemonic(wordCount: number) {
    return RNZumoKit.generateMnemonic(wordCount);
  }

  async isValidEthAddress(address: string) {
    return RNZumoKit.isValidEthAddress(address);
  }

  async isValidBtcAddress(address: string, network: Network) {
    return RNZumoKit.isValidBtcAddress(address, network);
  }

  async ethToGwei(eth: Decimal) {
    return RNZumoKit.ethToGwei(eth.toString());
  }

  async gweiToEth(gwei: Decimal) {
    return RNZumoKit.gweiToEth(gwei.toString());
  }

  async ethToWei(eth: Decimal) {
    return RNZumoKit.ethToWei(eth.toString());
  }

  async weiToEth(wei: Decimal) {
    return RNZumoKit.weiToEth(wei.toString());
  }
}
