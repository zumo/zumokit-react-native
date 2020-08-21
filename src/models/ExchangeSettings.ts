import { Decimal } from 'decimal.js';
import { CurrencyCode, ExchangeSettingsJSON } from '../types';

/** Zumo exchange settings used in making exchanges. */
export default class ExchangeSettings {
  /** @internal */
  json: ExchangeSettingsJSON;

  /** Identifier. */
  id: string;

  /** Currency code of outgoing transaction. */
  fromCurrency: CurrencyCode;

  /** Currency code of incoming transaction. */
  toCurrency: CurrencyCode;

  /**
   * Zumo Exchange Service wallet address for each network type.
   *
   * See {@link Network}.
   */
  depositAddress: string;

  /** Minimum amount that can be exchanged in outgoing transaction currency. */
  minExchangeAmount: Decimal;

  /** Fee rate that will be used for outgoing transaction. */
  outgoingTransactionFeeRate: Decimal;

  /** Exchange fee rate that will be charged once currency is exchanged. */
  exchangeFeeRate: Decimal;

  /** Fee that will charged for return transaction. */
  incomingTransactionFee: Decimal;

  /** Epoch timestamp when the exchange settings were last updated. */
  timestamp: number;

  /** @internal */
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
