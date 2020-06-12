import Account from '../models/Account'
import Transaction from '../models/Transaction'
import Exchange from '../models/Exchange'
import ExchangeRate from '../models/ExchangeRate'
import ExchangeSettings from '../models/ExchangeSettings';
import FeeRates from '../models/FeeRates';

export default class Parser {

  static parseAccounts(accounts) {
    return accounts.map((json) => new Account(json));
  }

  static parseTransactions(transactions) {
    return transactions.map((json) => new Transaction(json));
  }

  static parseExchanges(exchanges) {
    return exchanges.map((json) => new Exchange(json));
  }

  static parseFeeRates(feeRatesMap) {
    for (const currency in feeRatesMap) {
      feeRatesMap[currency] = new FeeRates(feeRatesMap[currency])
    }
    return feeRatesMap
  }


  static parseExchangeRates(exchangeRateMap) {
    for (const depositCurrency in exchangeRateMap) {
      for (const withdrawCurrency in exchangeRateMap[depositCurrency]) {
        exchangeRateMap[depositCurrency][withdrawCurrency] =
          new ExchangeRate(exchangeRateMap[depositCurrency][withdrawCurrency])
      }
    }
    return exchangeRateMap
  }

  static parseExchangeSettings(exchangeSettingsMap) {
    for (const depositCurrency in exchangeSettingsMap) {
      for (const withdrawCurrency in exchangeSettingsMap[depositCurrency]) {
        exchangeSettingsMap[depositCurrency][withdrawCurrency] =
          new ExchangeSettings(exchangeSettingsMap[depositCurrency][withdrawCurrency])
      }
    }
    return exchangeSettingsMap
  }

  static parseHistoricalExchangeRates(exchangeRateMap) {
    for (const timeInterval in exchangeRateMap) {
      let obj1 = exchangeRateMap[timeInterval]
      for (const depositCurrency in obj1) {
        let obj2 = obj1[depositCurrency]
        for (const withdrawCurrency in obj2) {
          let array = obj2[withdrawCurrency]
          exchangeRateMap[timeInterval][depositCurrency][withdrawCurrency] =
            array.map((json) => new ExchangeRate(json))
        }
      }
    }
    return exchangeRateMap
  }

}