const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("FeeValueStorage", function () {
  async function deployFeeValueStorageFixture() {
    const baseFeeRate = 0;

    const [owner, user] = await ethers.getSigners();

    const FeeValueStorage = await ethers.getContractFactory("FeeValueStorage", owner);
    const feeValueStorage = await FeeValueStorage.deploy(baseFeeRate);
    await feeValueStorage.deployed();

    const feeValueStorageAddress = feeValueStorage.address;

    return { feeValueStorage, baseFeeRate, owner, user };
  }

  describe("Deployment", function () {
    it("Should set the right feeRate", async function () {
      const { feeValueStorage, baseFeeRate } = await loadFixture(deployFeeValueStorageFixture);

      await expect(await feeValueStorage.feeRate()).to.equal(baseFeeRate);
    });

    it("Should set the right owner", async function () {
      const { feeValueStorage, owner } = await loadFixture(deployFeeValueStorageFixture);

      expect(await feeValueStorage.owner()).to.equal(owner.address);
    });

    it("Should setFeeRate function reverted by not an owner", async function () {
      const { feeValueStorage, user } = await loadFixture(
        deployFeeValueStorageFixture
      );

      await expect(feeValueStorage.connect(user).setNewFeeRate(0)).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });
    
    it("Should setFeeRate function succeed by owner", async function () {
      const { feeValueStorage, owner, baseFeeRate } = await loadFixture(
        deployFeeValueStorageFixture
      );

      const newFeeRate = 1337;

      await feeValueStorage.connect(owner).setNewFeeRate(newFeeRate);

      await expect(await feeValueStorage.feeRate()).to.equal(newFeeRate);
    });

    it("Should setFeeRate function reverted by wrong value", async function () {
      const { feeValueStorage, owner, baseFeeRate } = await loadFixture(
        deployFeeValueStorageFixture
      );

      const newFeeRate = 10001;

      await expect(feeValueStorage.connect(owner).setNewFeeRate(newFeeRate)).to.be.revertedWith(
        "FeeValueStorage: Invalid value"
      );
    });
  });
});
