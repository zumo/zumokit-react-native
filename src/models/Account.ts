import { Decimal } from 'decimal.js';
import AccountCryptoProperties from './AccountCryptoProperties';
import AccountFiatProperties from './AccountFiatProperties';
import { CurrencyType, CurrencyCode, Network, AccountType, AccountJSON } from '../types';

export default class Account {
  json: AccountJSON;

  id: string;

  currencyType: CurrencyType;

  currencyCode: CurrencyCode;

  network: Network;

  type: AccountType;

  balance: Decimal;

  cryptoProperties: AccountCryptoProperties | null;

  fiatProperties: AccountFiatProperties | null;

  constructor(json: AccountJSON) {
    this.json = json;
    this.id = json.id;
    this.currencyType = json.currencyType as CurrencyType;
    this.currencyCode = json.currencyCode as CurrencyCode;
    this.network = json.network as Network;
    this.type = json.type as AccountType;
    this.balance = new Decimal(json.balance);
    this.cryptoProperties = json.cryptoProperties
      ? new AccountCryptoProperties(json.cryptoProperties)
      : null;
    this.fiatProperties = json.fiatProperties
      ? new AccountFiatProperties(json.fiatProperties)
      : null;
  }
}
