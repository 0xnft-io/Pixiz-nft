const HDWalletProvider = require("@truffle/hdwallet-provider");

const PW = process.env.WALLET_PASSWORD;
const MNEMONIC = process.env.MNEMONIC;
const NODE_API_KEY = process.env.INFURA_PROJECT_ID;

if ((!MNEMONIC || !NODE_API_KEY)) {
  console.error("Please set a mnemonic and INFURA_KEY.");
  process.exit(0);
}

const rinkebyNodeUrl = "https://rinkeby.infura.io/v3/" + NODE_API_KEY;

const mainnetNodeUrl = "https://mainnet.infura.io/v3/" + NODE_API_KEY;

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 7545,
      gas: 6700000,
      network_id: "*", // Match any network id
    },
    rinkeby: {
      provider: function () {
        const wallet = new HDWalletProvider({
          mnemonic: MNEMONIC,
          password: PW,
          providerOrUrl: rinkebyNodeUrl,
          addressIndex: 0
        });
        console.log(`using wallet=${JSON.stringify(wallet.getAddress(0))}`);
        return wallet;
      },
      gas: 6700000,
      gasPrice: 5000000000,
      network_id: "4",
    },
    mainnet: {
      network_id: 1,
      provider: function () {
        const wallet = new HDWalletProvider({
          mnemonic: MNEMONIC,
          providerOrUrl: mainnetNodeUrl,
          addressIndex: 0
        });
        console.log(`wallet=${JSON.stringify(wallet)}`);
        return wallet
      },
      gas: 6700000,
      gasPrice: 5000000000,
    },
  },
  mocha: {
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD",
      gasPrice: 2,
    },
  },
  compilers: {
    solc: {
      version: "^0.8.0",
    },
  },
};
