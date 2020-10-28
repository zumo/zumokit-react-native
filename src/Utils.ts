import { NativeModules } from 'react-native';
import tryCatchProxy from './errorProxy';
import { Network } from './types';

const { RNZumoKit } = NativeModules;

/**
 * Crypto utility class provides mnemonic phrase generation utility and
 * Bitcoin/Ethereum address validation utilities.
 */
@tryCatchProxy
export default class Utils {
  /**
   * Generates mnemonic seed phrase used in wallet creation process.
   * @param wordCount   12, 15, 18, 21 or 24
   */
  async generateMnemonic(wordCount: number): Promise<string> {
    return RNZumoKit.generateMnemonic(wordCount);
  }

  /**
   * Validates Ethereum address.
   * @param address Ethereum address
   */
  async isValidEthAddress(address: string): Promise<boolean> {
    return RNZumoKit.isValidEthAddress(address);
  }

  /**
   * Validates Bitcoin address on a given network.
   * @param address Bitcoin address
   * @param network network type, either 'MAINNET' or 'TESTNET'
   */
  async isValidBtcAddress(address: string, network: Network): Promise<boolean> {
    return RNZumoKit.isValidBtcAddress(address, network);
  }
}
