import Account from './Account';
import ExchangeRate from './ExchangeRate';
import ExchangeSettings from './ExchangeSettings';
import { Decimal } from 'decimal.js';

export default class ComposedExchange {

    constructor(json) {
        this.json = json;
        this.signedTransaction = json.signedTransaction;
        this.fromAccount = new Account(json.depositAccount);
        this.toAccount = new Account(json.withdrawAccount);
        this.exchangeRate = new ExchangeRate(json.exchangeRate);
        this.exchangeSettings = new ExchangeSettings(json.exchangeSettings);
        this.exchangeAddress = json.exchangeAddress;
        this.amount = new Decimal(json.value);
        this.outgoingTransactionFee = new Decimal(json.depositFee);
        this.returnAmount = new Decimal(json.returnValue);
        this.exchangeFee = new Decimal(json.exchangeFee);
        this.incomingTransactionFee = new Decimal(json.withdrawFee);
    }

}
