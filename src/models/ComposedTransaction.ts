import { Decimal } from 'decimal.js';
import Account from './Account';
import { TransactionType, ComposedTransactionJSON } from '../types';

/**
 * Result of one of the transaction compose methods on {@link  Wallet Wallet} object.
 */
export default class ComposedTransaction {
  /** @internal */
  json: ComposedTransactionJSON;

  /**
   * Transaction type, 'FIAT', 'CRYPTO' or 'NOMINATED'.
   */
  type: TransactionType;

  /** Signed transaction for a crypto transaction, null otherwise. */
  signedTransaction: string | null;

  /** Account the composed transaction belongs to. */
  account: Account;

  /** Transaction destination, i.e. destination address for crypto transactions or user id for fiat transactions. */
  destination: string | null;

  /** Transaction amount in account currency. */
  amount: Decimal | null;

  /** Optional transaction data if available. */
  data: string | null;

  /** Maximum transaction fee. */
  fee: Decimal;

  /** Transaction nonce to prevent double spend. */
  nonce: string;

  /** @internal */
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
