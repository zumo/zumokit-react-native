import { Decimal } from 'decimal.js';

export default class ExchangeFees {

    /**
     * ID of the exchange rate group
     *
     * @memberof ExchangeFees
     */
    id;

    /**
     * Deposit currency
     *
     * @memberof ExchangeFees
     */
    depositCurrrency;

    /**
     * Withdraw currency
     *
     * @memberof ExchangeFees
     */
    withdrawCurrency;

    /**
     * Fee rate that will be used to deposit funds from user to exchange
     *
     * @memberof ExchangeFees
     */
    depositFeeRate;

    /**
     * Exchange fee rate
     *
     * @memberof ExchangeFees
     */
    feeRate;

    /**
     * Fee of the return transaction from exchange to user
     *
     * @memberof ExchangeFees
     */
    withdrawFee;

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
        this.depositCurrency = json.depositCurrency;
        this.withdrawCurrency = json.withdrawCurrency;
        this.feeRate = new Decimal(json.feeRate);
        this.withdrawFee = new Decimal(json.feeRate);
        this.validTo = json.validTo;
        this.timestamp = json.timestamp;
    }

}