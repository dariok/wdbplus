module.exports = {
  "env": {
      "browser": true,
      "es2021": true
  },
  "extends": "xo",
  "overrides": [
    {
      "files": [
        ".eslintrc.{js,cjs}"
      ],
      "parserOptions": {
        "sourceType": "script"
      }
    }
  ],
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "rules": {
  }
}
