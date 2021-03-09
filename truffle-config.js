const HDWalletProvider = require('@truffle/hdwallet-provider');
const infuraKey = '8165c77d80d441ab86e573b151f62b8d';

const fs = require('fs');
const mnemonic = fs.readFileSync('.secret').toString().trim();

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '*', // Match any network id
    },
    ropsten: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          `https://ropsten.infura.io/v3/${infuraKey}`
        ),
      network_id: 3, // Ropsten's id.
    },

    kovan: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          `https://kovan.infura.io/v3/${infuraKey}`
        ),
      network_id: 42,
      skipDryRun: true,
      timeoutBlocks: 200,
    },
  },
  compilers: {
    solc: {
      version: '0.6.12',
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: 'petersburg',
    },
  },
  plugins: ['truffle-plugin-verify'],
  api_keys: {
    etherscan: '8R621NFWB6T6RMADTAZT8UGBBC5IATEUEM',
  },
};
