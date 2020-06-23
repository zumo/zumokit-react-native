import { Decimal } from 'decimal.js';

export default class CryptoDetails {
    constructor(json) {
        this.json = json;
        this.txHash = json.txHash;
        this.nonce = json.nonce;
        this.fromAddress = json.fromAddress;
        this.toAddress = json.toAddress;
        this.data = json.data;
        this.gasPrice = (json.gasPrice) ? new Decimal(json.gasPrice) : null;
        this.gasLimit = json.gasLimit;
        this.fiatFee = json.fiatFee;
        this.fiatValue = json.fiatValue;
    }

}
