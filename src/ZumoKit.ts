import { NativeModules, NativeEventEmitter } from 'react-native';
import { ExchangeRate } from 'zumokit/src/models/ExchangeRate';
import { ExchangeRates } from 'zumokit/src/models/ExchangeRates';
import { ExchangeSetting } from 'zumokit/src/models/ExchangeSetting';
import { ExchangeSettings } from 'zumokit/src/models/ExchangeSettings';
import { TransactionFeeRate } from 'zumokit/src/models/TransactionFeeRate';
import { TransactionFeeRates } from 'zumokit/src/models/TransactionFeeRates';
import { HistoricalExchangeRates } from 'zumokit/src/models/HistoricalExchangeRates';
import {
  CurrencyCode,
  TokenSet,
  HistoricalExchangeRatesJSON,
  ExchangeRateJSON,
  ExchangeSettingJSON,
  TransactionFeeRateJSON,
  Dictionary,
} from 'zumokit/src/types';
import { ZumoKit as IZumoKit } from './interfaces';
import { Utils } from './Utils';
import { User } from './User';
import { tryCatchProxy } from './utility/errorProxy';

const {
  /** @internal */
  RNZumoKit,
} = NativeModules;

@tryCatchProxy
class ZumoKit implements IZumoKit {
  // The emitter that bubbles events from the native side
  private emitter = new NativeEventEmitter(RNZumoKit);

  // Listeners for exchange rates, exchange settings and transaction fee rates changes
  private changeListeners: Array<() => void> = [];

  version: string = RNZumoKit.version;

  currentUser: User | null = null;

  utils: Utils = new Utils();

  exchangeRates: ExchangeRates = {};

  exchangeSettings: ExchangeSettings = {};

  transactionFeeRates: TransactionFeeRates = {};

  init(apiKey: string, apiUrl: string, txServiceUrl: string) {
    RNZumoKit.init(apiKey, apiUrl, txServiceUrl);

    this.emitter.addListener('AuxDataChanged', async () => {
      await this.updateAuxData();
      this.changeListeners.forEach((listener) => listener());
    });
  }

  async signIn(userTokenSet: TokenSet) {
    const json = await RNZumoKit.signIn(JSON.stringify(userTokenSet));
    this.currentUser = new User(json);
    await this.updateAuxData();
    return this.currentUser;
  }

  async signOut() {
    await RNZumoKit.signOut();
    this.currentUser = null;
  }

  getExchangeRate(fromCurrency: CurrencyCode, toCurrency: CurrencyCode): ExchangeRate | null {
    return Object.keys(this.exchangeRates).includes(fromCurrency)
      ? ((this.exchangeRates[fromCurrency] as Dictionary<CurrencyCode, ExchangeRate>)[
          toCurrency
        ] as ExchangeRate)
      : null;
  }

  getExchangeSetting(fromCurrency: CurrencyCode, toCurrency: CurrencyCode): ExchangeSetting | null {
    return Object.keys(this.exchangeSettings).includes(fromCurrency)
      ? ((this.exchangeSettings[fromCurrency] as Dictionary<CurrencyCode, ExchangeSetting>)[
          toCurrency
        ] as ExchangeSetting)
      : null;
  }

  getTransactionFeeRate(currency: CurrencyCode): TransactionFeeRate | null {
    return Object.keys(this.transactionFeeRates).includes(currency)
      ? (this.transactionFeeRates[currency] as TransactionFeeRate)
      : null;
  }

  async fetchHistoricalExchangeRates(): Promise<HistoricalExchangeRates> {
    const historicalExchangeRatesJSON = (await RNZumoKit.fetchHistoricalExchangeRates()) as HistoricalExchangeRatesJSON;
    return HistoricalExchangeRates(historicalExchangeRatesJSON);
  }

  addChangeListener(listener: () => void) {
    this.changeListeners.push(listener);
  }

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

    this.exchangeRates = ExchangeRates(exchangeRatesJSON);
    this.exchangeSettings = ExchangeSettings(exchangeSettingsJSON);
    this.transactionFeeRates = TransactionFeeRates(tranactionFeeRatesJSON);
  }
}

export default new ZumoKit();
