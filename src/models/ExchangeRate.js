import { Decimal } from 'decimal.js';

export default class ExchangeRate {

    /**
     * ID of the exchange rate group
     *
     * @memberof ExchangeRate
     */
    id;

    /**
     * Deposit currency
     *
     * @memberof ExchangeRate
     */
    depositCurrrency;

    /**
     * Withdraw currency
     *
     * @memberof ExchangeRate
     */
    withdrawCurrency;

    /**
     * Exchange rate value
     *
     * @memberof ExchangeRate
     */
    value;

    /**
     * Rate valid to timestamp
     *
     * @memberof ExchangeRate
     */
    validTo;

    /**
     * Timestamp
     *
     * @memberof ExchangeRate
     */
    timestamp;

    /**
     * JSON representation of ExchangeRate object
     *
     * @memberof ExchangeRate
     */
    json;

    constructor(json) {
        this.json = json;
        this.id = json.id;
        this.depositCurrency = json.depositCurrency;
        this.withdrawCurrency = json.withdrawCurrency;
        this.value = json.value;
        this.validTo = json.validTo;
        this.timestamp = json.timestamp;
    }

}