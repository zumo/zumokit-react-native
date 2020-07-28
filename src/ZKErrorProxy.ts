import ZumoKitError from './ZumoKitError';

function handler(fun: any) {
  return function bar() {
    try {
      const res = fun.apply(this, arguments);
      if (Promise.resolve(res) == res) {
        return res.catch((e: any) => {
          return e instanceof Error ? Promise.reject(e) : Promise.reject(new ZumoKitError(e));
        });
      }
      return res;
    } catch (e) {
      if (e instanceof Error) {
        throw e;
      } else {
        throw new ZumoKitError(e);
      }
    }
  };
}

export default function tryCatchProxy(constructor: Function) {
  const { prototype } = constructor;

  if (Object.getOwnPropertyNames(prototype).length < 2) {
    return;
  }

  // eslint-disable-next-line no-restricted-syntax
  for (const property in Object.getOwnPropertyDescriptors(prototype)) {
    if (
      Object.prototype.hasOwnProperty.call(prototype, property) &&
      property !== 'constructor' &&
      typeof prototype[property] === 'function'
    ) {
      prototype[property] = handler(prototype[property]);
    }
  }
}
