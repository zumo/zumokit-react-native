export type Dictionary<K extends string, T> = Partial<Record<K, T>>;

export type CurrencyType = 'CRYPTO' | 'FIAT';

export type CurrencyCode = 'BTC' | 'ETH' | 'USD' | 'GBP' | 'EUR';

export type Network = 'MAINNET' | 'TESTNET' | 'RINKEBY' | 'ROPSTEN' | 'GOERLI';

export type AccountType = 'STANDARD' | 'COMPATIBILITY' | 'SEGWIT';

export type TransactionType = 'CRYPTO' | 'EXCHANGE' | 'FIAT' | 'NOMINATED';

export type TransactionStatus =
  | 'PENDING'
  | 'CONFIRMED'
  | 'FAILED'
  | 'RESUBMITTED'
  | 'CANCELLED'
  | 'PAUSED'
  | 'REJECTED';

export type ExchangeStatus =
  | 'PENDING'
  | 'DEPOSITED'
  | 'CONFIRMED'
  | 'FAILED'
  | 'RESUBMITTED'
  | 'CANCELLED'
  | 'PAUSED'
  | 'REJECTED';

export type TimeInterval = 'hour' | 'day' | 'week' | 'month' | 'quarter' | 'year';

export interface AccountCryptoPropertiesJSON {
  address: string;
  path: string;
  nonce: number | null;
}

export interface AccountFiatPropertiesJSON {
  accountNumber: string | null;
  sortCode: string | null;
  bic: string | null;
  iban: string | null;
  customerName: string | null;
}

export interface AccountJSON {
  id: string;
  currencyType: string;
  currencyCode: string;
  network: string;
  type: string;
  balance: string;
  cryptoProperties: AccountCryptoPropertiesJSON;
  fiatProperties: AccountFiatPropertiesJSON;
}

export interface ExchangeRateJSON {
  id: string;
  depositCurrency: string;
  withdrawCurrency: string;
  value: string;
  validTo: number;
  timestamp: number;
}

export interface ExchangeSettingsJSON {
  id: string;
  depositCurrency: string;
  withdrawCurrency: string;
  depositAddress: string;
  minExchangeAmount: string;
  depositFeeRate: string;
  feeRate: string;
  withdrawFee: string;
  timestamp: number;
}

export interface ComposedTransactionJSON {
  type: string;
  signedTransaction: string | null;
  account: AccountJSON;
  destination: string | null;
  amount: string | null;
  data: string | null;
  fee: string;
  nonce: string;
}

export interface ComposedExchangeJSON {
  signedTransaction: string | null;
  depositAccount: AccountJSON;
  withdrawAccount: AccountJSON;
  exchangeRate: ExchangeRateJSON;
  exchangeSettings: ExchangeSettingsJSON;
  exchangeAddress: string | null;
  value: string;
  depositFee: string;
  returnValue: string;
  exchangeFee: string;
  withdrawFee: string;
  nonce: string;
}

export interface FeeRatesJSON {
  slow: string;
  average: string;
  fast: string;
  slowTime: number;
  averageTime: number;
  fastTime: number;
  source: string;
}

export interface TransactionCryptoPropertiesJSON {
  txHash: string | null;
  nonce: string | null;
  fromAddress: string;
  toAddress: string | null;
  data: string | null;
  gasPrice: string | null;
  gasLimit: string | null;
  fiatFee: Record<string, string>;
  fiatAmount: Record<string, string>;
}

export interface TransactionFiatPropertiesJSON {
  fromFiatAccount: AccountFiatPropertiesJSON;
  toFiatAccount: AccountFiatPropertiesJSON;
}

export interface TransactionJSON {
  id: string;
  type: string;
  currencyCode: string;
  fromUserId: string | null;
  toUserId: string | null;
  fromAccountId: string | null;
  toAccountId: string | null;
  network: string;
  status: string;
  amount: string | null;
  fee: string | null;
  nonce: string;
  cryptoProperties: TransactionCryptoPropertiesJSON | null;
  fiatProperties: TransactionFiatPropertiesJSON | null;
  submittedAt: number | null;
  confirmedAt: number | null;
  timestamp: number;
}

export interface ExchangeJSON {
  id: string;
  status: string;
  depositCurrency: string;
  depositAccountId: string;
  depositTransactionId: string | null;
  depositFee: string | null;
  withdrawCurrency: string;
  withdrawAccountId: string;
  withdrawTransactionId: string | null;
  withdrawFee: string;
  amount: string;
  returnAmount: string;
  exchangeFee: string;
  exchangeRate: ExchangeRateJSON;
  exchangeSettings: ExchangeSettingsJSON;
  exchangeRates: Record<string, Record<string, ExchangeRateJSON>>;
  nonce: string | null;
  submittedAt: number;
  confirmedAt: number | null;
  timestamp: number;
}

export interface UserJSON {
  id: string;
  hasWallet: boolean;
}

export interface ZumoKitConfig {
  apiKey: string;
  apiRoot: string;
  txServiceUrl: string;
}

export interface TokenSet {
  accessToken: string;
  expiresIn: number;
  refreshToken: string;
}

export interface ModulrCustomerData {
  firstName: string;
  middleName: string | null;
  lastName: string;
  dateOfBirth: string;
  email: string;
  phone: string;
  addressLine1: string;
  addressLine2: string | null;
  country: string;
  postCode: string;
  postTown: string;
}
