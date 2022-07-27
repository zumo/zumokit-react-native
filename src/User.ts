import { NativeModules, NativeEventEmitter } from "react-native";
import Decimal from "decimal.js";
import {
  Account,
  AccountFiatProperties,
  AccountDataSnapshot,
  Card,
} from "zumokit/src/models";
import {
  AccountJSON,
  CurrencyCode,
  Network,
  AccountType,
  AccountDataSnapshotJSON,
  Address,
  CardType,
  CardStatus,
  CardDetails,
  KbaAnswer,
  AuthenticationConfig,
} from "zumokit/src/interfaces";
import { Wallet } from "./Wallet";
import { tryCatchProxy } from "./utility/errorProxy";

const {
  /** @internal */
  RNZumoKit,
} = NativeModules;

/** @internal */
interface UserJSON {
  id: string;
  integratorId: string;
  hasWallet: boolean;
  accounts: Array<AccountJSON>;
}

/**
 * User instance, obtained via {@link ZumoKit.signIn} method, provides methods for managing user wallet and accounts.
 * <p>
 * Refer to
 * <a href="https://developers.zumo.money/docs/guides/manage-user-wallet">Manage User Wallet</a>,
 * <a href="https://developers.zumo.money/docs/guides/create-fiat-account">Create Fiat Account</a>,
 * <a href="https://developers.zumo.money/docs/guides/view-user-accounts">View User Accounts</a> and
 * <a href="https://developers.zumo.money/docs/guides/get-account-data">Get Account Data</a>
 * guides for usage details.
 */
@tryCatchProxy
export class User {
  // The emitter that bubbles events from the native side
  private emitter = new NativeEventEmitter(RNZumoKit);

  // Current user account data snapshots are initialised when first AccountDataChanged event is received
  private accountDataSnapshotsInitialised = false;

  // Current user account data snapshots
  private accountDataSnapshots: Array<AccountDataSnapshot> = [];

  // Listeners for account data changes
  private accountDataListeners: Array<
    (snapshots: Array<AccountDataSnapshot>) => void
  > = [];

  /** User identifier. */
  id: string;

  /** User integrator identifier. */
  integratorId: string;

  /** Indicator if user has wallet. */
  hasWallet: boolean;

  /** User accounts. */
  accounts: Array<Account>;

  /** @internal */
  constructor(json: UserJSON) {
    this.id = json.id;
    this.integratorId = json.integratorId;
    this.hasWallet = json.hasWallet;
    this.accounts = json.accounts.map(
      (accountJson: AccountJSON) => new Account(accountJson)
    );

    this.emitter.addListener(
      "AccountDataChanged",
      (snapshots: Array<AccountDataSnapshotJSON>) => {
        this.accountDataSnapshots = snapshots.map(
          (snapshot: AccountDataSnapshotJSON) =>
            new AccountDataSnapshot(snapshot)
        );
        this.accounts = this.accountDataSnapshots.map(
          (snapshot) => snapshot.account
        );
        this.accountDataListeners.forEach((listener) =>
          listener(this.accountDataSnapshots)
        );
        this.accountDataSnapshotsInitialised = true;
      }
    );
    RNZumoKit.addAccountDataListener();
  }

  /**
   * Create user wallet seeded by provided mnemonic and encrypted with user's password.
   * <p>
   * Mnemonic can be generated by {@link Utils.generateMnemonic} utility method.
   * @param  mnemonic       mnemonic seed phrase
   * @param  password       user provided password
   */
  async createWallet(mnemonic: string, password: string) {
    await RNZumoKit.createWallet(mnemonic, password);
    this.hasWallet = true;
    return new Wallet();
  }

  /**
   * Recover user wallet with mnemonic seed phrase corresponding to user's wallet.
   * This can be used if user forgets his password or wants to change his wallet password.
   * @param  mnemonic       mnemonic seed phrase corresponding to user's wallet
   * @param  password       user provided password
   */
  async recoverWallet(mnemonic: string, password: string): Promise<Wallet> {
    await RNZumoKit.recoverWallet(mnemonic, password);
    return new Wallet();
  }

  /**
   * Unlock user wallet with user's password.
   * @param  password       user provided password
   */
  async unlockWallet(password: string) {
    await RNZumoKit.unlockWallet(password);
    return new Wallet();
  }

  /**
   * Reveal mnemonic seed phrase used to seed user wallet.
   * @param  password       user provided password
   */
  async revealMnemonic(password: string): Promise<string> {
    return RNZumoKit.revealMnemonic(password);
  }

  /**
   * Check if mnemonic seed phrase corresponds to user's wallet.
   * This is useful for validating seed phrase before trying to recover wallet.
   * @param  mnemonic       mnemonic seed phrase
   */
  async isRecoveryMnemonic(mnemonic: string): Promise<boolean> {
    return RNZumoKit.isRecoveryMnemonic(mnemonic);
  }

  /**
   * Get account in specific currency, on specific network, with specific type.
   * @param  currencyCode   currency code, e.g. 'BTC', 'ETH' or 'GBP'
   * @param  network        network type, e.g. 'MAINNET', 'TESTNET' or 'RINKEBY'
   * @param  type           account type, e.g. 'STANDARD', 'COMPATIBILITY' or 'SEGWIT'
   */
  getAccount(currencyCode: CurrencyCode, network: Network, type: AccountType) {
    return this.accounts.find(
      (account) =>
        account.currencyCode === currencyCode &&
        account.network === network &&
        account.type === type
    );
  }

