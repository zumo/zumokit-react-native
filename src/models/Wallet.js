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
            (nonce) ? '' + nonce : null
        );

        return new Transaction(json);
    }

    /**
     * Sends a new Bitcoin transaction.
     *
     * @param {string} accountId
     * @param {string} changeAccountId
     * @param {string} to
     * @param {string} value
     * @param {string} feeRate
     * @returns
     * @memberof Wallet
     */
    async sendBtcTransaction(accountId, changeAccountId, to, value, feeRate) {
        const json = await RNZumoKit.sendBtcTransaction(
            accountId,
            changeAccountId,
            to,
            '' + value,
            '' + feeRate
        );

        return new Transaction(json);
    }

}