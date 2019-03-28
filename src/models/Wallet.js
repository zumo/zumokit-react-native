/**
 * Represents a wallet on the blockchain/Zumo network.
 *
 * @export
 * @class Wallet
 */
export default class Wallet {
    
    /**
     * The address of the wallet on the blockchain.
     *
     * @memberof Wallet
     */
    address;

    constructor(json) {
        if(!json) throw 'JSON required to construct a Wallet.';
    }

    /**
     * Loads the balance for the wallet in ETH.
     *
     * @memberof Wallet
     */
    async getBalance() {
        
    }

}