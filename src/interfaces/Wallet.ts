import { Decimal } from 'decimal.js';
import {
  Transaction,
  ComposedTransaction,
  Exchange,
  ComposedExchange,
  ExchangeRate,
  ExchangeSetting,
} from 'zumokit';

/**
 * User wallet interface describes methods for transfer and exchange of fiat and cryptocurrency funds.
 *
 * Sending a transaction or making an exchange is a two step process. First a transaction or
 * exchange has to be composed via one of the compose methods, then {@link  ComposedTransaction ComposedTransaction} or
 * {@link  ComposedExchange ComposedExchange} can be submitted.
 * <p>
 * User wallet instance can be obtained by {@link User.createWallet creating}, {@link User.unlockWallet unlocking} or {@link User.recoverWallet recovering} user wallet.
 * <p>
 * See {@link User}.
 */
export interface Wallet {
  /**
   * Compose Ethereum transaction asynchronously.
   * Refer to <a href="https://developers.zumo.money/docs/guides/send-transactions#ethereum">Send Transactions</a>
   * guide for usage details.
   *
   * @param fromAccountId        {@link  Account Account} identifier
   * @param gasPrice             gas price in gwei
   * @param gasLimit             gas limit
   * @param destinationAddress   destination wallet address
   * @param amount               amount in ETH
   * @param data                 data in string format or null
   * @param nonce                next transaction nonce or null
   * @param sendMax              send maximum possible funds to destination (defaults to false)
   */
  composeEthTransaction(
    fromAccountId: string,
    gasPrice: Decimal,
    gasLimit: number,
    destinationAddress: string | null,
    amount: Decimal | null,
    data: string | null,
    nonce: number | null,
    sendMax: boolean
  ): Promise<ComposedTransaction>;

  /**
   * Compose BTC or BSV transaction asynchronously.
   * Refer to <a href="https://developers.zumo.money/docs/guides/send-transactions#bitcoin">Send Transactions</a>
   * guide for usage details.
   *
   * @param fromAccountId       {@link  Account Account} identifier
   * @param changeAccountId     change {@link  Account Account} identifier, which can be the same as fromAccountId
   * @param destinationAddress  destination wallet address
   * @param amount              amount in BTC or BSV
   * @param feeRate             fee rate in satoshis/byte
   * @param sendMax             send maximum possible funds to destination (defaults to false)
   */
  composeTransaction(
    fromAccountId: string,
    changeAccountId: string,
    destinationAddress: string,
    amount: Decimal | null,
    feeRate: Decimal,
    sendMax: boolean
  ): Promise<ComposedTransaction>;

  /**
   * Compose fiat transaction between users in Zumo ecosystem asynchronously.
   * Refer to <a href="https://developers.zumo.money/docs/guides/send-transactions#internal-fiat-transaction">Send Transactions</a>
   * guide for usage details.
   *
   * @param fromAccountId {@link  Account Account} identifier
   * @param toAccountId   {@link  Account Account} identifier
   * @param amount          amount in source account currency
   * @param sendMax        send maximum possible funds to destination (defaults to false)
   */
  composeInternalFiatTransaction(
    fromAccountId: string,
    toAccountId: string,
    amount: Decimal | null,
    sendMax: boolean
  ): Promise<ComposedTransaction>;

  /**
   * Compose transaction to nominated account asynchronously.
   * Refer to <a href="https://developers.zumo.money/docs/guides/send-transactions#external-fiat-transaction">Send Transactions</a>
   * guide for usage details.
   *
   * @param fromAccountId {@link  Account Account} identifier
   * @param amount          amount in source account currency
   * @param sendMax        send maximum possible funds to destination (defaults to false)
   */
  composeTransactionToNominatedAccount(
    fromAccountId: string,
    amount: Decimal | null,
    sendMax: boolean
  ): Promise<ComposedTransaction>;

  /**
   * Submit a transaction asynchronously.
   * Refer to <a href="https://developers.zumo.money/docs/guides/send-transactions#submit-transaction">Send Transactions</a>
   * guide for usage details.
   *
   * @param composedTransaction Composed transaction retrieved as a result
   *                             of one of the compose transaction methods
   */
  submitTransaction(composedTransaction: ComposedTransaction): Promise<Transaction>;

  /**
   * Compose exchange asynchronously.
   * Refer to <a href="https://developers.zumo.money/docs/guides/make-exchanges#compose-exchange">Make Exchanges</a>
   * guide for usage details.
   *
   * @param fromAccountId       {@link  Account Account} identifier
   * @param toAccountId         {@link  Account Account} identifier
   * @param exchangeRate        Zumo exchange rate obtained from ZumoKit state
   * @param exchangeSetting     Zumo exchange setting obtained from ZumoKit state
   * @param amount              amount in deposit account currency
   * @param sendMax             exchange maximum possible funds
   */
  composeExchange(
    fromAccountId: string,
    toAccountId: string,
    exchangeRate: ExchangeRate,
    exchangeSetting: ExchangeSetting,
    amount: Decimal | null,
    sendMax: boolean
  ): Promise<ComposedExchange>;

  /**
   * Submit an exchange asynchronously.
   * Refer to <a href="https://developers.zumo.money/docs/guides/make-exchanges#submit-exchange">Make Exchanges</a>
   * guide for usage details.
   *
   * @param composedExchange Composed exchange retrieved as the result
   *                          of {@link composeExchange} method
   */
  submitExchange(composedExchange: ComposedExchange): Promise<Exchange>;
}
