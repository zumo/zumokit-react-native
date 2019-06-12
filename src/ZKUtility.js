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

    ethToGwei(eth) {
        return eth * 1000000000;
    }

    gweiToEth(gwei) {
        return gwei / 1000000000;
    }

    ethToWei(eth) {
        return eth / 1000000000000000000;
    }

    weiToEth(wei) {
        return wei * 1000000000000000000;
    }

}

export default new ZKUtility();