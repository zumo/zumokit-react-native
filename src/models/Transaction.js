import ZKUtility from "../ZKUtility";

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
    get value() {
        return ZKUtility.toEther(this.weiValue);
    }

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

    constructor(json) {
        if(!json) return;


    }

}