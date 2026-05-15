const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

const argv = yargs(hideBin(process.argv))
  .option('db-host', {
    type: 'string',
    default: process.env.DB_HOST || '127.0.0.1',
    description: 'Database host'
  })
  .option('db-port', {
    type: 'number',
    default: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 3306,
    description: 'Database port'
  })
  .option('db-user', {
    type: 'string',
    default: process.env.DB_USER || 'dummy_user',
    description: 'Database username'
  })
  .option('db-pass', {
    type: 'string',
    default: process.env.DB_PASSWORD || 'dummy_pass',
    description: 'Database password'
  })
  .option('db-name', {
    type: 'string',
    default: process.env.DB_NAME || 'dummy_db',
    description: 'Database name'
  })
  .option('app-host', {
    type: 'string',
    default: process.env.APP_HOST || '127.0.0.1',
    description: 'Host the Express application will listen on'
  })
  .option('app-port', {
    type: 'number',
    default: process.env.PORT ? parseInt(process.env.PORT, 10) : 5200,
    description: 'Port the Express application will listen on'
  })
  .parseSync();

module.exports = argv;
