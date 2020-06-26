import { Decimal } from 'decimal.js';
import Account from './Account';
import ExchangeRate from './ExchangeRate';
import ExchangeSettings from './ExchangeSettings';
import { ComposedExchangeJSON } from '../types';

export default class ComposedExchange {
  json: ComposedExchangeJSON;

  signedTransaction: string | null;

  fromAccount: Account;

  toAccount: Account;

  exchangeRate: ExchangeRate;

  exchangeSettings: ExchangeSettings;

  exchangeAddress: string | null;

  amount: Decimal;

  outgoingTransactionFee: Decimal;

  returnAmount: Decimal;

  exchangeFee: Decimal;

  incomingTransactionFee: Decimal;

  nonce: string;

  constructor(json: ComposedExchangeJSON) {
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
    this.nonce = json.nonce;
  }
}
