export default class ZumoKitError extends Error {
  type: string;

  code: string;

  message: string;

  constructor(error: { code: string; message: string; userInfo?: { type: string } }) {
    const { code, message, userInfo } = error;
    super(message);

    this.type = userInfo && userInfo.type ? userInfo.type : 'zumo_kit_error';
    this.code = code;
    this.message = message;
  }
}
