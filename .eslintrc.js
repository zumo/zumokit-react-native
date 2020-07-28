module.exports = {
  "parser": "@typescript-eslint/parser",
  "extends": [
    "airbnb-typescript",
    "prettier",
    "plugin:react-native/all"
  ],
  parserOptions: {
    project: "./tsconfig.json"
  },
  "rules": {
    "brace-style": 2,
    "no-underscore-dangle": 0,
    "class-methods-use-this": 0,
    "@typescript-eslint/indent": 0,
    "prettier/prettier": [
      "error",
      {
        "trailingComma": "es5",
        "singleQuote": true,
        "printWidth": 100
      }
    ],
  },
  "plugins": [
    "prettier"
  ]
}