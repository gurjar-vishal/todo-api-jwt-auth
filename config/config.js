require('dotenv').config();

module.exports = {
  development: {
    use_env_variable: 'DB_URL',
    dialect: 'postgres',
  },
  test: {
    use_env_variable: 'DB_URL',
    dialect: 'postgres',
  },
  production: {
    use_env_variable: 'DB_URL',
    dialect: 'postgres',
  }
};
