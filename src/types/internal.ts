import { AccountJSON } from 'zumokit/src/types/internal';

export { AccountJSON };

export interface UserJSON {
  id: string;
  hasWallet: boolean;
  accounts: Array<AccountJSON>;
}

export {
  AccountCryptoPropertiesJSON,
  AccountFiatPropertiesJSON,
  ExchangeRateJSON,
  ExchangeSettingJSON,
  ComposedTransactionJSON,
  ComposedExchangeJSON,
  TransactionFeeRateJSON,
  TransactionCryptoPropertiesJSON,
  TransactionFiatPropertiesJSON,
  TransactionJSON,
  ExchangeJSON,
  AccountDataSnapshotJSON,
  HistoricalExchangeRatesJSON,
  ZumoKitErrorJSON,
} from 'zumokit/src/types/internal';
