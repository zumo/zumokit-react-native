import { Decimal } from 'decimal.js';
import { CurrencyCode, ExchangeRateJSON } from '../types';

export default class ExchangeRate {
  json: ExchangeRateJSON;

  id: string;

  fromCurrency: CurrencyCode;

  toCurrency: CurrencyCode;

  value: Decimal;

  validTo: number;

  timestamp: number;

  constructor(json: ExchangeRateJSON) {
    this.json = json;
    this.id = json.id;
    this.fromCurrency = json.depositCurrency as CurrencyCode;
    this.toCurrency = json.withdrawCurrency as CurrencyCode;
    this.value = new Decimal(json.value);
    this.validTo = json.validTo;
    this.timestamp = json.timestamp;
  }
}
