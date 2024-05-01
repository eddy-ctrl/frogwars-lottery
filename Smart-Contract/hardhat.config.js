require("@debridge-finance/hardhat-debridge");
require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

const POLYGON_RPC_URL = process.env.POLYGON_RPC_URL;
const POLYGON_PRIVATE_KEY = process.env.POLYGON_PRIVATE_KEY;
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY;

const LINEA_RPC_URL = process.env.LINEA_RPC_URL;
const LINEA_PRIVATE_KEY = process.env.LINEA_PRIVATE_KEY;
const LINEASCAN_API_KEY = process.env.LINEASCAN_API_KEY;

const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      blockConfirmations: 1
    },
    linea: {
      url: LINEA_RPC_URL,
      accounts: [LINEA_PRIVATE_KEY],
      chainId: 59144,
      blockConfirmations: 1,
      verify: {
        etherscan: {
          apiUrl: 'https://api.lineascan.build/',
          apiKey: LINEASCAN_API_KEY
        }
      }
    },
    polygon: {
      url: POLYGON_RPC_URL,
      accounts: [POLYGON_PRIVATE_KEY],
      chainId: 137,
      blockConfirmations: 1,
      verify: {
        etherscan: {
          apiUrl: 'https://api.polygonscan.com/',
          apiKey: POLYGONSCAN_API_KEY
        }
      }
    }
  },
  /*etherscan: {
    apiKey: {
          linea: LINEASCAN_API_KEY,
          polygon: POLYGONSCAN_API_KEY
      },
  },*/
  gasReporter: {
    enabled: false, 
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true
  },
  solidity: "0.8.7",
  namedAccounts: {
    deployer: {
      default: 0,
    },
    player: {
      default: 1,
    },
  },
  mocha: {
    timeout: 40000
  }
};
