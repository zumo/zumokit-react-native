import {
  ExchangeRate,
  ExchangeRates,
  ExchangeSetting,
  ExchangeSettings,
  TransactionFeeRate,
  TransactionFeeRates,
  HistoricalExchangeRates,
} from 'zumokit';
import { Utils } from './Utils';
import { User } from './User';
import { TokenSet, CurrencyCode } from '../types/exported';

/**
 * ZumoKit interface.
 * <p>
 * See <a href="https://developers.zumo.money/docs/guides/getting-started">Getting Started</a> guide for usage details.
 * */
export interface ZumoKit {
  /** ZumoKit SDK semantic version tag if exists, commit hash otherwise. */
  version: string;

  /** Currently signed-in user or null. */
  currentUser: User | null;

  /** Crypto utilities. */
  utils: Utils;

  /** Mapping between currency pairs and available exchange rates. */
  exchangeRates: ExchangeRates;

  /** Mapping between currency pairs and available exchange settings. */
  exchangeSettings: ExchangeSettings;

  /** Mapping between cryptocurrencies and available transaction fee rates. */
  transactionFeeRates: TransactionFeeRates;

  /**
   * Signs in user corresponding to user token set. Sets current user to the newly signed in user.
   * Refer to <a href="https://developers.zumo.money/docs/setup/server#get-zumokit-user-token">Server</a> guide for details on how to get user token set.
   *
   * @param tokenSet   user token set
   */
  signIn(userTokenSet: TokenSet): Promise<User>;

  /** Signs out current user. */
  signOut(): void;
  /**
   * Get exchange rate for selected currency pair.
   *
   * @param fromCurrency   currency code
   * @param toCurrency     currency code
   *
   * @return exchange rate or null
   */
  getExchangeRate(fromCurrency: CurrencyCode, toCurrency: CurrencyCode): ExchangeRate | null;

  /**
   * Get exchange setting for selected currency pair.
   *
   * @param fromCurrency   currency code
   * @param toCurrency     currency code
   *
   * @return exchange setting or null
   */
  getExchangeSetting(fromCurrency: CurrencyCode, toCurrency: CurrencyCode): ExchangeSetting | null;

  /**
   * Get transaction fee rate for selected crypto currency.
   *
   * @param currency   currency code
   *
   * @return transaction fee rate or null
   */
  getTransactionFeeRate(currency: CurrencyCode): TransactionFeeRate | null;

  /**
   * Fetch historical exchange rates for supported time intervals.
   *
   * @return historical exchange rates
   */
  fetchHistoricalExchangeRates(): Promise<HistoricalExchangeRates>;

  /**
   * Listen to changes in current user’s sign in state, exchange rates, exchange settings or transaction fee rates.
   *
   * @param listener interface to listen to changes
   */
  addChangeListener(listener: () => void): void;

  /**
   * Remove change listener.
   *
   * @param listener interface to listen to changes
   */
  removeChangeListener(listener: () => void): void;
}
