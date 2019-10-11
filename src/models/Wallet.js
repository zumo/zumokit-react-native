import { NativeModules } from 'react-native';
import Transaction from './Transaction';
const { RNZumoKit } = NativeModules;

export default class Wallet {

    /**
     * Sends a new transaction on the Ethereum blockchain.
     *
     * @param {number} gasPrice
     * @param {number} gasLimit
     * @param {string} to
     * @param {number} value
     * @param {string} data
     * @param {number} chainId
     * @param {number} nonce
     * @returns
     * @memberof Wallet
     */
    async sendEthTransaction(gasPrice, gasLimit, to, value, data, chainId, nonce) {
        const json = await RNZumoKit.sendEthTransaction(gasPrice, gasLimit, to, value, data, chainId, nonce);
        return new Transaction(json);
    }

}