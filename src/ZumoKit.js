import Wallet from './models/Wallet';
import { NativeModules } from 'react-native';
const { RNZumoKit } = NativeModules;

/**
 * The core class of ZumoKit.
 *
 * @class ZumoKit
 */
class ZumoKit {

    /**
     * Initialise ZumoKit with the provided JSON config.
     *
     * @param {Object} config
     * @memberof ZumoKit
     */
    init(config) {
        const { apiKey, appId, apiRoot } = config;
        RNZumoKit.init(apiKey, appId, apiRoot);
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
        const response = await RNZumoKit.getWallet();
        return new Wallet(response);
    }

    /**
     * Authenticates the user with the API.
     * This will enable synchonised wallets and should be called first.
     *
     * @returns
     * @memberof ZumoKit
     */
    auth = RNZumoKit.auth;

}

export default new ZumoKit();