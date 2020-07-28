import { Decimal } from 'decimal.js';
import Account from './Account';
import { TransactionType, ComposedTransactionJSON } from '../types';

export default class ComposedTransaction {
  json: ComposedTransactionJSON;

  type: TransactionType;

  signedTransaction: string | null;

  account: Account;

  destination: string | null;

  amount: Decimal | null;

  data: string | null;

  fee: Decimal;

  nonce: string;

  constructor(json: ComposedTransactionJSON) {
    this.json = json;
    this.type = json.type as TransactionType;
    this.signedTransaction = json.signedTransaction;
    this.account = new Account(json.account);
    this.destination = json.destination;
    this.amount = json.amount ? new Decimal(json.amount) : null;
    this.data = json.data;
    this.fee = new Decimal(json.fee);
    this.nonce = json.nonce;
  }
}
