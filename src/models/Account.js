import { Decimal } from 'decimal.js';

export default class Account {

    /**
     * Unique ID of the account
     *
     * @memberof Account
     */
    id;

    /**
     * Path to the account
     *
     * @memberof Account
     */
    path;

    /**
     * Coin symbol e.g. ETH, BTC
     *
     * @memberof Account
     */
    symbol;

    /**
     * Name of the coin e.g. Ethereum, Bitcoin
     *
     * @memberof Account
     */
    coin;

    /**
     * The blockchain address of the account
     *
     * @memberof Account
     */
    address;

    /**
     * The current balance of the account
     *
     * @memberof Account
     */
    balance;

    /**
     * The Chain ID to be used when sending transactions
     *
     * @memberof Account
     */
    chainId;

    /**
     * Number of transactions on the account to-date; used to sign outgoing transactions
     *
     * @memberof Account
     */
    nonce;

    constructor(json) {
        if(json.id) this.id = json.id;
        if(json.path) this.path = json.path;
        if(json.symbol) this.symbol = json.symbol;
        if(json.coin) this.coin = json.coin;
        if(json.address) this.address = json.address;
        if(json.balance) this.balance = new Decimal(json.balance);
        if(json.network) this.network = json.network;
        if(json.type) this.type = json.type;
        if(json.nonce) this.nonce = json.nonce;
    }

}