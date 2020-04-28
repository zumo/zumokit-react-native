import Account from './Account';
import { Decimal } from 'decimal.js';
import { tryCatchProxy } from '../ZKErrorProxy';

class ComposedTransaction {

    /**
     * Signed transaction
     *
     * @memberof ComposedTransaction
     */
    signedTransaction;

    /**
     * Sending account
     *
     * @memberof ComposedTransaction
     */
    account;

    /**
     * Destination address
     *
     * @memberof ComposedTransaction
     */
    destination;

    /**
     * Transaction value in Decimal format
     *
     * @memberof ComposedTransaction
     */
    value;

    /**
     * Transacation data
     *
     * @memberof ComposedTransaction
     */
    data;

    /**
     * Transaction fee in Decimal format
     *
     * @readonly
     * @memberof ComposedTransaction
     */
    fee;

    /**
     * JSON representation of ComposedTransaction
     *
     * @memberof ComposedTransaction
     */
    json;


    constructor(json) {
        this.json = json;
        this.signedTransaction = json.signedTransaction;
        this.account = new Account(json.account);
        this.destination = json.destination;
        this.value = (json.value) ? new Decimal(json.value) : new Decimal(0);
        this.data = json.data;
        this.fee = new Decimal(json.fee);
    }

}

export default (tryCatchProxy(ComposedTransaction))