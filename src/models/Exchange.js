import { Decimal } from 'decimal.js';
import ExchangeRate from './ExchangeRate';
import ExchangeSettings from './ExchangeSettings';
import { tryCatchProxy } from '../ZKErrorProxy';
import Parser from '../util/Parser';

class Exchange {

    constructor(json) {
        this.json = json;
        this.id = json.id;
        this.status = json.status;
        this.fromCurrency = json.depositCurrency;
        this.fromAccountId = json.depositAccountId;
        this.outgoingTransactionId = json.depositTransactionId;
        this.outgoingTransactionFee = json.depositFee ? new Decimal(json.depositFee) : null;
        this.toCurrency = json.withdrawCurrency;
        this.toAccountId = json.withdrawAccountId;
        this.incomingTransactionId = json.withdrawTransactionId;
        this.incomingTransactionFee = new Decimal(json.withdrawFee);
        this.amount = new Decimal(json.amount);
        this.returnAmount = new Decimal(json.returnAmount);
        this.exchangeFee = new Decimal(json.exchangeFee);
        this.exchangeRate = new ExchangeRate(json.exchangeRate);
        this.exchangeSettings = new ExchangeSettings(json.exchangeSettings);
        this.exchangeRates = Parser.parseExchangeRates(json.exchangeRates);
        this.submittedAt = json.submittedAt;
        this.confirmedAt = json.confirmedAt;
        this.timestamp = json.submittedAt;
    }

}

export default (tryCatchProxy(Exchange))