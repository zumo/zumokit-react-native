import AccountFiatProperties from './AccountFiatProperties';
import { TransactionFiatPropertiesJSON } from '../types';

export default class TransactionFiatProperties {
  json: TransactionFiatPropertiesJSON;

  fromFiatAccount: AccountFiatProperties;

  toFiatAccount: AccountFiatProperties;

  constructor(json: TransactionFiatPropertiesJSON) {
    this.json = json;
    this.fromFiatAccount = new AccountFiatProperties(json.fromFiatAccount);
    this.toFiatAccount = new AccountFiatProperties(json.toFiatAccount);
  }
}
