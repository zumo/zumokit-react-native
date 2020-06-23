import { Decimal } from 'decimal.js';
import CryptoProperties from './CryptoProperties';
import FiatProperties from './FiatProperties';

export default class Account {
    constructor(json) {
        this.json = json;
        this.id = json.id;
        this.currencyCode = json.currencyCode;
        this.currencyType = json.currencyType;
        this.network = json.network;
        this.type = json.type;
        this.balance = new Decimal(json.balance);
        this.cryptoProperties = json.cryptoProperties ? new CryptoProperties(json.cryptoProperties) : null;
        this.fiatProperties = json.fiatProperties ? new FiatProperties(json.fiatProperties) : null;
    }

}