const eslintJs = require("@eslint/js");
const globals = require("globals");

module.exports = [
  eslintJs.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 12,
      globals: {
        ...globals.node,
        ...globals.jest,
      },
    },
    rules: {
      "no-unused-vars": "warn",
      "no-console": "off",
    },
  },
];