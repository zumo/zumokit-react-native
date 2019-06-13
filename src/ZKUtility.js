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
        return parseFloat(rates.ETH.EUR.value) * eth;
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

    /**
     * Converts Ethereum to Gwei
     * 
     * @param {string} eth
     * @returns
     * @memberof ZKUtility
     */
    ethToGwei = RNZumoKit.ethToGwei;

    /**
     * Converts Gwei to Ethereum
     * 
     * @param {string} eth
     * @returns
     * @memberof ZKUtility
     */
    gweiToEth = RNZumoKit.gweiToEth;

    /**
     * Converts Ethereum to Wei
     * 
     * @param {string} eth
     * @returns
     * @memberof ZKUtility
     */
    ethToWei = RNZumoKit.ethToWei;

    /**
     * Converts Wei to Ethereum
     * 
     * @param {string} eth
     * @returns
     * @memberof ZKUtility
     */
    weiToEth = RNZumoKit.weiToEth;

}

export default new ZKUtility();