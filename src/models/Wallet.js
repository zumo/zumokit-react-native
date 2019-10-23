import { NativeModules } from 'react-native';
import Transaction from './Transaction';
const { RNZumoKit } = NativeModules;

export default class Wallet {

    /**
     * Sends a new transaction on the Ethereum blockchain.
     *
     * @param {string} accountId
     * @param {string} gasPrice
     * @param {string} gasLimit
     * @param {string} to
     * @param {string} value
     * @param {string} data
     * @param {number} nonce
     * @returns
     * @memberof Wallet
     */
    async sendEthTransaction(accountId, gasPrice, gasLimit, to, value, data, nonce) {
        const json = await RNZumoKit.sendEthTransaction(
            accountId,
            '' + gasPrice,
            '' + gasLimit,
            to,
            '' + value,
            data,
            nonce
        );

        return new Transaction(json);
    }

}