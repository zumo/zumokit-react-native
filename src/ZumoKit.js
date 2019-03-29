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
     * @param {Object} json
     * @memberof ZumoKit
     */
    init(json) {
        RNZumoKit.init();
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
    async getWallets() {
        const response = await RNZumoKit.getWallets();
        return response.map((keystore) => new Wallet(keystore));
    }

}

export default new ZumoKit();