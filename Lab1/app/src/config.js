const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

const argv = yargs(hideBin(process.argv))
  .option('db-host', {
    type: 'string',
    default: '127.0.0.1',
    description: 'Database host'
  })
  .option('db-port', {
    type: 'number',
    default: 3306,
    description: 'Database port'
  })
  .option('db-user', {
    type: 'string',
    demandOption: true,
    description: 'Database username'
  })
  .option('db-pass', {
    type: 'string',
    demandOption: true,
    description: 'Database password'
  })
  .option('db-name', {
    type: 'string',
    demandOption: true,
    description: 'Database name'
  })
  .option('app-port', {
    type: 'number',
    default: 5200,
    description: 'Port the Express application will listen on'
  })
  .parseSync();

module.exports = argv;
