import { Network } from '../types/exported';

/**
 * Crypto utility inteface decribes methods for mnemonic phrase generatio and
 * Bitcoin/Ethereum address validation.
 */
export interface Utils {
  /**
   * Generates mnemonic seed phrase used in wallet creation process.
   * @param wordCount   12, 15, 18, 21 or 24
   */
  generateMnemonic(wordCount: number): Promise<string>;

  /**
   * Validates Ethereum address.
   * @param address Ethereum address
   */
  isValidEthAddress(address: string): Promise<boolean>;

  /**
   * Validates Bitcoin address on a given network.
   * @param address Bitcoin address
   * @param network network type, either 'MAINNET' or 'TESTNET'
   */
  isValidBtcAddress(address: string, network: Network): Promise<boolean>;
}