  /**
   * Check if user is a fiat customer on 'MAINNET' or 'TESTNET' network.
   * @param  network 'MAINNET' or 'TESTNET'
   */
  async isFiatCustomer(network: Network): Promise<boolean> {
    return RNZumoKit.isFiatCustomer(network);
  }

  /**
   * Make user fiat customer on specified network by providing user's personal details.
   * @param  network        'MAINNET' or 'TESTNET'
   * @param  firstName       first name
   * @param  middleName      middle name or null
   * @param  lastName        last name
   * @param  dateOfBirth     date of birth in ISO 8601 format, e.g '2020-08-12'
   * @param  email           email
   * @param  phone           phone number
   * @param  address         home address
   */
  async makeFiatCustomer(
    network: Network,
    firstName: string,
    middleName: string | null,
    lastName: string,
    dateOfBirth: string,
    email: string,
    phone: string,
    address: Address
  ): Promise<void> {
    return RNZumoKit.makeFiatCustomer(
      network,
      firstName,
      middleName,
      lastName,
      dateOfBirth,
      email,
      phone,
      address
    );
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
      const json = await RNZumoKit.getNominatedAccountFiatProperties(accountId);
      return new AccountFiatProperties(json);
    } catch (error) {
      return null;
    }
  }

  /**
   * Fetch Strong Customer Authentication (SCA) config.
   */
  async fetchAuthenticationConfig(): Promise<AuthenticationConfig> {
    return RNZumoKit.fetchAuthenticationConfig();
  }

  /**
   * Create card for a fiat account.
   * <p>
   * At least one Knowledge-Based Authentication (KBA) answers should be defined,
   * answers are limited to 256 characters and cannot be null or empty and only
   * one answer per question type should be provided.
   * @param  fiatAccountId  fiat {@link Account account} identifier
   * @param  cardType       'VIRTUAL' or 'PHYSICAL'
   * @param  mobileNumber   card holder mobile number, starting with a '+', followed by the country code and then the mobile number, or null
   * @param  knowledgeBase  list of KBA answers
   */
  async createCard(
    fiatAccountId: string,
    cardType: CardType,
    mobileNumber: string,
    knowledgeBase: Array<KbaAnswer>
  ) {
    const json = await RNZumoKit.createCard(
      fiatAccountId,
      cardType,
      mobileNumber,
      knowledgeBase
    );
    return new Card(json);
  }

  /**
   * Set card status to 'ACTIVE', 'BLOCKED' or 'CANCELLED'.
   * - To block card, set card status to 'BLOCKED'.
   * - To activate a physical card, set card status to 'ACTIVE' and provide PAN and CVC2 fields.
   * - To cancel a card, set card status to 'CANCELLED'.
   * - To unblock a card, set card status to 'ACTIVE.'.
   * @param  cardId        {@link Card card} identifier
   * @param  cardStatus    new card status
   * @param  pan           PAN when activating a physical card, null otherwise (defaults to null)
   * @param  cvv2          CVV2 when activating a physical card, null otherwise (defaults to null)
   */
  async setCardStatus(
    cardId: string,
    cardStatus: CardStatus,
    pan: string | null = null,
    cvv2: string | null = null
  ): Promise<void> {
    return RNZumoKit.setCardStatus(cardId, cardStatus, pan, cvv2);
  }

  /**
   * Reveals sensitive card details.
   * @param  cardId  {@link Card card} identifier
   */
  async revealCardDetails(cardId: string) {
    const json = await RNZumoKit.revealCardDetails(cardId);
    return json as CardDetails;
  }

  /**
   * Reveal card PIN.
   * @param  cardId  {@link Card card} identifier
   */
  async revealPin(cardId: string): Promise<number> {
    return RNZumoKit.revealPin(cardId);
  }

  /**
   * Unblock card PIN.
   * @param  cardId  {@link Card card} identifier
   */
  async unblockPin(cardId: string): Promise<void> {
    return RNZumoKit.unblockPin(cardId);
  }

  /**
   * Add KBA answers to a card without SCA.
   * <p>
   * This endpoint is used to set Knowledge-Based Authentication (KBA) answers to
   * a card without Strong Customer Authentication (SCA). Once it is set SCA flag
   * on corresponding card is set to true.
   * <p>
   * At least one answer should be defined, answers are limited to 256 characters and
   * cannot be null or empty and only one answer per question type should be provided.
   *
   * @param  cardId         card id
   * @param  knowledgeBase  list of KBA answers
   */
  async setAuthentication(
    cardId: string,
    knowledgeBase: Array<KbaAnswer>
  ): Promise<void> {
    return RNZumoKit.setAuthentication(cardId, knowledgeBase);
  }

  /**
   * Listen to all account data changes.
   *
   * @param listener interface to listen to user changes
   */
  addAccountDataListener(
    listener: (snapshots: Array<AccountDataSnapshot>) => void
  ) {
    this.accountDataListeners.push(listener);
    if (this.accountDataSnapshotsInitialised) {
      listener(this.accountDataSnapshots);
    }
  }

  /**
   * Remove listener to state changes.
   *
   * @param listener interface to listen to state changes
   */
  removeAccountDataListener(
    listener: (snapshot: Array<AccountDataSnapshot>) => void
  ) {
    let index = this.accountDataListeners.indexOf(listener);
    while (index !== -1) {
      this.accountDataListeners.splice(index, 1);
      index = this.accountDataListeners.indexOf(listener);
    }
  }
}
