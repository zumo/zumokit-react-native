import { NativeModules } from 'react-native';
const { RNZumoKit } = NativeModules;
import Wallet from './Wallet';
import Account from './Account';
import Transaction from './Transaction';
import AccountFiatProperties from './AccountFiatProperties';
import { tryCatchProxy } from '../ZKErrorProxy';

class User {

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

    /**
     * Whether the user is a Modulr customer.
     *
     * @memberof User
     */
    isModulrCustomer;

    constructor(json) {
        if (json.id) this.id = json.id;
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
    async revealMnemonic(password) {
        return RNZumoKit.revealMnemonic(password);
    }

    /**
     * Validates the mnemonic phrase by the user's wallet
     *
     * @param {string} mnemonic
     * @returns
     * @memberof User
     */
    async isRecoveryMnemonic(mnemonic) {
        return RNZumoKit.isRecoveryMnemonic(mnemonic);
    }

    /**
     * Recovers a user's wallet.
     *
     * @param {string} mnemonic
     * @param {string} password
     * @returns
     * @memberof User
     */
    async recoverWallet(mnemonic, password) {
        return RNZumoKit.recoverWallet(mnemonic, password);
    }

    /**
     * User account selector
     *
     * @returns
     * @memberof User
     */
    async getAccount(symbol, network, type) {
        const json = await RNZumoKit.getAccount(symbol, network, type);
        return new Account(json);
    }

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

    /**
     * Loads an array of transactions the user has
     *
     * @returns
     * @memberof User
     */
    async getTransactions() {
        const array = await RNZumoKit.getTransactions();
        return array.map((json) => new Transaction(json));
    }

    /**
    * Loads an array of transactions for specific user account
    *
    * @param {string} accountId
    * @returns
    * @memberof User
    */
    async getAccountTransactions(accountId) {
        const array = await RNZumoKit.getAccountTransactions(accountId);
        return array.map((json) => new Transaction(json));
    }

    /**
     * Checks if user is a Modulr customer
     *
     * @param {string} network
     * @returns bool
     * @memberof User
     */
    async isModulrCustomer(network) {
        return RNZumoKit.isModulrCustomer(network);
    }

    /**
     * Make user Modulr customer
     *
     * @param {string} network
     * @param {object} customerData
     * @returns
     * @memberof User
     */
    async makeModulrCustomer(network, customerData) {
        return RNZumoKit.makeModulrCustomer(network, customerData);
    }

    /**
    * Create fiat account
    *
    * @param {string} network
    * @param {string} currencyCode
    * @returns Account
    * @memberof User
    */
    async createFiatAccount(network, currencyCode) {
        const json = await RNZumoKit.createFiatAccount(network, currencyCode);
        return new Account(json);
    }

    /**
    * Get nominated account fiat properties
    *
    * @param {string} accountId
    * @returns AccountFiatProperties | null
    * @memberof User
    */
    async getNominatedAccountFiatPoperties(accountId) {
        try {
            const json = await RNZumoKit.getNominatedAccountFiatPoperties(accountId);
            return new AccountFiatProperties(json);
        } catch (error) {
            return null;
        }
    }
}

export default (tryCatchProxy(User))