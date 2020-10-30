import ExchangeRate from '../models/ExchangeRate';
import ExchangeSetting from '../models/ExchangeSetting';
import TransactionFeeRate from '../models/TransactionFeeRate';
import {
  ExchangeRateJSON,
  ExchangeSettingJSON,
  TransactionFeeRateJSON,
  CurrencyCode,
  Dictionary,
  TimeInterval,
} from '../types';

/** @internal */
const parseExchangeRates = (
  exchangeRateMapJSON: Record<string, Record<string, ExchangeRateJSON>>
) => {
  const exchangeRatesMap: Dictionary<CurrencyCode, Dictionary<CurrencyCode, ExchangeRate>> = {};
  Object.keys(exchangeRateMapJSON).forEach((depositCurrency) => {
    const innerMap: Dictionary<CurrencyCode, ExchangeRate> = {};
    Object.keys(exchangeRateMapJSON[depositCurrency]).forEach((toCurrency) => {
      innerMap[toCurrency as CurrencyCode] = new ExchangeRate(
        exchangeRateMapJSON[depositCurrency][toCurrency]
      );
    });
    exchangeRatesMap[depositCurrency as CurrencyCode] = innerMap;
  });
  return exchangeRatesMap;
};

/** @internal */
const parseExchangeSettings = (
  exchangeSettingsMapJSON: Record<string, Record<string, ExchangeSettingJSON>>
) => {
  const exchangeSettings: Dictionary<CurrencyCode, Dictionary<CurrencyCode, ExchangeSetting>> = {};
  Object.keys(exchangeSettingsMapJSON).forEach((depositCurrency) => {
    const innerMap: Dictionary<CurrencyCode, ExchangeSetting> = {};
    Object.keys(exchangeSettingsMapJSON[depositCurrency]).forEach((withdrawCurrency) => {
      innerMap[withdrawCurrency as CurrencyCode] = new ExchangeSetting(
        exchangeSettingsMapJSON[depositCurrency][withdrawCurrency]
      );
    });
    exchangeSettings[depositCurrency as CurrencyCode] = innerMap;
  });
  return exchangeSettings;
};

/** @internal */
const parseTransactionFeeRates = (
  transactionFeeRatesJSON: Record<string, TransactionFeeRateJSON>
) => {
  const feeRates: Dictionary<CurrencyCode, TransactionFeeRate> = {};
  Object.keys(transactionFeeRatesJSON).forEach((currencyCode) => {
    feeRates[currencyCode as CurrencyCode] = new TransactionFeeRate(
      transactionFeeRatesJSON[currencyCode]
    );
  });
  return feeRates;
};

/** @internal */
const parseHistoricalExchangeRates = (
  exchangeRateMapJSON: Record<string, Record<string, Record<string, Array<ExchangeRateJSON>>>>
) => {
  const exchangeRateMap: Dictionary<
    TimeInterval,
    Dictionary<CurrencyCode, Dictionary<CurrencyCode, Array<ExchangeRate>>>
  > = {};
  Object.keys(exchangeRateMapJSON).forEach((timeInterval) => {
    const outerMap: Dictionary<CurrencyCode, Dictionary<CurrencyCode, Array<ExchangeRate>>> =
      exchangeRateMapJSON[timeInterval];
    Object.keys(outerMap).forEach((fromCurrency) => {
      const innerMap: Dictionary<CurrencyCode, Array<ExchangeRate>> = outerMap[
        fromCurrency as CurrencyCode
      ] as Dictionary<CurrencyCode, Array<ExchangeRate>>;
      Object.keys(innerMap).forEach((toCurrency) => {
        const array: Array<ExchangeRateJSON> = exchangeRateMapJSON[timeInterval][fromCurrency][
          toCurrency
        ] as Array<ExchangeRateJSON>;

        if (!exchangeRateMap[timeInterval as TimeInterval])
          exchangeRateMap[timeInterval as TimeInterval] = {};

        if (!exchangeRateMap[timeInterval as TimeInterval][fromCurrency as CurrencyCode])
          exchangeRateMap[timeInterval as TimeInterval][fromCurrency as CurrencyCode] = {};

        exchangeRateMap[timeInterval as TimeInterval][fromCurrency as CurrencyCode][
          toCurrency as CurrencyCode
        ] = array.map((exchangeRateJSON) => new ExchangeRate(exchangeRateJSON));
      });
    });
  });
  return exchangeRateMap;
};

export {
  parseExchangeRates,
  parseExchangeSettings,
  parseTransactionFeeRates,
  parseHistoricalExchangeRates,
};
