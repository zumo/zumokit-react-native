import { NativeModules, NativeEventEmitter } from 'react-native';
import User from './models/User';
import Account from './models/Account';
import Parser from './util/Parser';
import tryCatchProxy from './ZKErrorProxy';
import Transaction from './models/Transaction';
import Exchange from './models/Exchange';
import { Dictionary, CurrencyCode, ZumoKitConfig, TokenSet, StateJSON } from './types';
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

@tryCatchProxy
class ZumoKit {
  // The current state of ZumoKit.
  // Automatically updates when a change is made on the native side.
  state: State = {
    authenticatedUser: null,
    accounts: [],
    transactions: [],
    exchanges: [],
    feeRates: null,
    exchangeRates: null,
    exchangeSettings: null,
  };

  // The emitter that bubbles events from the native side.
  private emitter = new NativeEventEmitter(RNZumoKit);

  // Internal JS listeners for state changes.
  private listeners: Array<(state: State) => void> = [];

  // The version of the native SDK.
  version: string = RNZumoKit.version;

  init(config: ZumoKitConfig) {
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

  async getUser(tokenSet: TokenSet) {
    const json = await RNZumoKit.getUser(JSON.stringify(tokenSet));
    const user = new User(json);

    this.state.authenticatedUser = user;

    this.notifyStateListeners();

    return user;
  }

  async getHistoricalExchangeRates() {
    return RNZumoKit.getHistoricalExchangeRates();
  }

  addStateListener(callback: (state: State) => void) {
    if (this.listeners.includes(callback)) return;
    this.listeners.push(callback);
    callback(this.state);
  }

  removeStateListener(callback: (state: State) => void) {
    if (!this.listeners.includes(callback)) return;
    const index = this.listeners.indexOf(callback);
    this.listeners.splice(index, 1);
  }

  private notifyStateListeners() {
    this.listeners.forEach((listener: (state: State) => void) => listener(this.state));
  }

  async clear() {
    await RNZumoKit.clear();
  }
}

export default new ZumoKit();
