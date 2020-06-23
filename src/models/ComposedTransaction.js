import Account from './Account';
import { Decimal } from 'decimal.js';

export default class ComposedTransaction {
    constructor(json) {
        this.json = json;
        this.signedTransaction = json.signedTransaction;
        this.account = new Account(json.account);
        this.destination = json.destination;
        this.amount = (json.amount) ? new Decimal(json.amount) : null;
        this.data = json.data;
        this.fee = new Decimal(json.fee);
    }
}
