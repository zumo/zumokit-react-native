import { NativeModules } from 'react-native';
import Decimal from 'decimal.js';
import tryCatchProxy from './ZKErrorProxy';
import { Network } from './types';

const { RNZumoKit } = NativeModules;

/**
 * Crypto utility class can be used once {@link ZumoKit} module is {@link ZumoKit.init initialized}. Access it as follows:
 *
 * ```typescript
 * import { ZKUtility } from 'react-native-zumo-kit';
 * ```
 *
 * This class provides mnemonic phrase generation utility, Bitcoin & Ethereum
 * address validation utilities and Ethereum unit conversion methods.
 */
@tryCatchProxy
class ZKUtility {
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

  /**
   * Converts ETH value to gwei.
   * @param number ETH value to be converted
   */
  async ethToGwei(eth: Decimal): Promise<Decimal> {
    return new Decimal(RNZumoKit.ethToGwei(eth.toString()));
  }

  /**
   * Converts gwei value to ETH.
   * @param number gwei value to be converted
   */
  async gweiToEth(gwei: Decimal): Promise<Decimal> {
    return new Decimal(RNZumoKit.gweiToEth(gwei.toString()));
  }

  /**
   * Converts ETH value to wei.
   * @param number ETH value to be converted
   */
  async ethToWei(eth: Decimal): Promise<Decimal> {
    return new Decimal(RNZumoKit.ethToWei(eth.toString()));
  }

  /**
   * Converts wei value to ETH.
   * @param number wei value to be converted
   */
  async weiToEth(wei: Decimal): Promise<Decimal> {
    return new Decimal(RNZumoKit.weiToEth(wei.toString()));
  }
}

export default new ZKUtility();
