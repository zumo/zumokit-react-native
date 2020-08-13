import AccountFiatProperties from './AccountFiatProperties';
import { TransactionFiatPropertiesJSON } from '../types';

/**
 * Record containing transaction fiat properties.
 * <p>
 * See {@link Transaction}.
 * */
export default class TransactionFiatProperties {
  /** @internal */
  json: TransactionFiatPropertiesJSON;

  /** Sender fiat account properties. */
  fromFiatAccount: AccountFiatProperties;

  /** Recipient fiat account properties. */
  toFiatAccount: AccountFiatProperties;

  /** @internal */
  constructor(json: TransactionFiatPropertiesJSON) {
    this.json = json;
    this.fromFiatAccount = new AccountFiatProperties(json.fromFiatAccount);
    this.toFiatAccount = new AccountFiatProperties(json.toFiatAccount);
  }
}
