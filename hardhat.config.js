require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.17",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    goerli: {
      url: "https://goerli.blockpi.network/v1/rpc/public",
      chainId: 5, 
    },
    mainnet: {
      url: "https://rpc.mevblocker.io",
      chainId: 1, 
    },
  },
}
