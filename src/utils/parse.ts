import Decimal from 'decimal.js';
import ExchangeRate from '../models/ExchangeRate';
import { ExchangeRateJSON, CurrencyCode, Dictionary, TimeInterval, Network } from '../types';

/** @internal */
const parseFiatMap = (fiatMapJSON: Record<string, string>) => {
  const fiatMap: Dictionary<CurrencyCode, Decimal> = {};
  Object.keys(fiatMapJSON).forEach((currencyCode) => {
    fiatMap[currencyCode as CurrencyCode] = new Decimal(fiatMapJSON[currencyCode]);
  });
  return fiatMap;
};

/** @internal */
const parseExchangeAddressMap = (exchangeAddressMapJSON: Record<string, string>) => {
  const exchangeAddressMap: Dictionary<Network, string> = {};
  Object.keys(exchangeAddressMapJSON).forEach((network) => {
    exchangeAddressMap[network as Network] = exchangeAddressMapJSON[network];
  });
  return exchangeAddressMap;
};

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
        exchangeRateMap[timeInterval as TimeInterval][fromCurrency as CurrencyCode][
          toCurrency as CurrencyCode
        ] = array.map((exchangeRateJSON) => new ExchangeRate(exchangeRateJSON));
      });
    });
  });
  return exchangeRateMap;
};

export { parseFiatMap, parseExchangeAddressMap, parseExchangeRates, parseHistoricalExchangeRates };
