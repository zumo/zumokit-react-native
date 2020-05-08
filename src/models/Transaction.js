import { NativeModules, NativeEventEmitter } from 'react-native';
import Moment from 'moment-timezone';
import { Decimal } from 'decimal.js';
const { RNZumoKit } = NativeModules;
import { tryCatchProxy } from '../ZKErrorProxy';

class Transaction {

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
     * A `Moment` instance of the time that the transaction was created.
     * Use `.tz()` to localise it to a timezone.
     *
     * @readonly
     * @memberof Transaction
     */
    time;

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
     * The cost of the transaction
     *
     * @memberof Transaction
     */
    cost;

    /**
     * The cost of the tranaction in fiat
     *
     * @memberof Transaction
     */
    fiatValue;

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
     * The type of transaction. Either NORMAL or Exchange.
     *
     * @memberof Transaction
     */
    type;

     /**
     * The direction of transaction. Either INCOMING or OUTGOING.
     *
     * @memberof Transaction
     */
    direction;

    /**
     * The address to be displayed dependant on the type of transaction.
     *
     * @readonly
     * @memberof Transaction
     */
    get address() {
        return (this.direction == 'INCOMING') ? this.fromAddress : this.toAddress;
    }

    /**
     * The user ID to be displayed dependant on the type of transaction.
     *
     * @readonly
     * @memberof Transaction
     */
    get userId() {
        return (this.direction == 'INCOMING') ? this.fromUserId : this.toUserId;
    }

    /**
     * The emitter that bubbles events from the native side.
     *
     * @memberof ZumoKit
     */
    _emitter = new NativeEventEmitter(RNZumoKit);

    /**
     * Transaction listener to notify when an event occurs.
     *
     * @memberof Transaction
     */
    _transactionListener;

    /**
     * JSON representation of Account object
     *
     * @memberof Account
     */
    json;

    constructor(json) {
        this.json = json;
        if(json.id) this.id = json.id;
        if(json.type) this.type = json.type;
        if(json.direction) this.direction = json.direction;
        if(json.txHash) this.txHash = json.txHash;
        if(json.accountId) this.accountId = json.accountId;
        if(json.symbol) this.symbol = json.symbol;
        if(json.coin) this.coin = json.coin;
        if(json.network) this.network = json.network;
        if(json.nonce) this.nonce = json.nonce;
        if(json.status) this.status = json.status;
        if(json.fromAddress) this.fromAddress = json.fromAddress;
        if(json.toAddress) this.toAddress = json.toAddress;
        if(json.fromUserId) this.fromUserId = json.fromUserId;
        if(json.toUserId) this.toUserId = json.toUserId;
        this.value = (json.value) ? new Decimal(json.value) : new Decimal(0);
        if(json.fiatValue) this.fiatValue = json.fiatValue;
        if(json.data) this.data = json.data;
        this.gasPrice = (json.gasPrice) ? new Decimal(json.gasPrice) : new Decimal(0);
        if(json.gasLimit) this.gasLimit = json.gasLimit;
        if(json.fee) this.fee = json.fee;
        if(json.fiatFee) this.fiatFee = json.fiatFee;

        if(json.timestamp) {
            this.timestamp = json.timestamp
            this.time = new Moment(json.timestamp, 'X');;
        }

        if(json.submittedAt) {
            this.submittedAt = new Moment(json.submittedAt, 'X');;
        }

        if(json.confirmedAt) {
            this.confirmedAt = new Moment(json.confirmedAt, 'X');;
        }

    }

    async addListener(callback) {

        await RNZumoKit.addTransactionListener(this.id);

        this._transactionListener = this._emitter.addListener('TransactionChanged', (transaction) => {
            if(transaction.status) this.status = transaction.status;
            callback(this);
        });

    }

    async removeListener() {

        if(!this._transactionListener) return;

        this._transactionListener.removeListener();
        this._transactionListener = null;

        await RNZumoKit.removeTransactionListener();

    }

}

export default (tryCatchProxy(Transaction))