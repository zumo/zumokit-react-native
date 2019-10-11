import { NativeModules } from 'react-native';
import User from './models/User';

const { RNZumoKit } = NativeModules;

/**
 * The core class of ZumoKit.
 *
 * @class ZumoKit
 */
class ZumoKit {

    /**
     * The currently authenticated user.
     *
     * @memberof ZumoKit
     */
    _cachedUser;

    /**
     * Initialise ZumoKit with the provided JSON config.
     *
     * @param {object} config
     * @memberof ZumoKit
     */
    init(config) {
        const { apiKey, apiRoot, myRoot, txServiceUrl } = config;
        RNZumoKit.init(apiKey, apiRoot, myRoot, txServiceUrl);
    }

    /**
     * Authenticates the user with ZumoKit.
     *
     * @param {string} token
     * @param {object} headers
     * @returns
     * @memberof ZumoKit
     */
    async auth(token, headers) {
        const json = await RNZumoKit.auth(token, headers);
        this._cachedUser = new User(json);
        return this._cachedUser;
    }

}

export default new ZumoKit();