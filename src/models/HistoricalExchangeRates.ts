import ExchangeRate from './ExchangeRate';
import { CurrencyCode, Dictionary, TimeInterval } from '../types';

type HistoricalExchangeRates = Dictionary<
  TimeInterval,
  Dictionary<CurrencyCode, Dictionary<CurrencyCode, Array<ExchangeRate>>>
>;

export default HistoricalExchangeRates;
