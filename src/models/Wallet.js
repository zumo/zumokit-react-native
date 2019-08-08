import { NativeModules } from 'react-native';
import Transaction from './Transaction';
const { RNZumoKit } = NativeModules;

/**
 * Represents a wallet on the blockchain/Zumo network.
 *
 * @export
 * @class Wallet
 */
export default class Wallet {
    
    /**
     * The unique ID of the wallet on Zumo.
     *
     * @memberof Wallet
     */
    id;

    /**
     * The address of the wallet on the blockchain.
     *
     * @memberof Wallet
     */
    address;

    /**
     * Whether the wallet is locked or unlocked.
     *
     * @memberof Wallet
     */
    unlocked;

    constructor(json) {
        if(!json) throw 'JSON required to construct a Wallet.';

        this.address = json.address;
        this.id = json.id;
        this.unlocked = json.unlocked;
    }

    /**
     * Unlocks the wallet to enable other methods.
     *
     * @memberof Wallet
     */
    async unlock(password) {
        const status = await RNZumoKit.unlockWallet(this.id, password);
        this.unlocked = status;

        if(!status) throw 'Wallet could not be unlocked. Password could be incorrect.';

        return status;
    }

    /**
     * Loads the balance for the wallet in ETH.
     *
     * @memberof Wallet
     */
    async getBalance() {
        if(!this.unlocked) throw 'Wallet not unlocked.';

        const balance = await RNZumoKit.getBalance(this.address);
        return parseFloat(balance);
    }

    // - TRANSACTIONS

    /**
     * Loads the transactions that are to/from the wallet.
     *
     * @returns
     * @memberof Wallet
     */
    async getTransactions() {
        const response = await RNZumoKit.getTransactions(this.id);
        return response.map((json) => new Transaction(json))
            .reverse();
    }

    /**
     * Sends a transaction of the given amount to the address provided.
     *
     * @param {string} address
     * @param {number} amount
     * @memberof Wallet
     */
    async sendTransaction(address, amount, gasPrice, gasLimit) {
        if(!this.unlocked) throw 'Wallet not unlocked.';
        
        const response = await RNZumoKit.sendTransaction(
            this.id, address,
            '' + amount,
            '' + gasPrice,
            '' + gasLimit
        );
        
        return new Transaction(response);
    }

}