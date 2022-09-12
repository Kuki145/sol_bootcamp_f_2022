require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.16",
  defaultNetwork: "goerli",
  networks: {
    goerli: {
      url: "https://ethereum-goerli-rpc.allthatnode.com",
      accounts: [process.env.PK_DEV],
    },
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY
    }
  },
};
