import { NativeModules } from 'react-native';
const { RNZumoKit } = NativeModules;

class ZKUtility {

    // public String getBalance(Keystore keystore);
    // public String ethGetBalance(String address);
    // public boolean isValidEthAddress(String address);
    // public String weiToEth(String number);
    // public String ethToWei(String number);
    // public String gweiToEth(String number);
    // public String ethToGwei(String number);

    getFiat = RNZumoKit.getFiat;

}

export default new ZKUtility();