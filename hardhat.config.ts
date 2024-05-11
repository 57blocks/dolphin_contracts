import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-contract-sizer";
require("dotenv").config();


const PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY as string;
const OPSCAN_KEY = process.env.OPSCAN_API_KEY as string;
const ARBSCAN_KEY = process.env.ARBSCAN_API_KEY as string;
const BASESCAN_KEY = process.env.BASESCAN_API_KEY as string;

const config: HardhatUserConfig = {
  networks: {
    op: {
      url: "https://opt-mainnet.g.alchemy.com/v2/TLlGxxd7yWkAUelWtVgDYS3NJayhfYxb",
      chainId: 10,
      accounts: [PRIVATE_KEY],
    },
    arb: {
      url: "https://arb-mainnet.g.alchemy.com/v2/seHW32Ypz0fNvZRFnOywR4vJlAKtzeYm",
      chainId: 42161,
      accounts: [PRIVATE_KEY],
    },
    base: {
      url: "https://base-mainnet.g.alchemy.com/v2/q7DVhQSvDKEKP7fUXp3tZdz5y3Rlm14e",
      chainId: 8453,
      accounts: [PRIVATE_KEY],
    },
    polygon: {
      url: "https://polygon-mainnet.infura.io/v3/af9927a869d34531bdef670abe98c96d",
      chainId: 137,
      accounts: [PRIVATE_KEY],
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/452d2e71262a402cbed700a198b1b9c6",
      chainId: 11155111,
      accounts: [PRIVATE_KEY],
    }
  },
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  mocha: {
    timeout: 1000000,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  contractSizer: {
    runOnCompile: true,
  },
  etherscan: {
    apiKey: {
      optimisticEthereum: OPSCAN_KEY,
      arbitrumOne: ARBSCAN_KEY,
      base: BASESCAN_KEY,
    }
  },
};

export default config;
