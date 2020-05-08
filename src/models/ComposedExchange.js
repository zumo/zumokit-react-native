import Account from './Account';
import ExchangeRate from './ExchangeRate';
import ExchangeFees from './ExchangeFees';
import { Decimal } from 'decimal.js';

export default class ComposedExchange {

    constructor(json) {
        this.json = json;
        this.signedTransaction = json.signedTransaction;
        this.depositAccount = new Account(json.depositAccount);
        this.withdrawAccount = new Account(json.withdrawAccount);
        this.exchangeRate = new ExchangeRate(json.exchangeRate);
        this.exchangeFees = new ExchangeFees(json.exchangeFees);
        this.exchangeAddress = json.exchangeAddress;
        this.value = new Decimal(json.value);
        this.returnValue = new Decimal(json.returnValue);
        this.depositFee = new Decimal(json.depositFee);
        this.exchangeFee = new Decimal(json.exchangeFee);
        this.withdrawFee = new Decimal(json.withdrawFee);
    }

}
