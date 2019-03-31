import ZumoKit from '../ZumoKit';

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
        const status = await ZumoKit.unlockWallet(this.id, password);
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
        
    }

    // - TRANSACTIONS

    async getTransactions() {
        
    }

    /**
     * Sends a transaction of the given amount to the address provided.
     *
     * @param {number} amount
     * @param {string} address
     * @memberof Wallet
     */
    async sendTransaction(amount, address) {
        if(!this.unlocked) throw 'Wallet not unlocked.';

    }

}