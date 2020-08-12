import { AccountCryptoPropertiesJSON } from '../types';

/**
 * {@link Account}'s crypto related properties.
 */
export default class AccountCryptoProperties {
  /** @internal */
  json: AccountCryptoPropertiesJSON;

  /** Account crypto address. */
  address: string;

  /** Hierarchical Deterministic (HD) account derivation path. */
  path: string;

  /** Ethereum account nonce if greater than 0 or null otherwise. */
  nonce: number | null;

  /** @internal */
  constructor(json: AccountCryptoPropertiesJSON) {
    this.json = json;
    this.address = json.address;
    this.path = json.path;
    this.nonce = json.nonce;
  }
}
