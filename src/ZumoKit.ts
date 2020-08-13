import { NativeModules, NativeEventEmitter } from 'react-native';
import User from './models/User';
import Account from './models/Account';
import Parser from './util/Parser';
import tryCatchProxy from './ZKErrorProxy';
import Transaction from './models/Transaction';
import Exchange from './models/Exchange';
import {
  Dictionary,
  CurrencyCode,
  ZumoKitConfig,
  TokenSet,
  StateJSON,
  TimeInterval,
  HistoricalExchangeRatesJSON,
} from './types';
import FeeRates from './models/FeeRates';
import ExchangeRate from './models/ExchangeRate';
import ExchangeSettings from './models/ExchangeSettings';

const { RNZumoKit } = NativeModules;

interface State {
  authenticatedUser: User | null;
  accounts: Array<Account>;
  transactions: Array<Transaction>;
  exchanges: Array<Exchange>;
  feeRates: Dictionary<CurrencyCode, FeeRates>;
  exchangeRates: Dictionary<CurrencyCode, Dictionary<CurrencyCode, ExchangeRate>>;
  exchangeSettings: Dictionary<CurrencyCode, Dictionary<CurrencyCode, ExchangeSettings>>;
}

type HistoricalExchangeRates = Dictionary<
  TimeInterval,
  Dictionary<CurrencyCode, Dictionary<CurrencyCode, ExchangeRate>>
>;

/**
 * Entry point to ZumoKit React Native SDK:
 * ```typescript
 * import ZumoKit from 'react-native-zumo-kit';
 * ```
 * Once ZumoKit is {@link init | initialized}, this class provides access to {@Link getUser | user retrieval}, {@link state | ZumoKit state object} and {@link getHistoricalExchangeRates | historical exchange rates}.
 * State change listeners can be  {@link addStateListener added} and {@link removeStateListener removed}.
 * <p>
 * See <a href="https://developers.zumo.money/docs/guides/getting-started">Getting Started</a> guide for usage details.
 * */
@tryCatchProxy
class ZumoKit {
  /**
   * Current ZumoKit state. Refer to
   * <a href="https://developers.zumo.money/docs/guides/zumokit-state">ZumoKit State</a>
   * guide for details.
   */
  public state: State;

  // The emitter that bubbles events from the native side.
  private emitter = new NativeEventEmitter(RNZumoKit);

  // Internal JS listeners for state changes.
  private listeners: Array<(state: State) => void> = [];

  /** ZumoKit SDK semantic version tag if exists, commit hash otherwise. */
  version: string = RNZumoKit.version;

  /**
   * Initializes ZumoKit SDK. Should only be called once.
   *
   * @param config ZumoKit config
   */
  init(config: ZumoKitConfig) {
    this.state = {
      authenticatedUser: null,
      accounts: [],
      transactions: [],
      exchanges: [],
      feeRates: null,
      exchangeRates: null,
      exchangeSettings: null,
    };

    const { apiKey, apiRoot, txServiceUrl } = config;
    RNZumoKit.init(apiKey, apiRoot, txServiceUrl);

    this.emitter.addListener('StateChanged', (state: StateJSON) => {
      this.state.accounts = Parser.parseAccounts(state.accounts);
      this.state.transactions = Parser.parseTransactions(state.transactions);
      this.state.exchanges = Parser.parseExchanges(state.exchanges);
      this.state.exchangeRates = Parser.parseExchangeRates(state.exchangeRates);
      this.state.feeRates = Parser.parseFeeRates(state.feeRates);
      this.state.exchangeSettings = Parser.parseExchangeSettings(state.exchangeSettings);

      this.notifyStateListeners();
    });
  }

  /**
   * Get user corresponding to user token set.
   * Refer to <a href="https://developers.zumo.money/docs/setup/server#get-zumokit-user-token">Server</a> guide for details on how to get user token set.
   *
   * @param tokenSet   user token set
   */
  async getUser(tokenSet: TokenSet) {
    const json = await RNZumoKit.getUser(JSON.stringify(tokenSet));
    const user = new User(json);

    this.state.authenticatedUser = user;

    this.notifyStateListeners();

    return user;
  }

  /**
   * Fetch historical exchange rates for supported time intervals.
   * On success callback returns historical exchange rates are contained in a mapping between
   * time interval on a top level, from currency on second level, to currency on third level and
   * {@link ExchangeRate ExchangeRate} objects.
   */
  async getHistoricalExchangeRates(): Promise<HistoricalExchangeRates> {
    const historicalExchangeRatesJSON = RNZumoKit.getHistoricalExchangeRates() as HistoricalExchangeRatesJSON;
    const historicalExchangeRates: HistoricalExchangeRates = {};
    Object.keys(historicalExchangeRatesJSON).forEach((timeInterval) => {
      historicalExchangeRates[timeInterval as TimeInterval] = Parser.parseExchangeRates(
        historicalExchangeRatesJSON[timeInterval]
      );
    });
    return historicalExchangeRates;
  }

  /**
   * Listen to all state changes. Refer to <a href="https://developers.zumo.money/docs/guides/zumokit-state#listen-to-state-changes">ZumoKit State</a> guide for details.
   *
   * @param listener interface to listen to state changes
   */
  addStateListener(listener: (state: State) => void) {
    if (this.listeners.includes(listener)) return;
    this.listeners.push(listener);
    listener(this.state);
  }

  /**
   * Remove listener to state changes. Refer to <a href="https://developers.zumo.money/docs/guides/zumokit-state#remove-state-listener">ZumoKit State</a> guide for details.
   *
   * @param listener interface to listen to state changes
   */
  removeStateListener(listener: (state: State) => void) {
    if (!this.listeners.includes(listener)) return;
    const index = this.listeners.indexOf(listener);
    this.listeners.splice(index, 1);
  }

  private notifyStateListeners() {
    this.listeners.forEach((listener: (state: State) => void) => listener(this.state));
  }

  /**
   * Clear ZumoKit SDK state. Should be called when user logs out.
   */
  public async clear() {
    await RNZumoKit.clear();
  }
}

export default new ZumoKit();
