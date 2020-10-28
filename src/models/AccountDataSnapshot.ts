import { AccountDataSnapshotJSON } from '../types';
import Account from './Account';
import Transaction from './Transaction';

/** Record containing account data. */
export default class AccountDataSnapshot {
  /** Account. */
  account: Account;

  /** Account's transactions. */
  transactions: Array<Transaction>;

  /** @internal */
  constructor(json: AccountDataSnapshotJSON) {
    this.account = new Account(json.account);
    this.transactions = json.transactions.map((json) => new Transaction(json));
  }
}
