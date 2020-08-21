import { Decimal } from 'decimal.js';
import Account from './Account';
import ExchangeRate from './ExchangeRate';
import ExchangeSettings from './ExchangeSettings';
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
  exchangeSettings: ExchangeSettings;

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
   * Amount that user receives, calculated as <code>value X exchangeRate X (1 - feeRate) - withdrawFee</code>.
   * <p>
   * See {@link ExchangeSettings}.
   */
  returnAmount: Decimal;

  /**
   * Exchange fee, calculated as <code>value X exchangeRate X feeRate</code>.
   * <p>
   * See {@link ExchangeSettings}.
   */
  exchangeFee: Decimal;

  /**
   * Return transaction fee.
   * <p>
   * See {@link ExchangeSettings}.
   */
  incomingTransactionFee: Decimal;

  /** Unique nonce used to prevent double spend. */
  nonce: string;

  /** @internal */
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
