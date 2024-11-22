import {
  deployYToken,
  MINTER_AND_REDEEMER,
  ADMIN_ROLE,
  toN,
  fromN,
} from "../utils";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
export const REWARD_HASH = ethers.keccak256(ethers.toUtf8Bytes("REWARD"));

// Yield checks
describe("Yield checks!", function () {
  it("Should deploy the yield", async function () {
    const {
      deployer,
      administrator,
      ytoken,
      usdt,
      stoken,
      yld,
      user,
      u2,
    }: {
      deployer: any;
      administrator: any;
      ytoken: any;
      usdt: any;
      stoken: any;
      yld: any;
      user: any;
      u2: any;
    } = await loadFixture(deployYToken);
    expect(await yld.administrator()).to.equal(administrator.target);
  });

  it("+ Yield checks", async function () {
    const {
      deployer,
      administrator,
      ytoken,
      usdt,
      stoken,
      yld,
      user,
      u2,
    }: {
      deployer: any;
      administrator: any;
      ytoken: any;
      usdt: any;
      stoken: any;
      yld: any;
      user: any;
      u2: any;
    } = await loadFixture(deployYToken);

    await administrator.grantRoles(MINTER_AND_REDEEMER, [deployer.address]);

    await stoken.connect(deployer).mint(user.address, toN(100)); // mint sToken for the user
    await stoken.connect(user).approve(ytoken.target, toN(100));
    await ytoken.connect(user).deposit(toN(100), user.address); // deposit to yToken

    await stoken.connect(deployer).mint(yld.target, toN(80)); // mint sToken for the yld to simulate yield

    expect(await stoken.balanceOf(yld.target)).to.equal(toN(80)); // Yield deposited

    let abi = new ethers.AbiCoder().encode(
      ["address", "uint256", "uint256", "uint256", "bytes32"],
      [ytoken.target, toN(80), 1, 1, REWARD_HASH]
    );

    let sign = await u2.signMessage(ethers.toBeArray(ethers.keccak256(abi)));

    await expect(yld.connect(user).distributeYield(abi, sign)).not.to.be
      .reverted;

    expect(await ytoken.exchangeRate()).to.equal(toN(1));

    // increase evm time by an hour
    await ethers.provider.send("evm_increaseTime", [3600]);
    await stoken.connect(deployer).mint(yld.target, 1); // dummy transaction to to mint new block at new timestamp

    expect(await ytoken.exchangeRate()).to.equal(toN(1.1));

    // increase evm time by an 7 hour
    // await ethers.provider.send("evm_increaseTime", [7 * 3600]);
    await ethers.provider.send("evm_increaseTime", [7 * 60 * 60]);
    await stoken.connect(deployer).mint(yld.target, 1); // dummy transaction to to mint new block at new timestamp

    expect(await ytoken.exchangeRate()).to.equal(toN("1.8"));

    await stoken.connect(deployer).mint(user.address, toN(100));
    await stoken.connect(user).approve(ytoken.target, toN(100));
    await ytoken.connect(user).deposit(toN(100), user.address); // deposit to yToken

    expect(await stoken.balanceOf(yld.target)).to.equal(2);
    expect(await stoken.balanceOf(ytoken.target)).to.equal(toN(280)); // 100 + 100 + 80 (yield)
    expect(await stoken.balanceOf(user.address)).to.equal(0); // transfered everything
    expect(fromN(await ytoken.balanceOf(user.address)).toFixed(2)).to.equal(
      "155.56"
    ); // ytoken balance 100 + 100/1.8

    await ytoken.connect(user).redeem(toN(100), user.address, user.address);

    expect(await stoken.balanceOf(yld.target)).to.equal(2);
    expect(await stoken.balanceOf(ytoken.target)).to.equal(toN(100)); // 280 - 100 * 1.8 = 100
    expect(await stoken.balanceOf(user.address)).to.equal(toN(180));
    expect(fromN(await ytoken.balanceOf(user.address)).toFixed(2)).to.equal(
      "55.56"
    );
  });

  it("- Yield checks", async function () {
    const {
      deployer,
      administrator,
      ytoken,
      usdt,
      stoken,
      yld,
      user,
      u2,
    }: {
      deployer: any;
      administrator: any;
      ytoken: any;
      usdt: any;
      stoken: any;
      yld: any;
      user: any;
      u2: any;
    } = await loadFixture(deployYToken);

    await administrator.grantRoles(MINTER_AND_REDEEMER, [deployer.address]);

    await stoken.connect(deployer).mint(user.address, toN(100)); // mint sToken for the user
    await stoken.connect(user).approve(ytoken.target, toN(100));
    await ytoken.connect(user).deposit(toN(100), user.address); // deposit to yToken

    await stoken.connect(deployer).mint(yld.target, toN(80)); // mint sToken for the yld to simulate yield

    expect(await stoken.balanceOf(yld.target)).to.equal(toN(80)); // Yield deposited

    let abi = new ethers.AbiCoder().encode(
      ["address", "uint256", "uint256", "uint256", "bytes32"],
      [ytoken.target, toN(80), 1, 0, REWARD_HASH]
    );

    let sign = await u2.signMessage(ethers.toBeArray(ethers.keccak256(abi)));

    await administrator.grantRoles(MINTER_AND_REDEEMER, [yld.target]);
    await expect(yld.connect(user).distributeYield(abi, sign)).not.to.be
      .reverted;

    expect(fromN(await ytoken.exchangeRate()).toFixed(2)).to.equal("0.20");

    // increase evm time by an hour
    await ethers.provider.send("evm_increaseTime", [3600]);
    await stoken.connect(deployer).mint(yld.target, 1); // dummy transaction to to mint new block at new timestamp

    expect(fromN(await ytoken.exchangeRate()).toFixed(2)).to.equal("0.20"); // - yield should be done at the time of burn

    // increase evm time by an 7 hour
    // await ethers.provider.send("evm_increaseTime", [7 * 3600]);
    await ethers.provider.send("evm_increaseTime", [7 * 60 * 60]);
    await stoken.connect(deployer).mint(yld.target, 1); // dummy transaction to to mint new block at new timestamp

    expect(fromN(await ytoken.exchangeRate()).toFixed(2)).to.equal("0.20");

    await stoken.connect(deployer).mint(user.address, toN(100));
    await stoken.connect(user).approve(ytoken.target, toN(100));
    await ytoken.connect(user).deposit(toN(100), user.address); // deposit to yToken

    expect(fromN(await stoken.balanceOf(yld.target)).toFixed(2)).to.equal(
      "80.00"
    );
    expect(await stoken.balanceOf(ytoken.target)).to.equal(toN(120)); // 100 + 100 + 80 (yield)
    expect(await stoken.balanceOf(user.address)).to.equal(0); // transfered everything
    expect(fromN(await ytoken.balanceOf(user.address)).toFixed(2)).to.equal(
      "600.00"
    ); // ytoken balance 100 + 100/0.2

    await ytoken.connect(user).redeem(toN(100), user.address, user.address);

    expect(fromN(await stoken.balanceOf(yld.target)).toFixed(2)).to.equal(
      "80.00"
    );
    expect(await stoken.balanceOf(ytoken.target)).to.equal(toN(100)); // 120 - 100 * 0.2 = 100
    expect(await stoken.balanceOf(user.address)).to.equal(toN(20));
    expect(fromN(await ytoken.balanceOf(user.address)).toFixed(2)).to.equal(
      "500.00"
    );
  });

  it("+ Yield checks /  donation attack", async function () {
    const {
      deployer,
      administrator,
      ytoken,
      usdt,
      stoken,
      yld,
      user,
      u2,
    }: {
      deployer: any;
      administrator: any;
      ytoken: any;
      usdt: any;
      stoken: any;
      yld: any;
      user: any;
      u2: any;
    } = await loadFixture(deployYToken);

    await administrator.grantRoles(MINTER_AND_REDEEMER, [deployer.address]);

    await stoken.connect(deployer).mint(ytoken.target, toN(80)); // mint sToken for the yld to simulate donation attack

    await stoken.connect(deployer).mint(user.address, toN(100)); // mint sToken for the user
    await stoken.connect(user).approve(ytoken.target, toN(100));
    await ytoken.connect(user).deposit(toN(100), user.address); // deposit to yToken

    await stoken.connect(deployer).mint(yld.target, toN(80)); // mint sToken for the yld to simulate yield

    expect(await stoken.balanceOf(yld.target)).to.equal(toN(80)); // Yield deposited

    let abi = new ethers.AbiCoder().encode(
      ["address", "uint256", "uint256", "uint256", "bytes32"],
      [ytoken.target, toN(80), 1, 1, REWARD_HASH]
    );

    let sign = await u2.signMessage(ethers.toBeArray(ethers.keccak256(abi)));

    await expect(yld.connect(user).distributeYield(abi, sign)).not.to.be
      .reverted;

    // Also do a donation attack - it should not affect

    expect(await ytoken.exchangeRate()).to.equal(toN(1));

    // increase evm time by an hour
    await ethers.provider.send("evm_increaseTime", [3600]);
    await stoken.connect(deployer).mint(yld.target, 1); // dummy transaction to to mint new block at new timestamp

    expect(await ytoken.exchangeRate()).to.equal(toN(1.1));

    // increase evm time by an 7 hour
    // await ethers.provider.send("evm_increaseTime", [7 * 3600]);
    await ethers.provider.send("evm_increaseTime", [7 * 60 * 60]);
    await stoken.connect(deployer).mint(yld.target, 1); // dummy transaction to to mint new block at new timestamp

    expect(await ytoken.exchangeRate()).to.equal(toN("1.8"));

    await stoken.connect(deployer).mint(user.address, toN(100));
    await stoken.connect(user).approve(ytoken.target, toN(100));
    await ytoken.connect(user).deposit(toN(100), user.address); // deposit to yToken

    expect(await stoken.balanceOf(yld.target)).to.equal(2);
    expect(await stoken.balanceOf(ytoken.target)).to.equal(toN(360)); // 100 + 100 + 80 (yield) + 80 (donation)
    expect(await stoken.balanceOf(user.address)).to.equal(0); // transfered everything
    expect(fromN(await ytoken.balanceOf(user.address)).toFixed(2)).to.equal(
      "155.56"
    ); // ytoken balance 100 + 100/1.8

    await ytoken.connect(user).redeem(toN(100), user.address, user.address);

    expect(await stoken.balanceOf(yld.target)).to.equal(2);
    expect(await stoken.balanceOf(ytoken.target)).to.equal(toN(180)); // 280 - 100 * 1.8 = 100 + 80 (donation)
    expect(await stoken.balanceOf(user.address)).to.equal(toN(180));
    expect(fromN(await ytoken.balanceOf(user.address)).toFixed(2)).to.equal(
      "55.56"
    );
  });
});
