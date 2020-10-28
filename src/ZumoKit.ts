import { NativeModules } from 'react-native';
import Utils from './Utils';
import User from './User';
import tryCatchProxy from './errorProxy';
import FeeRates from './models/FeeRates';
import ExchangeRate from './models/ExchangeRate';
import ExchangeSettings from './models/ExchangeSettings';
import HistoricalExchangeRates from './models/HistoricalExchangeRates';
import { parseHistoricalExchangeRates } from './utils/parse';
import { CurrencyCode, TokenSet, HistoricalExchangeRatesJSON } from './types';

const { RNZumoKit } = NativeModules;

/**
 * Entry point to ZumoKit React Native SDK.
 * ```
 * <p>
 * See <a href="https://developers.zumo.money/docs/guides/getting-started">Getting Started</a> guide for usage details.
 * */
@tryCatchProxy
class ZumoKit {
  /** ZumoKit SDK semantic version tag if exists, commit hash otherwise. */
  version: string = RNZumoKit.version;

  /** Currently authenticated user. */
  currentUser: User = null;

  /** Crypto utilities. */
  utils: Utils = new Utils();

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
  async getExchangeRate(fromCurrency: CurrencyCode, toCurrency: CurrencyCode) {
    const json = await RNZumoKit.getExchangeRate(fromCurrency, toCurrency);
    return json ? new ExchangeRate(json) : null;
  }

  /**
   * Get exchange settings for selected currency pair.
   *
   * @param fromCurrency   currency code
   * @param toCurrency     currency code
   *
   * @return exchange rate or null
   */
  async getExchangeSettings(fromCurrency: CurrencyCode, toCurrency: CurrencyCode) {
    const json = await RNZumoKit.getExchangeSettings(fromCurrency, toCurrency);
    return json ? new ExchangeSettings(json) : null;
  }

  /**
   * Get exchange settings for selected currency pair.
   *
   * @param currency   currency code
   *
   * @return fee rates or null
   */
  async getFeeRates(currency: CurrencyCode) {
    const json = await RNZumoKit.getFeeRates(currency);
    return json ? new FeeRates(json) : null;
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
}

export default new ZumoKit();
