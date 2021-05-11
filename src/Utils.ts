import { NativeModules } from 'react-native';
import { CurrencyCode, Network } from 'zumokit/src/interfaces';
import { tryCatchProxy } from './utility/errorProxy';

const {
  /** @internal */
  RNZumoKit,
} = NativeModules;

/**
 * Crypto utility interface describes methods for mnemonic phrase generation and
 * Bitcoin/Ethereum address validation.
 */
@tryCatchProxy
export class Utils {
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
   * Validates Ethereum, Bitcoin or Bitcoin SV address.
   * @param currencyCode 'ETH', 'BTC or 'BSV'
   * @param address      blockchain address
   * @param network      network type
   */
  isValidAddress(currencyCode: CurrencyCode, address: string, network: Network): boolean {
    return RNZumoKit.isValidAddress(currencyCode, address, network);
  }
}
