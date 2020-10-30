import { NativeModules, NativeEventEmitter } from 'react-native';
import Utils from './Utils';
import User from './User';
import tryCatchProxy from './errorProxy';
import TransactionFeeRate from './models/TransactionFeeRate';
import ExchangeRate from './models/ExchangeRate';
import ExchangeSetting from './models/ExchangeSetting';
import HistoricalExchangeRates from './models/HistoricalExchangeRates';
import {
  parseExchangeRates,
  parseExchangeSettings,
  parseTransactionFeeRates,
  parseHistoricalExchangeRates,
} from './utils/parse';
import {
  Dictionary,
  CurrencyCode,
  TokenSet,
  HistoricalExchangeRatesJSON,
  ExchangeRateJSON,
  ExchangeSettingJSON,
  TransactionFeeRateJSON,
} from './types';

const { RNZumoKit } = NativeModules;

/**
 * Entry point to ZumoKit React Native SDK.
 * <p>
 * See <a href="https://developers.zumo.money/docs/guides/getting-started">Getting Started</a> guide for usage details.
 * */
@tryCatchProxy
class ZumoKit {
  // The emitter that bubbles events from the native side
  private emitter = new NativeEventEmitter(RNZumoKit);

  // Listeners for exchange rates, exchange settings and transaction fee rates changes
  private changeListeners: Array<() => void> = [];

  /** ZumoKit SDK semantic version tag if exists, commit hash otherwise. */
  version: string = RNZumoKit.version;

  /** Currently authenticated user. */
  currentUser: User = null;

  /** Crypto utilities. */
  utils: Utils = new Utils();

  /** Mapping between currency pairs and available exchange rates. */
  exchangeRates: Dictionary<CurrencyCode, Dictionary<CurrencyCode, ExchangeRate>> = {};

  /** Mapping between currency pairs and available exchange settings. */
  exchangeSettings: Dictionary<CurrencyCode, Dictionary<CurrencyCode, ExchangeSetting>> = {};

  /** Mapping between cryptocurrencies and available transaction fee rates. */
  transactionFeeRates: Dictionary<CurrencyCode, TransactionFeeRate> = {};

  /**
   * Initializes ZumoKit SDK. Should only be called once.
   * <p>
   * This function returns a Promise that resolves once ZumoKit SDK has loaded.
   *
   * @param apiKey        ZumoKit Api-Key
   * @param apiUrl        ZumoKit API url
   * @param txServiceUrl  ZumoKit Transaction Service url
   * */
  init(apiKey: string, apiUrl: string, txServiceUrl: string) {
    RNZumoKit.init(apiKey, apiUrl, txServiceUrl);

    this.emitter.addListener('AuxDataChanged', async () => {
      await this.updateAuxData();
      this.changeListeners.forEach((listener) => listener());
    });
  }

  /**
   * Signs in user corresponding to user token set. Sets current user to the newly signed in user.
   * Refer to <a href="https://developers.zumo.money/docs/setup/server#get-zumokit-user-token">Server</a> guide for details on how to get user token set.
   *
   * @param userTokenSet   user token set
   */
  async signIn(userTokenSet: TokenSet) {
    const json = await RNZumoKit.signIn(JSON.stringify(userTokenSet));
    this.currentUser = new User(json);
    await this.updateAuxData();
    return this.currentUser;
  }

  /**
   * Signs out current user. Should be called when user logs out.
   */
  async signOut() {
    await RNZumoKit.signOut();
    this.currentUser = null;
  }

  /**
   * Get exchange rate for selected currency pair.
   *
   * @param fromCurrency   currency code
   * @param toCurrency     currency code
   *
   * @return exchange rate or null
   */
  getExchangeRate(fromCurrency: CurrencyCode, toCurrency: CurrencyCode): ExchangeRate | null {
    return Object.keys(this.exchangeRates).includes(fromCurrency)
      ? this.exchangeRates[fromCurrency][toCurrency]
      : null;
  }

  /**
   * Get exchange setting for selected currency pair.
   *
   * @param fromCurrency   currency code
   * @param toCurrency     currency code
   *
   * @return exchange settings or null
   */
  getExchangeSetting(fromCurrency: CurrencyCode, toCurrency: CurrencyCode): ExchangeSetting | null {
    return Object.keys(this.exchangeSettings).includes(fromCurrency)
      ? this.exchangeSettings[fromCurrency][toCurrency]
      : null;
  }

  /**
   * Get transaction fee rate for selected crypto currency.
   *
   * @param currency   currency code
   *
   * @return transaction fee rate or null
   */
  getTransactionFeeRate(currency: CurrencyCode): TransactionFeeRate | null {
    return this.transactionFeeRates[currency];
  }

  /**
   * Fetch historical exchange rates for supported time intervals.
   * On success callback returns historical exchange rates are contained in
   * a mapping between
   * time interval on a top level, from currency on second level, to currency on third level and
   * {@link ExchangeRate ExchangeRate} objects.
   */
  async fetchHistoricalExchangeRates(): Promise<HistoricalExchangeRates> {
    const historicalExchangeRatesJSON = (await RNZumoKit.fetchHistoricalExchangeRates()) as HistoricalExchangeRatesJSON;
    return parseHistoricalExchangeRates(historicalExchangeRatesJSON);
  }

  /**
   * Listen to changes in exchange rates, exchange settings or transaction fee rates.
   *
   * @param listener interface to listen to user changes
   */
  addChangeListener(listener: () => void) {
    this.changeListeners.push(listener);
  }

  /**
   * Remove change listener.
   *
   * @param listener interface to listen to changes
   */
  removeChangeListener(listener: () => void) {
    let index = this.changeListeners.indexOf(listener);
    while (index !== -1) {
      this.changeListeners.splice(index, 1);
      index = this.changeListeners.indexOf(listener);
    }
  }

  private async updateAuxData(): Promise<void> {
    const exchangeRatesJSON = (await RNZumoKit.getExchangeRates()) as Record<
      string,
      Record<string, ExchangeRateJSON>
    >;
    const exchangeSettingsJSON = (await RNZumoKit.getExchangeSettings()) as Record<
      string,
      Record<string, ExchangeSettingJSON>
    >;
    const tranactionFeeRatesJSON = (await RNZumoKit.getTransactionFeeRates()) as Record<
      string,
      TransactionFeeRateJSON
    >;

    this.exchangeRates = parseExchangeRates(exchangeRatesJSON);
    this.exchangeSettings = parseExchangeSettings(exchangeSettingsJSON);
    this.transactionFeeRates = parseTransactionFeeRates(tranactionFeeRatesJSON);
  }
}

export default new ZumoKit();
