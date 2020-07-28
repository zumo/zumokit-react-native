import { Decimal } from 'decimal.js';
import { TransactionCryptoPropertiesJSON, Dictionary, CurrencyCode } from '../types';
// eslint-disable-next-line import/no-cycle
import Parser from '../util/Parser';

export default class TransactionCryptoProperties {
  json: TransactionCryptoPropertiesJSON;

  txHash: string | null;

  nonce: string | null;

  fromAddress: string;

  toAddress: string | null;

  data: string | null;

  gasPrice: Decimal | null;

  gasLimit: number | null;

  fiatFee: Dictionary<CurrencyCode, Decimal>;

  fiatAmount: Dictionary<CurrencyCode, Decimal>;

  constructor(json: TransactionCryptoPropertiesJSON) {
    this.json = json;
    this.txHash = json.txHash;
    this.nonce = json.nonce;
    this.fromAddress = json.fromAddress;
    this.toAddress = json.toAddress;
    this.data = json.data;
    this.gasPrice = json.gasPrice ? new Decimal(json.gasPrice) : null;
    this.gasLimit = json.gasLimit ? parseInt(json.gasLimit, 10) : null;
    this.fiatFee = Parser.parseFiatMap(json.fiatFee);
    this.fiatAmount = Parser.parseFiatMap(json.fiatAmount);
  }
}
