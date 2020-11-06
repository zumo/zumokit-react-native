import { AccountDataSnapshot, Account } from 'zumokit';
import { AccountFiatProperties } from 'zumokit/src/interfaces';
import { CurrencyCode, Network, AccountType, FiatCustomerData } from '../types/exported';
import { Wallet } from './Wallet';

/**
 * User interface describes methods for managing user wallet and accounts.
 * <p>
 * User instance can be obtained via {@link ZumoKit.signIn} method.
 * <p>
 * See <a href="https://developers.zumo.money/docs/guides/manage-user-wallet">Manage User Wallet</a>,
 * <a href="https://developers.zumo.money/docs/guides/create-fiat-account">Create Fiat Account</a> and
 * <a href="https://developers.zumo.money/docs/guides/view-user-data">View User Data</a>
 * guides for usage details.
 */
export interface User {
  /** User dentifier. */
  id: string;

  /** Indicator if user has wallet. */
  hasWallet: boolean;

  /** User accounts. */
  accounts: Array<Account>;

  /**
   * Create user wallet seeded by provided mnemonic and encrypted with user's password.
   * <p>
   * Mnemonic can be generated by {@link Utils.generateMnemonic} utility method.
   * @param  mnemonic       mnemonic seed phrase
   * @param  password       user provided password
   */
  createWallet(mnemonic: string, password: string): Promise<Wallet>;

  /**
   * Recover user wallet with mnemonic seed phrase corresponding to user's wallet.
   * This can be used if user forgets his password or wants to change his wallet password.
   * @param  mnemonic       mnemonic seed phrase corresponding to user's wallet
   * @param  password       user provided password
   */
  recoverWallet(mnemonic: string, password: string): Promise<Wallet>;

  /**
   * Unlock user wallet with user's password.
   * @param  password       user provided password
   */
  unlockWallet(password: string): Promise<Wallet>;

  /**
   * Reveal mnemonic seed phrase used to seed user wallet.
   * @param  password       user provided password
   */
  revealMnemonic(password: string): Promise<string>;

  /**
   * Check if mnemonic seed phrase corresponds to user's wallet.
   * This is useful for validating seed phrase before trying to recover wallet.
   * @param  mnemonic       mnemonic seed phrase
   */
  isRecoveryMnemonic(mnemonic: string): Promise<boolean>;

  /**
   * Get account in specific currency, on specific network, with specific type.
   * @param  currencyCode   currency code, e.g. 'BTC', 'ETH' or 'GBP'
   * @param  network        network type, e.g. 'MAINNET', 'TESTNET' or 'RINKEBY'
   * @param  type           account type, e.g. 'STANDARD', 'COMPATIBILITY' or 'SEGWIT'
   */
  getAccount(currencyCode: CurrencyCode, network: Network, type: AccountType): any | null;
  /**
   * Check if user is a fiat customer on 'MAINNET' or 'TESTNET' network.
   * @param  network 'MAINNET' or 'TESTNET'
   */
  isFiatCustomer(network: string): Promise<boolean>;
  /**
   * Make user fiat customer on specified network by providing user's personal details.
   * @param  network        'MAINNET' or 'TESTNET'
   * @param  customerData    user's personal details.
   */
  makeFiatCustomer(network: Network, customerData: FiatCustomerData): Promise<void>;

  /**
   * Create fiat account on specified network and currency code. User must already be fiat customer on specified network.
   * @param  network        'MAINNET' or 'TESTNET'
   * @param  currencyCode  country code in ISO 4217 format, e.g. 'GBP'
   */
  createFiatAccount(network: Network, currencyCode: CurrencyCode): Promise<Account>;

  /**
   * Get nominated account details for specified account if it exists.
   * Refer to
   * <a href="https://developers.zumo.money/docs/guides/send-transactions#bitcoin">Create Fiat Account</a>
   * for explanation about nominated account.
   * @param  accountId     {@link  Account Account} identifier
   */
  getNominatedAccountFiatProperties(accountId: string): Promise<AccountFiatProperties | null>;

  /**
   * Listen to all account data changes.
   *
   * @param listener interface to listen to user changes
   */
  addAccountDataListener(listener: (snapshots: Array<AccountDataSnapshot>) => void): void;

  /**
   * Remove listener to state changes.
   *
   * @param listener interface to listen to state changes
   */
  removeAccountDataListener(listener: (snapshots: Array<AccountDataSnapshot>) => void): void;
}
