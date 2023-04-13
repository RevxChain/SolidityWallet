const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {

  /*
    const provider = ethers.getDefaultProvider('NETWORK');
    const privateKey = 'PRIVATE_KEY';
    const owner = new ethers.Wallet(privateKey, provider);
    const user = owner;
  */
  const [owner, user] = await ethers.getSigners();

  const feeRate = 1337;

  const FeeValueStorage = await ethers.getContractFactory("FeeValueStorage", owner);
  const feeValueStorage = await FeeValueStorage.deploy(feeRate);
  await feeValueStorage.deployed();
  console.log(feeValueStorage.address);

  const Wallet = await ethers.getContractFactory("Wallet", owner);
  const wallet = await Wallet.deploy(user.address, owner.address, feeValueStorage.address);
  await wallet.deployed();
  console.log(wallet.address);
} 

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});