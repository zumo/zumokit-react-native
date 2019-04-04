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
    getFiat = RNZumoKit.getFiat;

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