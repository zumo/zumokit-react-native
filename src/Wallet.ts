import { NativeModules } from "react-native";
import Decimal from "decimal.js";
import { ComposedTransaction, ComposedExchange } from "zumokit/src/models";
import { tryCatchProxy } from "./utility/errorProxy";

const {
  /** @internal */
  RNZumoKit,
} = NativeModules;

/**
 * User wallet interface describes methods for transfer and exchange of fiat and cryptocurrency funds.
 * <p>
 * User wallet instance can be obtained by {@link User.createWallet creating}, {@link User.unlockWallet unlocking} or {@link User.recoverWallet recovering} user wallet.
 * <p>
 * Sending a transaction or making an exchange is a two step process. First a transaction or
 * exchange has to be composed via one of the compose methods, then {@link  ComposedTransaction ComposedTransaction} or
 * {@link  ComposedExchange ComposedExchange} can be submitted.
 */
@tryCatchProxy
export class Wallet {
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
   * @param data                 data in string format or null (defaults to null)
   * @param nonce                next transaction nonce or null (defaults to null)
   * @param sendMax              send maximum possible funds to destination (defaults to false)
   */
  async composeEthTransaction(
    fromAccountId: string,
    gasPrice: Decimal,
    gasLimit: number,
    destinationAddress: string | null,
    amount: Decimal | null,
    data: string | null = null,
    nonce: number | null = null,
    sendMax = false
  ) {
    const json = await RNZumoKit.composeEthTransaction(
      fromAccountId,
      gasPrice.toString(),
      gasLimit,
      destinationAddress,
      amount ? amount.toString() : null,
      data,
      // RN bridge does not support nullable numbers
      nonce ? nonce.toString() : null,
      sendMax
    );

    return new ComposedTransaction(json);
  }

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
}
