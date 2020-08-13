/**
 * ZumoKitError extension to Error class with type, code and message properties.
 * Refer to <a href="https://developers.zumo.money/docs/guides/handling-errors">Handling Error</a>
 * guide for details on handling errors.
 */
export default class ZumoKitError extends Error {
  /**
   * Error type, such as api_connection_error, api_error, wallet_error etc.
   */
  type: string;

  /**
   * In case an error could be handled programmatically in addition to error type
   * error code is returned.
   */
  code: string;

  /**
   * Error message.
   */
  message: string;

  /** @internal */
  constructor(error: { code: string; message: string; userInfo?: { type: string } }) {
    const { code, message, userInfo } = error;
    super(message);

    this.type = userInfo && userInfo.type ? userInfo.type : 'zumo_kit_error';
    this.code = code;
    this.message = message;
  }
}
