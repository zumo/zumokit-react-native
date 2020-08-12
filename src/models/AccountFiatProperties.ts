import { AccountFiatPropertiesJSON } from '../types';

/**
 * {@link Account}'s fiat related properties.
 */
export default class AccountFiatProperties {
  /** @internal */
  json: AccountFiatPropertiesJSON;

  /** Fiat account number or null. */
  accountNumber: string | null;

  /** Fiat account sort code or null. */
  sortCode: string | null;

  /** Fiat account BIC or null. */
  bic: string | null;

  /** Fiat account IBAN or null. */
  iban: string | null;

  /** Customer name or null. */
  customerName: string | null;

  /** @internal */
  constructor(json: AccountFiatPropertiesJSON) {
    this.json = json;
    this.accountNumber = json.accountNumber;
    this.sortCode = json.sortCode;
    this.bic = json.bic;
    this.iban = json.iban;
    this.customerName = json.customerName;
  }
}
