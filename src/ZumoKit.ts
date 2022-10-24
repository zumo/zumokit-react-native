import { NativeModules, NativeEventEmitter } from "react-native";
import {
  ExchangeRate,
  ExchangeRates,
  TransactionFeeRate,
  TransactionFeeRates,
  HistoricalExchangeRates,
} from "zumokit/src/models";
import {
  LogLevel,
  CurrencyCode,
  TokenSet,
  HistoricalExchangeRatesJSON,
  ExchangeRateJSON,
  TransactionFeeRateJSON,
} from "zumokit/src/interfaces";
import { Utils } from "./Utils";
import { User } from "./User";
import { tryCatchProxy } from "./utility/errorProxy";

const {
  /** @internal */
  RNZumoKit,
} = NativeModules;

/**
 * ZumoKit entry point. Refer to <a href="https://developers.zumo.money/docs/guides/initialize-zumokit">documentation</a> for usage details.
 * */
@tryCatchProxy
class ZumoKit {
  // The emitter that bubbles events from the native side
  private emitter = new NativeEventEmitter(RNZumoKit);

  // Listeners for exchange rates and transaction fee rates changes
  private changeListeners: Array<() => void> = [];

  /** ZumoKit SDK semantic version tag if exists, commit hash otherwise. */
  version: string = RNZumoKit.version;

  /** Currently signed-in user or null. */
  currentUser: User | null = null;

  /** Crypto utilities. */
  utils: Utils = new Utils();

  /** Mapping between currency pairs and available exchange rates. */
  exchangeRates: ExchangeRates = {};

  /** Mapping between cryptocurrencies and available transaction fee rates. */
  transactionFeeRates: TransactionFeeRates = {};

  /**
   * Sets log level for current logger.
   *
   * @param logLevel log level, e.g. 'debug' or 'info'
   */
  setLogLevel(logLevel: LogLevel) {
    RNZumoKit.setLogLevel(logLevel);
  }

  /**
   * Sets log handler for all ZumoKit related logs.
   *
   * @param listener interface to listen to changes
   * @param logLevel log level, e.g. 'debug' or 'info'
   */
  onLog(
    listener: (logEntry: {
      timestamp: number;
      level: LogLevel;
      process: number;
      thread: number;
      message: string;
      data: any;
    }) => void,
    logLevel: LogLevel
  ) {
    this.emitter.addListener("OnLog", (message: string) => {
      listener(JSON.parse(message));
    });

    RNZumoKit.addLogListener(logLevel);
  }

  /**
   * Initializes ZumoKit SDK. Should only be called once.
   *
   * @param apiKey                 ZumoKit API key
   * @param apiUrl                 ZumoKit API URL
   * @param transactionServiceUrl  ZumoKit Transaction Service URL
   * @param cardServiceUrl         ZumoKit Card Service URL
   * @param notificationServiceUrl ZumoKit Notification Service URL
   * @param exchangeServiceUrl     ZumoKit Exchange Service URL
   */
  init(
    apiKey: string,
    apiUrl: string,
    txServiceUrl: string,
    cardServiceUrl: string,
    notificationServiceUrl: string,
    exchangeServiceUrl: string
  ) {
    this.emitter.addListener("AuxDataChanged", async () => {
      await this.updateAuxData();
      this.changeListeners.forEach((listener) => listener());
    });

    RNZumoKit.init(
      apiKey,
      apiUrl,
      txServiceUrl,
      cardServiceUrl,
      notificationServiceUrl,
      exchangeServiceUrl
    );
  }

  /**
   * Signs in user corresponding to user token set. Sets current user to the newly signed in user.
   * Refer to <a href="https://developers.zumo.money/docs/setup/server#get-zumokit-user-token">Server</a> guide for details on how to get user token set.
   *
   * @param tokenSet   user token set
   */
  async signIn(userTokenSet: TokenSet) {
    const json = await RNZumoKit.signIn(JSON.stringify(userTokenSet));
    this.currentUser = new User(json);
    await this.updateAuxData();
    return this.currentUser;
  }

  /** Signs out current user. */
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
  getExchangeRate(
    fromCurrency: CurrencyCode,
    toCurrency: CurrencyCode
  ): ExchangeRate | null {
    return Object.keys(this.exchangeRates).includes(fromCurrency)
      ? this.exchangeRates[fromCurrency]![toCurrency]!
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
    return Object.keys(this.transactionFeeRates).includes(currency)
      ? this.transactionFeeRates[currency]!
      : null;
  }

  /**
   * Fetch historical exchange rates for supported time intervals.
   *
   * @return historical exchange rates
   */
  async fetchHistoricalExchangeRates(): Promise<HistoricalExchangeRates> {
    const historicalExchangeRatesJSON = (await RNZumoKit.fetchHistoricalExchangeRates()) as HistoricalExchangeRatesJSON;
    return HistoricalExchangeRates(historicalExchangeRatesJSON);
  }

  /**
   * Listen to changes in current user’s sign in state, exchange rates, exchange settings or transaction fee rates.
   *
   * @param listener interface to listen to changes
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
    const transactionFeeRatesJSON = (await RNZumoKit.getTransactionFeeRates()) as Record<
      string,
      TransactionFeeRateJSON
    >;

    this.exchangeRates = ExchangeRates(exchangeRatesJSON);
    this.transactionFeeRates = TransactionFeeRates(transactionFeeRatesJSON);
  }
}

export { ZumoKit };

export default new ZumoKit();
