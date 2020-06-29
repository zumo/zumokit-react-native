import { Decimal } from 'decimal.js';
import AccountCryptoProperties from './AccountCryptoProperties';
import AccountFiatProperties from './AccountFiatProperties';

export default class Account {
    constructor(json) {
        this.json = json;
        this.id = json.id;
        this.currencyCode = json.currencyCode;
        this.currencyType = json.currencyType;
        this.network = json.network;
        this.type = json.type;
        this.balance = new Decimal(json.balance);
        this.cryptoProperties = json.cryptoProperties ? new AccountCryptoProperties(json.cryptoProperties) : null;
        this.fiatProperties = json.fiatProperties ? new AccountFiatProperties(json.fiatProperties) : null;
    }

}