import { Decimal } from 'decimal.js'
import Account from '../models/Account'
import Transaction from '../models/Transaction'
import ExchangeRate from '../models/ExchangeRate'
import FeeRates from '../models/FeeRates';

function parseAccounts(accounts) {
  return accounts.map((json) => new Account(json));
}

function parseTransactions(transactions) {
  return transactions.map((json) => new Transaction(json));
}

function parseFiatValues(fiatMap) {
  for (const currency in fiatMap) {
      fiatMap[currency] = new Decimal(fiatMap[currency])
  }
  return fiatMap
}

function parseFeeRates(feeRatesMap) {
  for (const currency in feeRatesMap) {
    feeRatesMap[currency] = new FeeRates(feeRatesMap[currency])
  }
  return feeRatesMap
}

function parseExchangeRates(exchangeRateMap) {
  for (const depositCurrency in exchangeRateMap) {
    for (const withdrawCurrency in exchangeRateMap[depositCurrency]) {
      exchangeRateMap[depositCurrency][withdrawCurrency] =
        new ExchangeRate(exchangeRateMap[depositCurrency][withdrawCurrency])
    }
  }
  return exchangeRateMap
}

function parseExchangeFees(exchangeFeesMap) {
  for (const depositCurrency in exchangeFeesMap) {
    for (const withdrawCurrency in exchangeFeesMap[depositCurrency]) {
      exchangeFeesMap[depositCurrency][withdrawCurrency] =
        new ExchangeFees(exchangeFeesMap[depositCurrency][withdrawCurrency])
    }
  }
  return exchangeFeesMap
}

function parseHistoricalExchangeRates(exchangeRateMap) {
  for (const timeInterval in exchangeRateMap) {
    let obj1 = exchangeRateMap[timeInterval]
    for (const depositCurrency in obj1) {
      let obj2 = obj1[depositCurrency]
      for (const withdrawCurrency in obj2[depositCurrency]) {
        let array = obj2[withdrawCurrency]
        exchangeRateMap[timeInterval][depositCurrency][withdrawCurrency] =
          array.map((json) => new ExchangeRate(json))
      }
    }
  }
  return exchangeRateMap
}

export {
  parseAccounts,
  parseTransactions,
  parseFiatValues,
  parseFeeRates,
  parseExchangeRates,
  parseExchangeFees,
  parseHistoricalExchangeRates
}