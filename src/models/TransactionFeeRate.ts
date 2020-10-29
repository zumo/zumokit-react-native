import { Decimal } from 'decimal.js';
import { TransactionFeeRateJSON } from '../types';

/** Crypto transactions fee rates. */
export default class FeeRates {
  /** @internal */
  json: TransactionFeeRateJSON;

  /** Fee rate resulting in slow confirmation time. */
  slow: Decimal;

  /** Fee rate resulting in average confirmation time. */
  average: Decimal;

  /** Fee rate resulting in fast confirmation time. */
  fast: Decimal;

  /** Slow confirmation time in hours. */
  slowTime: number;

  /** Average confirmation time in hours. */
  averageTime: number;

  /** Fast confirmation time in hours. */
  fastTime: number;

  /** Fee rate information provider. */
  source: string;

  /** @internal */
  constructor(json: TransactionFeeRateJSON) {
    this.json = json;
    this.slow = new Decimal(json.slow);
    this.average = new Decimal(json.average);
    this.fast = new Decimal(json.fast);
    this.slowTime = json.slowTime;
    this.averageTime = json.averageTime;
    this.fastTime = json.fastTime;
    this.source = json.source;
  }
}
