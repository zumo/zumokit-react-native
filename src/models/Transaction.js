import { NativeModules, NativeEventEmitter } from 'react-native';
import { Decimal } from 'decimal.js';
const { RNZumoKit } = NativeModules;
import { tryCatchProxy } from '../ZKErrorProxy';
import CryptoDetails from './CryptoDetails';

class Transaction {
    /**
     * The emitter that bubbles events from the native side.
     *
     * @memberof ZumoKit
     */
    _emitter = new NativeEventEmitter(RNZumoKit);

    /**
     * Transaction listener to notify when an event occurs.
     *
     * @memberof Transaction
     */
    _transactionListener;

    constructor(json) {
        this.json = json;
        this.id = json.id;
        this.type = json.type;
        this.currencyCode = json.currencyCode;
        this.fromUserId = json.fromUserId;
        this.toUserId = json.toUserId;
        this.fromAccountId = json.fromAccountId;
        this.toAccountId = json.toAccountId;
        this.network = json.network;
        this.status = json.status;
        this.amount = (json.amount) ? new Decimal(json.amount) : null;
        this.fee = (json.fee) ? new Decimal(json.fee) : null;
        this.nonce = json.nonce;
        this.cryptoDetails = json.cryptoDetails ? new CryptoDetails(json.cryptoDetails) : null;
        this.fiatDetails = null;
        this.submittedAt = json.submittedAt;
        this.confirmedAt = json.confirmedAt;
        this.timestamp = json.timestamp;
    }

    async addListener(callback) {

        await RNZumoKit.addTransactionListener(this.id);

        this._transactionListener = this._emitter.addListener('TransactionChanged', (transaction) => {
            if (transaction.status) this.status = transaction.status;
            callback(this);
        });

    }

    async removeListener() {

        if (!this._transactionListener) return;

        this._transactionListener.removeListener();
        this._transactionListener = null;

        await RNZumoKit.removeTransactionListener();

    }

}

export default (tryCatchProxy(Transaction))