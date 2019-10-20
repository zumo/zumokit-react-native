import { NativeModules, NativeEventEmitter } from 'react-native';
import User from './models/User';

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
        transactions: []
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
     * Initialise ZumoKit with the provided JSON config.
     *
     * @param {object} config
     * @memberof ZumoKit
     */
    init(config) {
        const { apiKey, apiRoot, myRoot, txServiceUrl } = config;
        RNZumoKit.init(apiKey, apiRoot, myRoot, txServiceUrl);

        this._stateListener = this._emitter.addListener('StateChanged', (state) => {
            this.state = {
                authenticatedUser: this.state.authenticatedUser,
                accounts: state.accounts,
                transactions: state.transactions
            };
        });
    }

    /**
     * Authenticates the user with ZumoKit.
     *
     * @param {string} token
     * @param {object} headers
     * @returns
     * @memberof ZumoKit
     */
    async auth(token, headers) {
        const json = await RNZumoKit.auth(token, headers);
        const user = new User(json);

        this.state.authenticatedUser = user;

        this._notifyStateListeners();

        return user;
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

}

export default new ZumoKit();