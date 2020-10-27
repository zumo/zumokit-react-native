import { NativeModules } from 'react-native';
import ZKUtility from './ZKUtility';
import User from './User';
import tryCatchProxy from './errorProxy';
import FeeRates from './models/FeeRates';
import ExchangeRate from './models/ExchangeRate';
import HistoricalExchangeRates from './models/HistoricalExchangeRates';
import { parseHistoricalExchangeRates } from './utils/parse';
import { CurrencyCode, TokenSet, HistoricalExchangeRatesJSON } from './types';

const { RNZumoKit } = NativeModules;

/**
 * ZumoKit instance.
 * ```typescript
 * import ZumoKit from 'react-native-zumo-kit';
 * ```
 * <p>
 * See <a href="https://developers.zumo.money/docs/guides/getting-started">Getting Started</a> guide for usage details.
 * */
@tryCatchProxy
class ZumoKit {
  private currentUser: User = null;

  /** ZumoKit SDK semantic version tag if exists, commit hash otherwise. */
  version: string = RNZumoKit.version;

  /**
   * Signs in user corresponding to user token set. Sets current user to the newly signed in user.
   * Refer to <a href="https://developers.zumo.money/docs/setup/server#get-zumokit-user-token">Server</a> guide for details on how to get user token set.
   *
   * @param userTokenSet   user token set
   */
  async signIn(userTokenSet: TokenSet) {
    const json = await RNZumoKit.authUser(JSON.stringify(userTokenSet));
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
   * Returns crypto utility class.
   */
  getUtils(): typeof ZKUtility {
    return ZKUtility;
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
    const json = RNZumoKit.getExchangeSettings(fromCurrency, toCurrency);
    return json ? new ExchangeRate(json) : null;
  }

  /**
   * Get exchange settings for selected currency pair.
   *
   * @param currency   currency code
   *
   * @return fee rates or null
   */
  async getFeeRates(currency: CurrencyCode) {
    const json = RNZumoKit.getFeeRates(currency);
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
    const historicalExchangeRatesJSON = RNZumoKit.fetchHistoricalExchangeRates() as HistoricalExchangeRatesJSON;
    return parseHistoricalExchangeRates(historicalExchangeRatesJSON);
  }
}

export default new ZumoKit();
