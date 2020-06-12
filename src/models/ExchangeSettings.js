import { Decimal } from 'decimal.js';

export default class ExchangeSettings {

    /**
     * ID of the exchange rate group
     *
     * @memberof ExchangeSettings
     */
    id;

    /**
     * From currency
     *
     * @memberof ExchangeSettings
     */
    fromCurrency;

    /**
     * To currency
     *
     * @memberof ExchangeSettings
     */
    toCurrency;

    /**
     * Deposit address
     *
     * @memberof ExchangeSettings
     */
    depositAddress;

    /**
     * Minimum exchange amount
     *
     * @memberof ExchangeSettings
     */
    minExchangeAmount

    /**
     * Fee rate that will be used to deposit funds from user to exchange
     *
     * @memberof ExchangeSettings
     */
    outgoingTransactionFeeRate;

    /**
     * Exchange fee rate
     *
     * @memberof ExchangeSettings
     */
    exchangeFeeRate;

    /**
     * Fee of the return transaction from exchange to user
     *
     * @memberof ExchangeSettings
     */
    incomingTransactionFee;

    /**
     * Timestamp
     *
     * @memberof ExchangeSettings
     */
    timestamp;

    /**
     * JSON representation of ExchangeSettings object
     *
     * @memberof ExchangeSettings
     */
    json;

    constructor(json) {
        this.json = json;
        this.id = json.id;
        this.fromCurrency = json.depositCurrency;
        this.toCurrency = json.withdrawCurrency;
        this.depositAddress = json.depositAddress;
        this.minExchangeAmount = new Decimal(json.minExchangeAmount);
        this.outgoingTransactionFeeRate = new Decimal(json.depositFeeRate);
        this.exchangeFeeRate = new Decimal(json.feeRate);
        this.incomingTransactionFee = new Decimal(json.withdrawFee);
        this.timestamp = json.timestamp;
    }

}