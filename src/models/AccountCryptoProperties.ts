import { AccountCryptoPropertiesJSON } from '../types';

export default class CryptoProperties {
  json: AccountCryptoPropertiesJSON;

  address: string;

  path: string;

  nonce: number | null;

  constructor(json: AccountCryptoPropertiesJSON) {
    this.json = json;
    this.address = json.address;
    this.path = json.path;
    this.nonce = json.nonce;
  }
}
