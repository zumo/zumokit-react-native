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

/**
 * User wallet provides methods for transfer and exchange of fiat and cryptocurrency funds.
 * Sending a transaction or making an exchange is a two step process. First a transaction or
 * exchange has to be composed via one of the compose method, then {@link  ComposedTransaction ComposedTransaction} or
 * {@link  ComposedExchange ComposedExchange} can be submitted.
 * <p>
 * User wallet instance can be obtained by creating, unlocking or recovering user wallet.
 * <p>
 * See {@link User}.
 */
@tryCatchProxy
export default class Wallet {
  /**
   * Compose Ethereum transaction asynchronously. Refer to <a href="https://developers.zumo.money/docs/guides/send-transactions#ethereum">Send Transactions</a> guide for usage details.
   *
   * @param fromAccountId        {@link  Account Account} identifier
   * @param gasPrice             gas price in gwei
   * @param gasLimit             gas limit
   * @param destinationAddress   destination wallet address
   * @param amount               amount in ETH
   * @param data                 data in string format or null
   * @param nonce                next transaction nonce or null
   * @param sendMax              send maximum possible funds to destination
   */
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

  /**
   * Compose Bitcoin transaction asynchronously. Refer to <a href="https://developers.zumo.money/docs/guides/send-transactions#bitcoin">Send Transactions</a> guide for usage details.
   *
   * @param fromAccountId       {@link  Account Account} identifier
   * @param changeAccountId     change {@link  Account Account} identifier, which can be the same as fromAccountId
   * @param destinationAddress  destination wallet address
   * @param amount              amount in BTC
   * @param feeRate             fee rate in satoshis/byte
   * @param sendMax             send maximum possible funds to destination
   */
  async composeBtcTransaction(
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

  /**
   * Compose fiat transaction between users in Zumo ecosystem asynchronously. Refer to <a href="https://developers.zumo.money/docs/guides/send-transactions#internal-fiat-transaction">Send Transactions</a> guide for usage details.
   *
   * @param fromAccountId {@link  Account Account} identifier
   * @param toAccountId   {@link  Account Account} identifier
   * @param amount          amount in source account currency
   * @param sendMax        send maximum possible funds to destination
   */
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

  /**
   * Compose transaction to nominated account asynchronously. Refer to <a href="https://developers.zumo.money/docs/guides/send-transactions#external-fiat-transaction">Send Transactions</a> guide for usage details.
   *
   * @param fromAccountId {@link  Account Account} identifier
   * @param amount          amount in source account currency
   * @param sendMax        send maximum possible funds to destination
   */
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

  /**
   * Submit a transaction asynchronously. Refer to <a href="https://developers.zumo.money/docs/guides/send-transactions#submit-transaction">Send Transactions</a> guide for usage details.
   *
   * @param composedTransaction Composed transaction retrieved as a result
   *                             of one of the compose transaction methods
   */
  async submitTransaction(composedTransaction: ComposedTransaction) {
    const json = await RNZumoKit.submitTransaction(composedTransaction.json);

    return new Transaction(json);
  }

  /**
   * Compose exchange asynchronously. Refer to <a href="https://developers.zumo.money/docs/guides/make-exchanges#compose-exchange">Make Exchanges</a> guide for usage details.
   *
   * @param fromAccountId       {@link  Account Account} identifier
   * @param toAccountId         {@link  Account Account} identifier
   * @param exchangeRate        Zumo exchange rate obtained from ZumoKit state
   * @param exchangeSettings    Zumo exchange settings obtained from ZumoKit state
   * @param amount              amount in deposit account currency
   * @param sendMax             exchange maximum possible funds
   */
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

  /**
   * Submit an exchange asynchronously. <a href="https://developers.zumo.money/docs/guides/make-exchanges#submit-exchange">Make Exchanges</a> guide for usage details.
   *
   * @param composedExchange Composed exchange retrieved as the result
   *                          of {@link composeExchange} method
   */
  async submitExchange(composedExchange: ComposedExchange) {
    const json = await RNZumoKit.submitExchange(composedExchange.json);
    return new Exchange(json);
  }
}
