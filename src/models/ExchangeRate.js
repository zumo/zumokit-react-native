import { Decimal } from 'decimal.js';

class ExchangeRate {

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
        this.depositCurrrency = json.depositCurrrency;
        this.withdrawCurrency = json.withdrawCurrency;
        this.balance = new Decimal(json.balance);
        this.validTo = json.validTo;
        this.timestamp = json.timestamp;
    }

}

export default (tryCatchProxy(ExchangeRate))