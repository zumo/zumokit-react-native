import Wallet from './models/Wallet';
import { NativeModules, NativeEventEmitter } from 'react-native';
const { RNZumoKit } = NativeModules;

/**
 * The core class of ZumoKit.
 *
 * @class ZumoKit
 */
class ZumoKit {

    /**
     * Private cached wallet.
     *
     * @memberof ZumoKit
     */
    _cachedWallet;

    /**
     * The emitter that bubbles events from the native side.
     *
     * @memberof ZumoKit
     */
    _emitter = new NativeEventEmitter(RNZumoKit);

    /**
     * Initialise ZumoKit with the provided JSON config.
     *
     * @param {Object} config
     * @memberof ZumoKit
     */
    init(config) {
        const { apiKey, appId, apiRoot, myRoot, txServiceUrl } = config;
        RNZumoKit.init(apiKey, appId, apiRoot, myRoot, txServiceUrl);
    }

    /**
     * Clears the ZumoKit cache.
     * This should be called when a user logs out.
     *
     * @memberof ZumoKit
     */
    clear() {
        this._cachedWallet = undefined;
    }

    /**
     * Creates a new ETH wallet.
     *
     * @param {string} password
     * @param {number} nmemonicCount
     * @returns
     * @memberof ZumoKit
     */
    async createWallet(password, nmemonicCount) {
        const { mnemonic, keystore } = await RNZumoKit.createWallet(password, nmemonicCount);

        return {
            mnemonic,
            wallet: new Wallet(keystore)
        };
    }

    /**
     * Loads any wallets saved within the keystore.
     *
     * @returns
     * @memberof ZumoKit
     */
    async getWallet() {
        return new Promise((resolve, reject) => {

            if(this._cachedWallet) {
                resolve(this._cachedWallet);
                return;
            }

            let retries = 0;

            const interval = setInterval(async () => {
                if(retries >= 10) {
                    clearInterval(interval);
                    reject(new Error('No wallet found'));
                    return
                }

                try {
                    const json = await RNZumoKit.getWallet();
                    const wallet = new Wallet(json);
                    this._cachedWallet = wallet;

                    clearInterval(interval);
                    resolve(wallet);
                } catch(error) {
                    retries++;
                }
            }, 1000);

        });
    }

    /**
     * Authenticates the user with the API.
     * This will enable synchonised wallets and should be called first.
     *
     * @returns
     * @memberof ZumoKit
     */
    auth = RNZumoKit.auth;

    /**
     * Add a listener for native events.
     *
     * @param {function} callback
     * @returns
     * @memberof ZumoKit
     */
    addListener(callback) {
        return this._emitter.addListener('StoreUpdated', callback);
    }

}

export default new ZumoKit();