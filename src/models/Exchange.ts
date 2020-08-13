import { Decimal } from 'decimal.js';
import ExchangeRate from './ExchangeRate';
import ExchangeSettings from './ExchangeSettings';
// eslint-disable-next-line import/no-cycle
import Parser from '../util/Parser';
import { Dictionary, ExchangeStatus, CurrencyCode, ExchangeJSON } from '../types';

/** Record containing exchange details. */
export default class Exchange {
  /** @internal */
  json: ExchangeJSON;

  /** Identifier */
  id: string;

  /** Exchange status. */
  status: ExchangeStatus;

  /** Currency from which exchange was made. */
  fromCurrency: CurrencyCode;

  /** Source {@link  Account Account} identifier. */
  fromAccountId: string;

  /** Outgoing {@link  Transaction Transaction} identifier. */
  outgoingTransactionId: string | null;

  /** Outgoing transaction fee. */
  outgoingTransactionFee: Decimal;

  /** Currency to which exchange was made. */
  toCurrency: CurrencyCode;

  /** Target {@link  Account Account} identifier. */
  toAccountId: string;

  /** Return {@link  Transaction Transaction} identifier. */
  incomingTransactionId: string | null;

  /** Return {@link  Transaction Transaction} fee. */
  incomingTransactionFee: Decimal;

  /** Amount in source account currency. */
  amount: Decimal;

  /**
   * Amount that user receives in target account currency, calculated as <code>amount X exchangeRate X (1 - feeRate) - withdrawFee</code>.
   * <p>
   * See {@link ExchangeSettings}.
   */
  returnAmount: Decimal;

  /**
   * Exchange fee in target account currency, calculated as <code>amount X exchangeRate X feeRate</code>.
   * <p>
   * See {@link ExchangeSettings}.
   */
  exchangeFee: Decimal;

  /** Exchange rate used. */
  exchangeRate: ExchangeRate;

  /** Exchange settings used. */
  exchangeSettings: ExchangeSettings;

  /**
   * Exchange rates at the time exchange was made.
   * This can be used to display amounts in local currency to the user.
   */
  exchangeRates: Dictionary<CurrencyCode, Dictionary<CurrencyCode, ExchangeRate>>;

  /** Exchange nonce or null. Used to prevent double spend. */
  nonce: string | null;

  /** Epoch timestamp when transaction was submitted. */
  submittedAt: number;

  /** Epoch timestamp when transaction was confirmed or null if not yet confirmed. */
  confirmedAt: number | null;

  /** Alias of {@link submittedAt} timestamp. Provided for convenience to match {@link Transaction} record structure. */
  timestamp: number;

  /** @internal */
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
