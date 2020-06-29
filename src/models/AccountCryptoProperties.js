export default class AccountCryptoProperties {
    constructor(json) {
        this.json = json;
        this.address = json.address;
        this.path = json.path;
        this.nonce = json.nonce;
    }
}