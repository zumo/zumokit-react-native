import { Decimal } from 'decimal.js';
import { FeeRatesJSON } from '../types';

export default class FeeRates {
  json: FeeRatesJSON;

  slow: Decimal;

  average: Decimal;

  fast: Decimal;

  slowTime: number;

  averageTime: number;

  fastTime: number;

  source: string;

  constructor(json: FeeRatesJSON) {
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
