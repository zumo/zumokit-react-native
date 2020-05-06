import { NativeModules, NativeEventEmitter } from 'react-native';
import User from './models/User';
import Transaction from './models/Transaction';
import { tryCatchProxy } from './ZKErrorProxy';

const { RNZumoKit } = NativeModules;

/**
 * The core class of ZumoKit.
 *
 * @class ZumoKit
 */
class ZumoKit {

    /**
     * The current state of ZumoKit.
     * Automatically updates when a change is made on the native side.
     *
     * @memberof ZumoKit
     */
    state = {
        authenticatedUser: null,
        accounts: [],
        transactions: [],
        feeRates: null
    };

    /**
     * The emitter that bubbles events from the native side.
     *
     * @memberof ZumoKit
     */
    _emitter = new NativeEventEmitter(RNZumoKit);

    /**
     * The listener that updates the internal ZumoKit state.
     *
     * @memberof ZumoKit
     */
    _stateListener;

    /**
     * Internal JS listeners for state changes.
     *
     * @memberof ZumoKit
     */
    _listeners = [];

    /**
     * The version of the native SDK.
     *
     * @memberof ZumoKit
     */
    version = RNZumoKit.version;

    /**
     * Initialise ZumoKit with the provided JSON config.
     *
     * @param {object} config
     * @memberof ZumoKit
     */
    init(config) {
        const { apiKey, apiRoot, txServiceUrl } = config;
        RNZumoKit.init(apiKey, apiRoot, txServiceUrl);

        this._stateListener = this._emitter.addListener('StateChanged', (state) => {

            console.log('ZumoKitStateChanged');
            console.log(state);

            if(state.accounts) this.state.accounts = state.accounts;
            if(state.transactions) this.state.transactions = state.transactions.map((json) => new Transaction(json));
            if(state.exchangeRates) this.state.exchangeRates = state.exchangeRates;
            if(state.feeRates) this.state.feeRates = state.feeRates;

            this._notifyStateListeners();

        });
    }

    /**
     * Authenticates the user with ZumoKit.
     *
     * @param {string} token
     * @returns
     * @memberof ZumoKit
     */
    async getUser(token) {
        const json = await RNZumoKit.getUser(token);
        const user = new User(json);

        this.state.authenticatedUser = user;

        this._notifyStateListeners();

        return user;
    }

    /**
     * Get historical exchange rates
     *
     * @returns ¯\_(ツ)_/¯
     * @memberof ZumoKit
     */
    async getHistoricalExchangeRates() {
        return RNZumoKit.getHistoricalExchangeRates();
    }

    /**
     * Adds a new listener for state updates.
     *
     * @param {function} callback
     * @returns
     * @memberof ZumoKit
     */
    addStateListener(callback) {
        if(this._listeners.includes(callback)) return;
        this._listeners.push(callback);
        callback(this.state);
    }

    /**
     * Removes a state listener.
     *
     * @param {function} callback
     * @returns
     * @memberof ZumoKit
     */
    removeStateListener(callback) {
        if(!this._listeners.includes(callback)) return;
        const index = this._listeners.indexOf(callback);
        this._listeners.splice(index, 1);
    }

    /**
     * Notify all the listeners that the state has changed.
     *
     * @memberof ZumoKit
     */
    _notifyStateListeners() {
        for (const listener of this._listeners) {
            listener(this.state);
        }
    }

    /**
     * Clears the wallet and user.
     *
     * @memberof ZumoKit
     */
    async clear() {
        await RNZumoKit.clear();
    }

}

export default new (tryCatchProxy(ZumoKit))