import { NativeModules } from 'react-native';
import Wallet from './Wallet';
import Account from './Account';
import Transaction from './Transaction';
import AccountFiatProperties from './AccountFiatProperties';
import tryCatchProxy from '../ZKErrorProxy';
import {
  UserJSON,
  CurrencyCode,
  Network,
  AccountType,
  AccountJSON,
  TransactionJSON,
  ModulrCustomerData,
} from '../types';

const { RNZumoKit } = NativeModules;

@tryCatchProxy
export default class User {
  id: string;

  hasWallet: boolean;

  constructor(json: UserJSON) {
    this.id = json.id;
    this.hasWallet = !!json.hasWallet;
  }

  async createWallet(mnemonic: string, password: string) {
    await RNZumoKit.createWallet(mnemonic, password);
    this.hasWallet = true;
    return new Wallet();
  }

  async unlockWallet(password: string) {
    await RNZumoKit.unlockWallet(password);
    return new Wallet();
  }

  async revealMnemonic(password: string) {
    return RNZumoKit.revealMnemonic(password);
  }

  async isRecoveryMnemonic(mnemonic: string) {
    return RNZumoKit.isRecoveryMnemonic(mnemonic);
  }

  async recoverWallet(mnemonic: string, password: string) {
    return RNZumoKit.recoverWallet(mnemonic, password);
  }

  async getAccount(currencyCode: CurrencyCode, network: Network, type: AccountType) {
    const json = await RNZumoKit.getAccount(currencyCode, network, type);
    return new Account(json);
  }

  async getAccounts() {
    const array = await RNZumoKit.getAccounts();
    return array.map((json: AccountJSON) => new Account(json));
  }

  async getTransactions() {
    const array = await RNZumoKit.getTransactions();
    return array.map((json: TransactionJSON) => new Transaction(json));
  }

  async getAccountTransactions(accountId: string) {
    const array = await RNZumoKit.getAccountTransactions(accountId);
    return array.map((json: TransactionJSON) => new Transaction(json));
  }

  async isModulrCustomer(network: Network) {
    return RNZumoKit.isModulrCustomer(network);
  }

  async makeModulrCustomer(network: Network, customerData: ModulrCustomerData) {
    return RNZumoKit.makeModulrCustomer(network, customerData);
  }

  async createFiatAccount(network: Network, currencyCode: CurrencyCode) {
    const json = await RNZumoKit.createFiatAccount(network, currencyCode);
    return new Account(json);
  }

  async getNominatedAccountFiatPoperties(accountId: string) {
    try {
      const json = await RNZumoKit.getNominatedAccountFiatPoperties(accountId);
      return new AccountFiatProperties(json);
    } catch (error) {
      return null;
    }
  }
}
