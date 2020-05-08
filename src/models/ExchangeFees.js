import { Decimal } from 'decimal.js';

export default class ExchangeFees {

    /**
     * ID of the exchange rate group
     *
     * @memberof ExchangeFees
     */
    id;

    /**
     * From currency
     *
     * @memberof ExchangeFees
     */
    fromCurrency;

    /**
     * To currency
     *
     * @memberof ExchangeFees
     */
    toCurrency;

    /**
     * Fee rate that will be used to deposit funds from user to exchange
     *
     * @memberof ExchangeFees
     */
    outgoingTransactionFeeRate;

    /**
     * Exchange fee rate
     *
     * @memberof ExchangeFees
     */
    exchangeFeeRate;

    /**
     * Fee of the return transaction from exchange to user
     *
     * @memberof ExchangeFees
     */
    incomingTransactionFee;

    /**
     * Timestamp
     *
     * @memberof ExchangeFees
     */
    timestamp;

    /**
     * JSON representation of ExchangeFees object
     *
     * @memberof ExchangeFees
     */
    json;

    constructor(json) {
        this.json = json;
        this.id = json.id;
        this.fromCurrency = json.depositCurrency;
        this.toCurrency = json.withdrawCurrency;
        this.outgoingTransactionFeeRate = new Decimal(json.depositFeeRate);
        this.exchangefeeRate = new Decimal(json.feeRate);
        this.incomingTransactionFee = new Decimal(json.withdrawFee);
        this.validTo = json.validTo;
        this.timestamp = json.timestamp;
    }

}