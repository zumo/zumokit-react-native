import { NativeModules } from 'react-native';
import Transaction from './Transaction';
import ComposedTransaction from './ComposedTransaction';
import Exchange from './Exchange';
import ComposedExchange from './ComposedExchange';
const { RNZumoKit } = NativeModules;
import { tryCatchProxy } from '../ZKErrorProxy';

class Wallet {

    /**
     * Composes a new transaction on the Ethereum blockchain.
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
    async composeEthTransaction(accountId, gasPrice, gasLimit, to, value, data, nonce) {
        const json = await RNZumoKit.composeEthTransaction(
            accountId,
            '' + gasPrice,
            '' + gasLimit,
            to,
            '' + value,
            data,
            (nonce) ? '' + nonce : null
        );

        return new ComposedTransaction(json);
    }

    /**
     * Composes a new Bitcoin transaction.
     *
     * @param {string} accountId
     * @param {string} changeAccountId
     * @param {string} to
     * @param {string} value
     * @param {string} feeRate
     * @returns
     * @memberof Wallet
     */
    async composeBtcTransaction(accountId, changeAccountId, to, value, feeRate) {
        const json = await RNZumoKit.composeBtcTransaction(
            accountId,
            changeAccountId,
            to,
            '' + value,
            '' + feeRate
        );

        return new ComposedTransaction(json);
    }

     /**
     * Submits transaction to Transaction Service
     *
     * @param {ComposedTransaction} composedTransaction
     * @returns {Transaction}
     * @memberof Wallet
     */
    async submitTransaction(composedTransaction) {
        const json = await RNZumoKit.submitTransaction(composedTransaction.json);

        return new Transaction(json);
    }

    /**
     * Composes a new exchange
     *
     * @param {string} depositAccountId
     * @param {string} withdrawAccountId
     * @param {ExchangeRate} exchangeRate
     * @param {ExchangeFees} exchangeFees
     * @param {Decimal} value
     * @returns
     * @memberof ComposedExchange
     */
    async composeExchange(depositAccountId, withdrawAccountId, exchangeRate, exchangeFees, value) {
        const json = await RNZumoKit.composeExchange(
            depositAccountId,
            withdrawAccountId,
            exchangeRate.json,
            exchangeFees.json,
            value.toString()
        );

        return new ComposedExchange(json);
    }

    /**
     * Submits exchange to Transaction Service
     *
     * @param {ComposedExchange} composedExchange
     * @returns {Exchange}
     * @memberof Wallet
     */
    async submitExchange(composedExchange) {
        const json = await RNZumoKit.submitExchange(composedExchange.json);
        return new Exchange(json);
    }

    /**
     * Returns the maxmimum amount of Ethereum that can be spent.
     *
     * @param {string} accountId
     * @param {string} gasPrice
     * @param {string} gasLimit
     * @returns
     * @memberof Wallet
     */
    async maxSpendableEth(accountId, gasPrice, gasLimit) {
        return RNZumoKit.maxSpendableEth(accountId, gasPrice, gasLimit);
    }

    /**
     * Returns the maximum amount of Bitcoin that can be spent.
     *
     * @param {string} accountId
     * @param {string} to
     * @param {string} feeRate
     * @returns
     * @memberof Wallet
     */
    async maxSpendableBtc(accountId, to, feeRate) {
        return RNZumoKit.maxSpendableBtc(accountId, to, feeRate);
    }

}

export default (tryCatchProxy(Wallet))