function transformError(error) {
  let { code, message, userInfo } = error
  let type = (userInfo && userInfo.type) ? userInfo.type : "zumo_kit_error"
  return { type, code, message }
}

export function tryCatchProxy (superClass) {
  const prototype = superClass.prototype;

  if (Object.getOwnPropertyNames(prototype).length < 2) {
      return superClass;
  }

  const handler = function(_super) {
    return function() {
        try {
          let res = _super.apply(this, arguments)
          if (Promise.resolve(res) == res) {
            return res.catch((e)=> {
              return Promise.reject(transformError(e))
            });
          } else {
            return res
          }
        } catch (e) {
            throw transformError(e)
        }
    };
  }

  for (const property in Object.getOwnPropertyDescriptors(prototype)) {
      if (Object.prototype.hasOwnProperty.call(prototype, property) &&
            property !== 'constructor' && typeof prototype[property] === 'function') {
          superClass.prototype[property] = handler(superClass.prototype[property])
      }
  }

  return superClass;
}