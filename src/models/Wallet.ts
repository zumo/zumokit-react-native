import { NativeModules } from 'react-native';
import Decimal from 'decimal.js';
import Transaction from './Transaction';
import ComposedTransaction from './ComposedTransaction';
import Exchange from './Exchange';
import ComposedExchange from './ComposedExchange';
import tryCatchProxy from '../ZKErrorProxy';
import ExchangeRate from './ExchangeRate';
import ExchangeSettings from './ExchangeSettings';

const { RNZumoKit } = NativeModules;

@tryCatchProxy
export default class Wallet {
  async composeEthTransaction(
    accountId: string,
    gasPrice: Decimal,
    gasLimit: number,
    destinationAddresss: string,
    amount: Decimal | null,
    data: string | null,
    nonce: number,
    sendMax = false
  ) {
    const json = await RNZumoKit.composeEthTransaction(
      accountId,
      gasPrice.toString(),
      gasLimit.toString(),
      destinationAddresss,
      amount ? amount.toString() : null,
      data,
      nonce ? nonce.toString() : null,
      sendMax
    );

    return new ComposedTransaction(json);
  }

  async composeBtcTransaction(
    accountId: string,
    changeAccountId: string,
    destinationAddresss: string,
    amount: Decimal | null,
    feeRate: Decimal,
    sendMax = false
  ) {
    const json = await RNZumoKit.composeBtcTransaction(
      accountId,
      changeAccountId,
      destinationAddresss,
      amount ? amount.toString() : null,
      feeRate.toString(),
      sendMax
    );

    return new ComposedTransaction(json);
  }

  async composeInternalFiatTransaction(
    fromAccountId: string,
    toAccountId: string,
    amount: Decimal | null,
    sendMax = false
  ) {
    const json = await RNZumoKit.composeInternalFiatTransaction(
      fromAccountId,
      toAccountId,
      amount ? amount.toString() : null,
      sendMax
    );

    return new ComposedTransaction(json);
  }

  async composeTransactionToNominatedAccount(
    fromAccountId: string,
    amount: Decimal | null,
    sendMax = false
  ) {
    const json = await RNZumoKit.composeTransactionToNominatedAccount(
      fromAccountId,
      amount ? amount.toString() : null,
      sendMax
    );

    return new ComposedTransaction(json);
  }

  async submitTransaction(composedTransaction: ComposedTransaction) {
    const json = await RNZumoKit.submitTransaction(composedTransaction.json);

    return new Transaction(json);
  }

  async composeExchange(
    fromAccountId: string,
    toAccountId: string,
    exchangeRate: ExchangeRate,
    exchangeSettings: ExchangeSettings,
    amount: Decimal | null,
    sendMax = false
  ) {
    const json = await RNZumoKit.composeExchange(
      fromAccountId,
      toAccountId,
      exchangeRate.json,
      exchangeSettings.json,
      amount ? amount.toString() : null,
      sendMax
    );

    return new ComposedExchange(json);
  }

  async submitExchange(composedExchange: ComposedExchange) {
    const json = await RNZumoKit.submitExchange(composedExchange.json);
    return new Exchange(json);
  }
}
