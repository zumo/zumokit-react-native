import { Decimal } from 'decimal.js';
import Account from './Account';
import ExchangeRate from './ExchangeRate';
import ExchangeSetting from './ExchangeSetting';
import { ComposedExchangeJSON } from '../types';

/** Result of the compose exchange method on {@link  Wallet Wallet} object. */
export default class ComposedExchange {
  /** @internal */
  json: ComposedExchangeJSON;

  /** Signed transaction for a crypto transaction, null otherwise. */
  signedTransaction: string | null;

  /** Source account. */
  fromAccount: Account;

  /** Target account. */
  toAccount: Account;

  /** Exchange rate used composing exchange. */
  exchangeRate: ExchangeRate;

  /** Exchange settings used composing exchange. */
  exchangeSetting: ExchangeSetting;

  /**
   * Zumo Exchange Service wallet address where outgoing crypto funds were deposited,
   * null for exchanges from fiat currencies.
   */
  exchangeAddress: string | null;

  /** Exchange amount in source account currency. */
  amount: Decimal;

  /** Outgoing transaction fee. */
  outgoingTransactionFee: Decimal;

  /**
   * Amount that user receives, calculated as <code>value X exchangeRate X (1 - feeRate) - returnTransactionFee</code>.
   * <p>
   * See {@link ExchangeSetting}.
   */
  returnAmount: Decimal;

  /**
   * Exchange fee, calculated as <code>value X exchangeRate X exchangeFeeRate</code>.
   * <p>
   * See {@link ExchangeSetting}.
   */
  exchangeFee: Decimal;

  /**
   * Return transaction fee.
   * <p>
   * See {@link ExchangeSetting}.
   */
  returnTransactionFee: Decimal;

  /** Unique nonce used to prevent double spend. */
  nonce: string;

  /** @internal */
  constructor(json: ComposedExchangeJSON) {
    this.json = json;
    this.signedTransaction = json.signedTransaction;
    this.fromAccount = new Account(json.fromAccount);
    this.toAccount = new Account(json.toAccount);
    this.exchangeRate = new ExchangeRate(json.exchangeRate);
    this.exchangeSetting = new ExchangeSetting(json.exchangeSetting);
    this.exchangeAddress = json.exchangeAddress;
    this.amount = new Decimal(json.amount);
    this.outgoingTransactionFee = new Decimal(json.outgoingTransactionFee);
    this.returnAmount = new Decimal(json.returnAmount);
    this.exchangeFee = new Decimal(json.exchangeFee);
    this.returnTransactionFee = new Decimal(json.returnTransactionFee);
    this.nonce = json.nonce;
  }
}
