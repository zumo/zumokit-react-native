import { Decimal } from 'decimal.js';
import ExchangeRate from './ExchangeRate';
import ExchangeSettings from './ExchangeSettings';
import { Dictionary, ExchangeStatus, CurrencyCode, ExchangeJSON } from '../types';
import { parseExchangeRates } from '../utils/parse';

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
  outgoingTransactionFee: Decimal | null;

  /** Currency to which exchange was made. */
  toCurrency: CurrencyCode;

  /** Target {@link  Account Account} identifier. */
  toAccountId: string;

  /** Return {@link  Transaction Transaction} identifier. */
  returnTransactionId: string | null;

  /** Return {@link  Transaction Transaction} fee. */
  returnTransactionFee: Decimal;

  /** Amount in source account currency. */
  amount: Decimal;

  /**
   * Amount that user receives in target account currency, calculated as <code>amount X exchangeRate X (1 - feeRate) - returnTransactionFee</code>.
   * <p>
   * See {@link ExchangeSettings}.
   */
  returnAmount: Decimal;

  /**
   * Exchange fee in target account currency, calculated as <code>amount X exchangeRate X exchangeFeeRate</code>.
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
    this.fromCurrency = json.fromCurrency as CurrencyCode;
    this.fromAccountId = json.fromAccountId;
    this.outgoingTransactionId = json.outgoingTransactionId;
    this.outgoingTransactionFee = json.outgoingTransactionFee
      ? new Decimal(json.outgoingTransactionFee)
      : null;
    this.toCurrency = json.toCurrency as CurrencyCode;
    this.toAccountId = json.toAccountId;
    this.returnTransactionId = json.returnTransactionId;
    this.returnTransactionFee = new Decimal(json.returnTransactionFee);
    this.amount = new Decimal(json.amount);
    this.returnAmount = new Decimal(json.returnAmount);
    this.exchangeFee = new Decimal(json.exchangeFee);
    this.exchangeRate = new ExchangeRate(json.exchangeRate);
    this.exchangeSettings = new ExchangeSettings(json.exchangeSettings);
    this.exchangeRates = parseExchangeRates(json.exchangeRates);
    this.nonce = json.nonce;
    this.submittedAt = json.submittedAt;
    this.confirmedAt = json.confirmedAt;
    this.timestamp = json.submittedAt;
  }
}
