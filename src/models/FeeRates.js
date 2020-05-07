import { Decimal } from 'decimal.js';
import { tryCatchProxy } from '../ZKErrorProxy';

class FeeRates {

    /**
     * Slow fee rate
     *
     * @memberof FeeRates
     */
    slow;

    /**
     * Average fee rate
     *
     * @memberof FeeRates
     */
    average;

    /**
     * Fast fee rate
     *
     * @memberof FeeRates
     */
    fast;

    /**
     * Estimated slow confirmation time in hours
     *
     * @memberof FeeRates
     */
    slow_time;

    /**
     * Estimated average confirmation time in hours
     *
     * @memberof FeeRates
     */
    average_time;

    /**
     * Estimated fast confirmation time in hours
     *
     * @memberof FeeRates
     */
    fast_time;

    /**
     * Source of fees data
     *
     * @memberof FeeRates
     */
    source;

        /**
     * JSON representation of Account object
     *
     * @memberof Account
     */
    json;

    constructor(json) {
        this.json = json;
        if(json.slow) this.slow = new Decimal(json.slow);
        if(json.average) this.average = new Decimal(json.average);
        if(json.fast) this.fast = new Decimal(json.fast);
        if(json.slow_time) this.slow_time = json.slow_time;
        if(json.average_time) this.average_time = json.average_time;
        if(json.fast_time) this.fast_time = json.fast_time;
        if(json.source) this.source = json.source;
    }

}

export default (tryCatchProxy(FeeRates))