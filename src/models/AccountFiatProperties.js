export default class AccountFiatProperties {
  constructor(json) {
    this.json = json;
    this.accountNumber = json.accountNumber;
    this.sortCode = json.sortCode;
    this.bic = json.bic;
    this.iban = json.iban;
    this.customerName = json.customerName;
  }
}