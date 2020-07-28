import { Decimal } from 'decimal.js';
import { CurrencyCode, ExchangeSettingsJSON } from '../types';

export default class ExchangeSettings {
  json: ExchangeSettingsJSON;

  id: string;

  fromCurrency: CurrencyCode;

  toCurrency: CurrencyCode;

  depositAddress: string;

  minExchangeAmount: Decimal;

  outgoingTransactionFeeRate: Decimal;

  exchangeFeeRate: Decimal;

  incomingTransactionFee: Decimal;

  timestamp: number;

  constructor(json: ExchangeSettingsJSON) {
    this.json = json;
    this.id = json.id;
    this.fromCurrency = json.depositCurrency as CurrencyCode;
    this.toCurrency = json.withdrawCurrency as CurrencyCode;
    this.depositAddress = json.depositAddress;
    this.minExchangeAmount = new Decimal(json.minExchangeAmount);
    this.outgoingTransactionFeeRate = new Decimal(json.depositFeeRate);
    this.exchangeFeeRate = new Decimal(json.feeRate);
    this.incomingTransactionFee = new Decimal(json.withdrawFee);
    this.timestamp = json.timestamp;
  }
}
