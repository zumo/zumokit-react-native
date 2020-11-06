import { NativeModules, NativeEventEmitter } from 'react-native';
import { Account } from 'zumokit/src/models/Account';
import { AccountFiatProperties } from 'zumokit/src/models/AccountFiatProperties';
import { AccountDataSnapshot } from 'zumokit/src/models/AccountDataSnapshot';
import { User as IUser } from '../interfaces';
import {
  AccountJSON,
  CurrencyCode,
  Network,
  AccountType,
  AccountDataSnapshotJSON,
  FiatCustomerData,
  UserJSON,
} from '../types';
import { Wallet } from './Wallet';
import { tryCatchProxy } from '../utility/errorProxy';

const { RNZumoKit } = NativeModules;

@tryCatchProxy
export class User implements IUser {
  // Listening to account data changes
  private listeningToChanges = false;

  // The emitter that bubbles events from the native side
  private emitter = new NativeEventEmitter(RNZumoKit);

  // Current user account data snanpshots
  private accountDataSnapshots: Array<AccountDataSnapshot> = [];

  // Listeners for account data changes
  private accountDataListeners: Array<(snapshots: Array<AccountDataSnapshot>) => void> = [];

  id: string;

  hasWallet: boolean;

  accounts: Array<Account>;

  constructor(json: UserJSON) {
    this.id = json.id;
    this.hasWallet = json.hasWallet;
    this.accounts = json.accounts.map((accountJson: AccountJSON) => new Account(accountJson));

    this.emitter.addListener('AccountDataChanged', (snapshots: Array<AccountDataSnapshotJSON>) => {
      this.listeningToChanges = true;
      this.accountDataSnapshots = snapshots.map(
        (snapshot: AccountDataSnapshotJSON) => new AccountDataSnapshot(snapshot)
      );
      this.accounts = this.accountDataSnapshots.map((snapshot) => snapshot.account);
      this.accountDataListeners.forEach((listener) => listener(this.accountDataSnapshots));
    });
  }

  async createWallet(mnemonic: string, password: string) {
    await RNZumoKit.createWallet(mnemonic, password);
    this.hasWallet = true;
    return new Wallet();
  }

  async recoverWallet(mnemonic: string, password: string): Promise<Wallet> {
    await RNZumoKit.recoverWallet(mnemonic, password);
    return new Wallet();
  }

  async unlockWallet(password: string) {
    await RNZumoKit.unlockWallet(password);
    return new Wallet();
  }

  async revealMnemonic(password: string): Promise<string> {
    return RNZumoKit.revealMnemonic(password);
  }

  async isRecoveryMnemonic(mnemonic: string): Promise<boolean> {
    return RNZumoKit.isRecoveryMnemonic(mnemonic);
  }

  getAccount(currencyCode: CurrencyCode, network: Network, type: AccountType) {
    return this.accounts.find(
      (account) =>
        account.currencyCode === currencyCode &&
        account.network === network &&
        account.type === type
    );
  }

  async isFiatCustomer(network: Network): Promise<boolean> {
    return RNZumoKit.isFiatCustomer(network);
  }

  /**
   * Make user fiat customer on specified network by providing user's personal details.
   * @param  network        'MAINNET' or 'TESTNET'
   * @param  customerData    user's personal details.
   */
  async makeFiatCustomer(network: Network, customerData: FiatCustomerData): Promise<void> {
    return RNZumoKit.makeFiatCustomer(network, customerData);
  }

  /**
   * Create fiat account on specified network and currency code. User must already be fiat customer on specified network.
   * @param  network        'MAINNET' or 'TESTNET'
   * @param  currencyCode  country code in ISO 4217 format, e.g. 'GBP'
   */
  async createFiatAccount(network: Network, currencyCode: CurrencyCode) {
    const json = await RNZumoKit.createFiatAccount(network, currencyCode);
    return new Account(json);
  }

  /**
   * Get nominated account details for specified account if it exists.
   * Refer to
   * <a href="https://developers.zumo.money/docs/guides/send-transactions#bitcoin">Create Fiat Account</a>
   * for explanation about nominated account.
   * @param  accountId     {@link  Account Account} identifier
   */
  async getNominatedAccountFiatProperties(accountId: string) {
    try {
      const json = await RNZumoKit.getNominatedAccountFiatPoperties(accountId);
      return new AccountFiatProperties(json);
    } catch (error) {
      return null;
    }
  }

  /**
   * Listen to all account data changes.
   *
   * @param listener interface to listen to user changes
   */
  addAccountDataListener(listener: (snapshots: Array<AccountDataSnapshot>) => void) {
    this.accountDataListeners.push(listener);
    if (this.listeningToChanges) {
      listener(this.accountDataSnapshots);
    } else {
      RNZumoKit.addAccountDataListener();
    }
  }

  /**
   * Remove listener to state changes.
   *
   * @param listener interface to listen to state changes
   */
  removeAccountDataListener(listener: (snapshot: Array<AccountDataSnapshot>) => void) {
    let index = this.accountDataListeners.indexOf(listener);
    while (index !== -1) {
      this.accountDataListeners.splice(index, 1);
      index = this.accountDataListeners.indexOf(listener);
    }
  }
}
