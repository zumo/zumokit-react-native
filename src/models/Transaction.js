import ZumoKit from '../ZumoKit';

export default class Transaction {

    /**
     * Unique identifier for the transaction
     *
     * @memberof Transaction
     */
    id;

    /**
     * Hash of the transaction on the blockchain
     *
     * @memberof Transaction
     */
    txHash;

    /**
     * The coin used to create the transaction
     *
     * @memberof Transaction
     */
    coin;

    /**
     * The symbol for the coin used to create the transaction
     *
     * @memberof Transaction
     */
    symbol;

    /**
     * 
     *
     * @memberof Transaction
     */
    timestamp;

    /**
     * The address that sent the transaction
     *
     * @memberof Transaction
     */
    fromAddress;

    /**
     * The address that received the transaction
     *
     * @memberof Transaction
     */
    toAddress;

    /**
     * The user ID that sent the transaction
     *
     * @memberof Transaction
     */
    fromUserId;

    /**
     * The user ID that received the transaction
     *
     * @memberof Transaction
     */
    toUserId;

    /**
     * The price of gas used to send the transaction
     *
     * @memberof Transaction
     */
    gasPrice;

    /**
     * The gas limit used to send the transaction
     *
     * @memberof Transaction
     */
    gasLimit;

    /**
     * The amount of gas used to send the transaction
     *
     * @memberof Transaction
     */
    gasUsed;

    /**
     * The value of the transaction
     *
     * @memberof Transaction
     */
    value;

    /**
     * The status of the transaction
     * 
     * - PENDING
     * - CONFIRMED
     * - FAILED
     *
     * @memberof Transaction
     */
    status;

    /**
     * Additional data that was sent with the transaction
     *
     * @memberof Transaction
     */
    payload;

    /**
     * The type of transaction. Either INCOMING or OUTGOING.
     *
     * @memberof Transaction
     */
    type;

    /**
     * The address to be displayed dependant on the type of transaction.
     *
     * @readonly
     * @memberof Transaction
     */
    get address() {
        return (this.type == 'INCOMING') ? this.fromAddress : this.toAddress;
    }

    /**
     * The user ID to be displayed dependant on the type of transaction.
     *
     * @readonly
     * @memberof Transaction
     */
    get userId() {
        return (this.type == 'INCOMING') ? this.fromUserId : this.toUserId;
    }

    constructor(json) {

        if(json.id) this.id = json.id;
        if(json.txHash) this.txHash = json.txHash;
        if(json.coin) this.coin = json.coin;
        if(json.timestamp) this.timestamp = json.timestamp;
        if(json.fromAddress) this.fromAddress = json.fromAddress;
        if(json.toAddress) this.toAddress = json.toAddress;
        if(json.fromUserId) this.fromUserId = json.fromUserId;
        if(json.toUserId) this.toUserId = json.toUserId;
        if(json.gasPrice) this.gasPrice = json.gasPrice;
        if(json.gasLimit) this.gasLimit = json.gasLimit;
        if(json.gasUsed) this.gasUsed = json.gasUsed;
        if(json.value) this.value = json.value;
        if(json.status) this.status = json.status;
        if(json.payload) this.payload = json.payload;
        
        // Check whether the transaction is incoming or outgoing
        const filtered = ZumoKit.state.accounts
            .filter((a) => a.address.toLowerCase() == json.fromAddress.toLowerCase());

        this.type = (filtered.length > 0) ? 'OUTGOING' : 'INCOMING';

    }

}