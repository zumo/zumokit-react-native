import { Decimal } from 'decimal.js';
import { TransactionCryptoPropertiesJSON, Dictionary, CurrencyCode } from '../types';

/** @internal */
const parseFiatMap = (fiatMapJSON: Record<string, string>) => {
  const fiatMap: Dictionary<CurrencyCode, Decimal> = {};
  Object.keys(fiatMapJSON).forEach((currencyCode) => {
    fiatMap[currencyCode as CurrencyCode] = new Decimal(fiatMapJSON[currencyCode]);
  });
  return fiatMap;
};

/**
 * Record containing transaction crypto properties.
 * <p>
 * See {@link Transaction}.
 * */
export default class TransactionCryptoProperties {
  /** @internal */
  json: TransactionCryptoPropertiesJSON;

  /** Transaction hash or null. */
  txHash: string | null;

  /**
   * Ethereum transaction nonce if greater than 0 and
   * it is Ethereum transaction, otherwise returns null.
   */
  nonce: string | null;

  /** Wallet address of sender, */
  fromAddress: string;

  /** Wallet address of receiver or null, if it is Ethereum contract deploy. */
  toAddress: string | null;

  /** Transaction data or null. */
  data: string | null;

  /** Ethereum gas price if it is Ethereum transaction, otherwise null. */
  gasPrice: Decimal | null;

  /** Ethereum gas limit if it is Ethereum transaction, otherwise null. */
  gasLimit: number | null;

  /** Amount in fiat currencies at the time of the transaction submission. */
  fiatFee: Dictionary<CurrencyCode, Decimal>;

  /** Fee in fiat currencies at the time of the transaction submission. */
  fiatAmount: Dictionary<CurrencyCode, Decimal>;

  /** @internal */
  constructor(json: TransactionCryptoPropertiesJSON) {
    this.json = json;
    this.txHash = json.txHash;
    this.nonce = json.nonce;
    this.fromAddress = json.fromAddress;
    this.toAddress = json.toAddress;
    this.data = json.data;
    this.gasPrice = json.gasPrice ? new Decimal(json.gasPrice) : null;
    this.gasLimit = json.gasLimit ? parseInt(json.gasLimit, 10) : null;
    this.fiatFee = parseFiatMap(json.fiatFee);
    this.fiatAmount = parseFiatMap(json.fiatAmount);
  }
}
