import { Decimal } from 'decimal.js';
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
export default class Transaction {
  json: TransactionJSON;

  id: string;

  type: TransactionType;

  currencyCode: CurrencyCode;

  fromUserId: string | null;

  toUserId: string | null;

  fromAccountId: string | null;

  toAccountId: string | null;

  network: Network;

  status: TransactionStatus;

  amount: Decimal | null;

  fee: Decimal | null;

  nonce: string | null;

  cryptoProperties: TransactionCryptoProperties | null;

  fiatProperties: TransactionFiatProperties | null;

  submittedAt: number | null;

  confirmedAt: number | null;

  timestamp: number;

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
