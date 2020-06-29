import AccountFiatProperties from './AccountFiatProperties';

export default class TransactionFiatProperties {
    constructor(json) {
        this.json = json;
        this.fromFiatAccount = json.fromFiatAccount ? new AccountFiatProperties(json.fromFiatAccount) : null;
        this.toFiatAccount = json.toFiatAccount ? new AccountFiatProperties(json.toFiatAccount) : null;
    }

}
