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
     * @param {string} destinationAddresss
     * @param {string} amount
     * @param {string} data
     * @param {number} nonce
     * @returns
     * @memberof Wallet
     */
    async composeEthTransaction(accountId, gasPrice, gasLimit, destinationAddresss, amount, data, nonce) {
        const json = await RNZumoKit.composeEthTransaction(
            accountId,
            '' + gasPrice,
            '' + gasLimit,
            destinationAddresss,
            '' + amount,
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
     * @param {string} destinationAddresss
     * @param {string} amount
     * @param {string} feeRate
     * @returns
     * @memberof Wallet
     */
    async composeBtcTransaction(accountId, changeAccountId, destinationAddresss, amount, feeRate) {
        const json = await RNZumoKit.composeBtcTransaction(
            accountId,
            changeAccountId,
            destinationAddresss,
            '' + amount,
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
     * @param {string} fromAccountId
     * @param {string} toAccountId
     * @param {ExchangeRate} exchangeRate
     * @param {ExchangeSettings} exchangeSettings
     * @param {Decimal} amount
     * @returns
     * @memberof ComposedExchange
     */
    async composeExchange(fromAccountId, toAccountId, exchangeRate, exchangeSettings, amount) {
        const json = await RNZumoKit.composeExchange(
            fromAccountId,
            toAccountId,
            exchangeRate.json,
            exchangeSettings.json,
            amount.toString()
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