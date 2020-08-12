import { Decimal } from 'decimal.js';
import AccountCryptoProperties from './AccountCryptoProperties';
import AccountFiatProperties from './AccountFiatProperties';
import { CurrencyType, CurrencyCode, Network, AccountType, AccountJSON } from '../types';

/** Record containing account details. */
export default class Account {
  /** @internal */
  json: AccountJSON;

  /** Unique account identifier. */
  id: string;

  /** Account currency type. */
  currencyType: CurrencyType;

  /** Account currency code. */
  currencyCode: CurrencyCode;

  /** Account network type. */
  network: Network;

  /** Account type. */
  type: AccountType;

  /** Account balance. */
  balance: Decimal;

  /** Account has associated nominated account. */
  hasNominatedAccount: boolean;

  /** Account crypto properties if account is a crypto account, otherwise null. */
  cryptoProperties: AccountCryptoProperties | null;

  /** Account fiat properties if account is a fiat account, otherwise null. */
  fiatProperties: AccountFiatProperties | null;

  /** @internal */
  constructor(json: AccountJSON) {
    this.json = json;
    this.id = json.id;
    this.currencyType = json.currencyType as CurrencyType;
    this.currencyCode = json.currencyCode as CurrencyCode;
    this.network = json.network as Network;
    this.type = json.type as AccountType;
    this.balance = new Decimal(json.balance);
    this.hasNominatedAccount = !!json.hasNominatedAccount;
    this.cryptoProperties = json.cryptoProperties
      ? new AccountCryptoProperties(json.cryptoProperties)
      : null;
    this.fiatProperties = json.fiatProperties
      ? new AccountFiatProperties(json.fiatProperties)
      : null;
  }
}
