import { NativeModules } from 'react-native';
const { RNZumoKit } = NativeModules;

/**
 * The core class of ZumoKit.
 *
 * @class ZumoKit
 */
class ZumoKit {

    /**
     * Initialise ZumoKit with the provided JSON config.
     *
     * @param {Object} json
     * @memberof ZumoKit
     */
    init(json) {
        RNZumoKit.init();
    }

}

export default new ZumoKit();