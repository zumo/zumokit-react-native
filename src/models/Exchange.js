import { Decimal } from 'decimal.js';
import ExchangeRate from './ExchangeRate';
import ExchangeFees from './ExchangeFees';
import { tryCatchProxy } from '../ZKErrorProxy';

class Exchange {

    constructor(json) {
        this.json = json;
        this.id = json.id;
        this.status = json.status;
        this.depositCurrency = json.depositCurrency;
        this.depositAccountId = json.depositAccountId;
        this.depositTransactionId = json.depositTransactionId;
        this.withdrawCurrency = json.withdrawCurrency;
        this.withdrawAccountId = json.withdrawAccountId;
        this.withdrawTransactionId = json.withdrawTransactionId;
        this.amount = new Decimal(json.amount);
        this.depositFee = json.depositFee ? new Decimal(json.depositFee) : null;
        this.returnAmount = new Decimal(json.returnAmount);
        this.exchangeFee = new Decimal(json.exchangeFee);
        this.withdrawFee = new Decimal(json.withdrawFee);
        this.exchangeRate = new ExchangeRate(json.exchangeRate);
        this.exchangeFees = new ExchangeFees(json.exchangeFees);
        this.submittedAt = json.submittedAt;
        this.confirmedAt = json.confirmedAt;
    }

}

export default (tryCatchProxy(Exchange))