import { Decimal } from 'decimal.js';
import ExchangeRate from './ExchangeRate';
import ExchangeSettings from './ExchangeSettings';
// eslint-disable-next-line import/no-cycle
import Parser from '../util/Parser';
import { Dictionary, ExchangeStatus, CurrencyCode, ExchangeJSON } from '../types';

export default class Exchange {
  json: ExchangeJSON;

  id: string;

  status: ExchangeStatus;

  fromCurrency: CurrencyCode;

  fromAccountId: string;

  outgoingTransactionId: string | null;

  outgoingTransactionFee: Decimal;

  toCurrency: CurrencyCode;

  toAccountId: string;

  incomingTransactionId: string | null;

  incomingTransactionFee: Decimal;

  amount: Decimal;

  returnAmount: Decimal;

  exchangeFee: Decimal;

  exchangeRate: ExchangeRate;

  exchangeSettings: ExchangeSettings;

  exchangeRates: Dictionary<CurrencyCode, Dictionary<CurrencyCode, ExchangeRate>>;

  nonce: string | null;

  submittedAt: number;

  confirmedAt: number | null;

  timestamp: number;

  constructor(json: ExchangeJSON) {
    this.json = json;
    this.id = json.id;
    this.status = json.status as ExchangeStatus;
    this.fromCurrency = json.depositCurrency as CurrencyCode;
    this.fromAccountId = json.depositAccountId;
    this.outgoingTransactionId = json.depositTransactionId;
    this.outgoingTransactionFee = json.depositFee ? new Decimal(json.depositFee) : null;
    this.toCurrency = json.withdrawCurrency as CurrencyCode;
    this.toAccountId = json.withdrawAccountId;
    this.incomingTransactionId = json.withdrawTransactionId;
    this.incomingTransactionFee = new Decimal(json.withdrawFee);
    this.amount = new Decimal(json.amount);
    this.returnAmount = new Decimal(json.returnAmount);
    this.exchangeFee = new Decimal(json.exchangeFee);
    this.exchangeRate = new ExchangeRate(json.exchangeRate);
    this.exchangeSettings = new ExchangeSettings(json.exchangeSettings);
    this.exchangeRates = Parser.parseExchangeRates(json.exchangeRates);
    this.nonce = json.nonce;
    this.submittedAt = json.submittedAt;
    this.confirmedAt = json.confirmedAt;
    this.timestamp = json.submittedAt;
  }
}
