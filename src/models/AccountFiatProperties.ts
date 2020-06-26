import { AccountFiatPropertiesJSON } from '../types';

export default class FiatProperties {
  json: AccountFiatPropertiesJSON;

  accountNumber: string | null;

  sortCode: string | null;

  bic: string | null;

  iban: string | null;

  customerName: string | null;

  constructor(json: AccountFiatPropertiesJSON) {
    this.json = json;
    this.accountNumber = json.accountNumber;
    this.sortCode = json.sortCode;
    this.bic = json.bic;
    this.iban = json.iban;
    this.customerName = json.customerName;
  }
}
