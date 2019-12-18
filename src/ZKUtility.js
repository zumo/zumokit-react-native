import { NativeModules } from 'react-native';
const { RNZumoKit } = NativeModules;

class ZKUtility {

    /**
     * Generates and returns a new mnemonic for use with wallet creation.
     *
     * @param {string} wordCount
     * @returns
     * @memberof ZKUtility
     */
    generateMnemonic = RNZumoKit.generateMnemonic;

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
     * Checks whether the address is valid or not.
     * 
     * @param {string} address
     * @returns
     * @memberof ZKUtility
     */
    isValidBtcAddress = RNZumoKit.isValidBtcAddress;

    /**
     * Converts Ethereum to Gwei
     * 
     * @param {string} eth
     * @returns
     * @memberof ZKUtility
     */
    ethToGwei(eth) {
        return RNZumoKit
            .ethToGwei("" + eth);
    }

    /**
     * Converts Gwei to Ethereum
     * 
     * @param {string} eth
     * @returns
     * @memberof ZKUtility
     */
    gweiToEth(gwei) {
        return RNZumoKit
            .gweiToEth("" + gwei);
    }

    /**
     * Converts Ethereum to Wei
     * 
     * @param {string} eth
     * @returns
     * @memberof ZKUtility
     */
    ethToWei(eth) {
        return RNZumoKit
            .ethToWei("" + eth);
    }

    /**
     * Converts Wei to Ethereum
     * 
     * @param {string} eth
     * @returns
     * @memberof ZKUtility
     */
    weiToEth(wei) {
        return RNZumoKit
            .weiToEth("" + wei);
    }
   
}

export default new ZKUtility();