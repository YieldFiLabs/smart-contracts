import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-contract-sizer";
import "@nomicfoundation/hardhat-verify";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";

import { config as dotenvConfig } from "dotenv";

dotenvConfig();

const config: HardhatUserConfig = {
  solidity: "0.8.24",

  // Compiler optimization
  settings: { optimizer: { enabled: true, runs: 200 } },

  // Networks
  networks: {
    arb: {
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      chainId: 421614,
      accounts: process.env.DEPLOYER_PVT_KEY
        ? [process.env.DEPLOYER_PVT_KEY]
        : [],
    },
    op: {
      url: "https://sepolia.optimism.io",
      chainId: 11155420,
      accounts: process.env.DEPLOYER_PVT_KEY
        ? [process.env.DEPLOYER_PVT_KEY]
        : [],
    },
    eth: {
      url: "https://eth-sepolia.public.blastapi.io",
      chainId: 11155111,
      accounts: process.env.DEPLOYER_PVT_KEY
        ? [process.env.DEPLOYER_PVT_KEY]
        : [],
    },
    arbMain: {
      url: "https://arb1.arbitrum.io/rpc",
      chainId: 42161,
      accounts: process.env.PROD_PVT_KEY ? [process.env.PROD_PVT_KEY] : [],
    },
    ethMain: {
      url: "https://eth.llamarpc.com",
      chainId: 1,
      accounts: process.env.PROD_PVT_KEY ? [process.env.PROD_PVT_KEY] : [],
    },
    nile: {
      url: "https://api.nileex.io",
      accounts: process.env.TRON_PVT_KEY ? [process.env.TRON_PVT_KEY] : [],
      httpHeaders: {
        "TRON-PRO-API-KEY": process.env.TRON_PRO_API_KEY
          ? process.env.TRON_PRO_API_KEY
          : "",
      },
      tron: true,
    },
  },

  // Gas reporting
  gasReporter: {
    enabled: true,
    currency: "USD",
    noColors: false,
  },

  // Source verification
  sourcify: {
    enabled: true,
  },

  // Contract sizing this is must, EVM has a contract size limit of 24kB
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    unit: "kB",
  },

  etherscan: {
    apiKey: {
      arbitrumOne: process.env.ARB_SCAN_KEY ? process.env.ARB_SCAN_KEY : "",
      arbitrumSepolia: process.env.ARB_SCAN_KEY ? process.env.ARB_SCAN_KEY : "",
      mainnet: process.env.ETH_SCAN_KEY ? process.env.ETH_SCAN_KEY : "",
      opsepolia: process.env.OP_SCAN_KEY ? process.env.OP_SCAN_KEY : "",
      sepolia: process.env.ETH_SCAN_KEY ? process.env.ETH_SCAN_KEY : "",
    },

    customChains: [
      {
        network: "opsepolia",
        chainId: 11155420,
        urls: {
          apiURL: "https://api-sepolia-optimistic.etherscan.io/api",
          browserURL: "https://sepolia-optimism.etherscan.io/",
        },
      },
    ],
  },

  // Tron network configuration
  tronSolc: {
    enable: true,
    // Optional: specify an array of contract filenames (without path) to selectively compile. Leave as empty array to compile all contracts.
    filter: [],
    compilers: [{ version: "0.7.7" }, { version: "0.8.20" }], // can be any tron-solc version
    // Optional: Define version remappings for compiler versions
    versionRemapping: [
      ["0.7.7", "0.7.6"], // Remap version "0.7.7" to "0.7.6"
      ["0.8.22", "0.8.20"], // Remap version "0.8.20" to "0.8.19"
    ],
  },
};

export default config;
