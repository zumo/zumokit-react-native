import { NativeModules } from 'react-native';
const { RNZumoKit } = NativeModules;
import Wallet from './Wallet';
import Account from './Account';

export default class User {

    /**
     * The unique ID of the user.
     *
     * @memberof User
     */
    id;

    /**
     * Whether the user currently has a wallet.
     *
     * @memberof User
     */
    hasWallet;
    
    constructor(json) {
        if(json.id) this.id = json.id;
        this.hasWallet = (json.hasWallet) ? true : false;
    }

    /**
     * Creates and returns new wallet for the user.
     *
     * @param {string} mnemonic
     * @param {string} password
     * @returns
     * @memberof User
     */
    async createWallet(mnemonic, password) {
        await RNZumoKit.createWallet(mnemonic, password);
        this.hasWallet = true;
        return new Wallet();
    }

    /**
     * Unlocks and returns wallet for the user.
     *
     * @param {string} password
     * @returns
     * @memberof User
     */
    async unlockWallet(password) {
        await RNZumoKit.unlockWallet(password);
        return new Wallet();
    }

    /**
     * Reveals the mnemonic used to create the wallet
     *
     * @param {string} password
     * @returns
     * @memberof User
     */
    revealMnemonic = RNZumoKit.revealMnemonic;

    /**
     * Loads an array of accounts the user has
     *
     * @returns
     * @memberof User
     */
    async getAccounts() {
        const array = await RNZumoKit.getAccounts();
        return array.map((json) => new Account(json));
    }

}