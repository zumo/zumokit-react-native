import { Decimal } from 'decimal.js';
// eslint-disable-next-line import/no-cycle
import TransactionCryptoProperties from './TransactionCryptoProperties';
import TransactionFiatProperties from './TransactionFiatProperties';
import {
  TransactionType,
  TransactionStatus,
  CurrencyCode,
  Network,
  TransactionJSON,
} from '../types';

// TODO: Add transaction subscription
/** Record containing transaction details. */
export default class Transaction {
  /** @internal */
  json: TransactionJSON;

  /** Identifier. */
  id: string;

  /** Transaction type. */
  type: TransactionType;

  /** Currency code. */
  currencyCode: CurrencyCode;

  /** Sender integrator user identifier or null if it is external user. */
  fromUserId: string | null;

  /** Recipient integrator user identifier or null if it is external user. */
  toUserId: string | null;

  /** Sender account identifier if it is internal transaction or null otherwise. */
  fromAccountId: string | null;

  /** Recipient account identifier if it is internal transaction or null otherwise. */
  toAccountId: string | null;

  /** Network type. */
  network: Network;

  /** Transaction status. */
  status: TransactionStatus;

  /** Amount in transaction currency or null if transaction is Ethereum contract deploy. */
  amount: Decimal | null;

  /** Transaction fee in transaction currency or null, if not yet available. */
  fee: Decimal | null;

  /** Transaction nonce or null. Used to prevent double spend. */
  nonce: string | null;

  /** Crypto properties if it is crypto transaction, null otherwise. */
  cryptoProperties: TransactionCryptoProperties | null;

  /** Fiat properties if it is crypto transaction, null otherwise. */
  fiatProperties: TransactionFiatProperties | null;

  /** Epoch timestamp when transaction was submitted or null for incoming transactions from outside of Zumo ecosystem. */
  submittedAt: number | null;

  /** Epoch timestamp when transaction was submitted or null if transaction was not confirmed yet. */
  confirmedAt: number | null;

  /** Epoch timestamp, minimum non-null value between submitted at and confirmed at timestamps. */
  timestamp: number;

  /** @internal */
  constructor(json: TransactionJSON) {
    this.json = json;
    this.id = json.id;
    this.type = json.type as TransactionType;
    this.currencyCode = json.currencyCode as CurrencyCode;
    this.fromUserId = json.fromUserId;
    this.toUserId = json.toUserId;
    this.fromAccountId = json.fromAccountId;
    this.toAccountId = json.toAccountId;
    this.network = json.network as Network;
    this.status = json.status as TransactionStatus;
    this.amount = json.amount ? new Decimal(json.amount) : null;
    this.fee = json.fee ? new Decimal(json.fee) : null;
    this.nonce = json.nonce;
    this.cryptoProperties = json.cryptoProperties
      ? new TransactionCryptoProperties(json.cryptoProperties)
      : null;
    this.fiatProperties = json.fiatProperties
      ? new TransactionFiatProperties(json.fiatProperties)
      : null;
    this.submittedAt = json.submittedAt;
    this.confirmedAt = json.confirmedAt;
    this.timestamp = json.timestamp;
  }
}
