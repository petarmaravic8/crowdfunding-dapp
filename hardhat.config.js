require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

// /** @type import('hardhat/config').HardhatUserConfig */
// module.exports = {
//   solidity: "0.8.18",
//   paths: {
//     artifacts: "./src/artifacts",
//   },
//   networks: {
//     localganache: {
//       url: process.env.PROVIDER_URL,
//       accounts: [`0x${process.env.PRIVATE_KEY}`],
//     },
//   },
// };

//require('dotenv').config();
//require("@nomiclabs/hardhat-ethers");

const { API_URL, PRIVATE_KEY } = process.env;

module.exports = {
  solidity: "0.7.3",
  paths: {
    artifacts: "./src/artifacts",
  },

  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    sepolia: {
      url: API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
};
