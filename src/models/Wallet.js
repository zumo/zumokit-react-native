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

    constructor(json) {
        if(!json) throw 'JSON required to construct a Wallet.';

        this.address = json.address;
        this.id = json.id;
    }

    /**
     * Loads the balance for the wallet in ETH.
     *
     * @memberof Wallet
     */
    async getBalance() {
        
    }

    /**
     * Creates a transaction to the provided address.
     *
     * @param {*} amount
     * @param {*} address
     * @memberof Wallet
     */
    async createTransaction(amount, address) {

    }

    async sendTransaction(transaction) {
        
    }

}