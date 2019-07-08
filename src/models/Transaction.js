import Moment from 'moment-timezone';

/**
 * Represents a transaction on the blockchain.
 *
 * @export
 * @class Transaction
 */
export default class Transaction {

    /**
     * The address that sent the transaction.
     *
     * @memberof Transaction
     */
    fromAddress;

    /**
     * The address that received the transaction.
     *
     * @memberof Transaction
     */
    toAddress;

    /**
     * The blockchain hash of the transaction.
     *
     * @memberof Transaction
     */
    hash;

    /**
     * The time that the transaction occured.
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
     * The status of the transaction.
     *
     * @memberof Transaction
     */
    status;

    /**
     * The value of the transaction in Wei.
     *
     * @memberof Transaction
     */
    weiValue;

    /**
     * The value of the transaction in Ether.
     *
     * @readonly
     * @memberof Transaction
     */
    value;

    /**
     * The price of the gas that was used by the transaction.
     *
     * @memberof Transaction
     */
    gasPrice;

    /**
     * The amount of gas that was used by the transaction.
     *
     * @memberof Transaction
     */
    gasUsed;

    /**
     * A note that was added to the transaction.
     * This is only used in internal transactions within the Zumo network.
     *
     * @memberof Transaction
     */
    note;

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

    constructor(json) {
        if(!json) throw 'JSON required to construct a Transaction.';

        if(json.from) this.fromAddress = json.from;
        if(json.to) this.toAddress = json.to;
        if(json.hash) this.hash = json.hash;
        if(json.timestamp) {
            this.timestamp = json.timestamp;
            this.time = new Moment(json.timestamp, 'X');
        }
        if(json.status) this.status = json.status;
        if(json.value) this.value = parseFloat(json.value);
        if(json.type) this.type = json.type;
        if(json.gas_price) this.gasPrice = parseFloat(json.gas_price);

    }

}