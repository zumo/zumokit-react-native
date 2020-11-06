import { NativeModules } from 'react-native';
import { Transaction } from 'zumokit/src/models/Transaction';
import { ComposedTransaction } from 'zumokit/src/models/ComposedTransaction';
import { Exchange } from 'zumokit/src/models/Exchange';
import { ComposedExchange } from 'zumokit/src/models/ComposedExchange';
import { ExchangeRate } from 'zumokit/src/models/ExchangeRate';
import { ExchangeSetting } from 'zumokit/src/models/ExchangeSetting';
import Decimal from 'decimal.js';
import { Wallet as IWallet } from '../interfaces';
import { tryCatchProxy } from '../utility/errorProxy';

const { RNZumoKit } = NativeModules;

@tryCatchProxy
export class Wallet implements IWallet {
  async composeEthTransaction(
    fromAccountId: string,
    gasPrice: Decimal,
    gasLimit: number,
    destinationAddress: string,
    amount: Decimal | null,
    data: string | null,
    nonce: number,
    sendMax = false
  ) {
    const json = await RNZumoKit.composeEthTransaction(
      fromAccountId,
      gasPrice.toString(),
      gasLimit.toString(),
      destinationAddress,
      amount ? amount.toString() : null,
      data,
      nonce ? nonce.toString() : null,
      sendMax
    );

    return new ComposedTransaction(json);
  }

  async composeTransaction(
    fromAccountId: string,
    changeAccountId: string,
    destinationAddress: string,
    amount: Decimal | null,
    feeRate: Decimal,
    sendMax = false
  ) {
    const json = await RNZumoKit.composeBtcTransaction(
      fromAccountId,
      changeAccountId,
      destinationAddress,
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
    exchangeSetting: ExchangeSetting,
    amount: Decimal | null,
    sendMax = false
  ) {
    const json = await RNZumoKit.composeExchange(
      fromAccountId,
      toAccountId,
      exchangeRate.json,
      exchangeSetting.json,
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
