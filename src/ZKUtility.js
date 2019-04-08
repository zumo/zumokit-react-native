import { NativeModules } from 'react-native';
const { RNZumoKit } = NativeModules;

class ZKUtility {

    /**
     * Converts the given ETH value into Fiat.
     * 
     * @param {number} eth
     * @returns
     * @memberof ZKUtility
     */
    async getFiat(eth) {
        const rates = await this.getExchangeRates();
        return rates.ETH.EUR * eth;
    }

    /**
     * Loads the exchange rate from the native SDK.
     *
     * @returns
     * @memberof ZKUtility
     */
    async getExchangeRates() {
        const string = await RNZumoKit.getExchangeRates();
        const json = JSON.parse(string);
        return json;
    }

    /**
     * Checks whether the address is valid or not.
     * 
     * @param {string} address
     * @returns
     * @memberof ZKUtility
     */
    isValidEthAddress = RNZumoKit.isValidEthAddress;

}

export default new ZKUtility();