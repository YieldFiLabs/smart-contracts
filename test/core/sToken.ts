import {
  deploySToken,
  deployYToken,
  expectArray,
  MINTER_AND_REDEEMER,
  toN,
} from "../utils";
import { ADMIN_ROLE, MANAGER_ROLE } from "../utils";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

// Load the utils
describe("sToken checks!", function () {
  // deploy sToken
  it("Should deploy the sToken", async function () {
    const {
      deployer,
      administrator,
      stoken,
      usdt,
    }: { deployer: any; administrator: any; stoken: any; usdt: any } =
      await loadFixture(deploySToken);
    expect(await administrator.hasRole(ADMIN_ROLE, deployer.address)).to.equal(
      true
    );
    expect(await stoken.usdt()).to.equal(usdt.target);
    expect(await stoken.balanceOf(deployer.address)).to.equal(0);
    expect(await stoken.administrator()).to.equal(administrator.target);

    // intialize again which should revert
    await expect(stoken.connect(deployer).init(administrator.target)).to.be
      .reverted;
  });

  // check roles
  it("Roles checks", async function () {
    const {
      deployer,
      administrator,
      stoken,
      usdt,
    }: { deployer: any; administrator: any; stoken: any; usdt: any } =
      await loadFixture(deploySToken);
    let result = await administrator.hasRoles(
      [ADMIN_ROLE, ADMIN_ROLE],
      [deployer.address, administrator.target]
    );
    expectArray(result, [true, false]);
    result = await administrator.hasRoles(
      [ADMIN_ROLE, MANAGER_ROLE],
      [deployer.address, administrator.target]
    );
    expectArray(result, [true, false]);
  });

  // Deposit check
  it("Deposit check", async function () {
    const {
      deployer,
      stoken,
      usdt,
      u1,
    }: { deployer: any; stoken: any; usdt: any; u1: any } = await loadFixture(
      deployYToken
    );

    expect(await usdt.allowance(deployer.address, stoken.target)).to.equal(0);
    expect(await usdt.allowance(u1.address, stoken.target)).to.equal(
      toN(1000, 6)
    );
    expect(await stoken.balanceOf(u1.address)).to.equal(0);

    await expect(stoken.connect(u1).deposit(toN(1000, 6), u1.address)).not.to.be
      .reverted;

    // check balances u1 stoken - 1000
    expect(await stoken.balanceOf(u1.address)).to.equal(toN(1000, 18));
    expect(await usdt.allowance(u1.address, stoken.target)).to.equal(0);
    expect(await usdt.balanceOf(u1.address)).to.equal(0);
  });

  it("Withdraw check", async function () {
    const {
      deployer,
      stoken,
      usdt,
      u1,
      receipt
    }: { deployer: any; stoken: any; usdt: any; u1: any; receipt: any } = await loadFixture(
      deployYToken
    );

    await expect(stoken.connect(u1).deposit(toN(1000, 6), u1.address)).not.to.be
      .reverted; // deposit 1000 usdt

    expect(await stoken.balanceOf(u1.address)).to.equal(toN(1000, 18));

    await stoken.connect(deployer).setCoolingPeriod(1 * 24 * 60 * 60); // 1 day as cooling period
    await expect(
      stoken.connect(u1).withdrawRequest(toN(1000, 18), u1.address, u1.address)
    ).not.to.be.reverted;

    expect(await receipt.balanceOf(u1)).to.equal(1);
    let receiptId = await receipt.tokenOfOwnerByIndex(u1.address, 0); // get receipt at 0 index
    expect(await receipt.ownerOf(receiptId)).to.equal(u1.address);

    // claim should fail with out cooldown
    await expect(stoken.connect(u1).claim(receiptId, u1.address)).to.be.revertedWith(
      "!cooling"
    );

    // wait for 3 days - claim should not fail
    await ethers.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);
    await expect(stoken.connect(u1).claim(receiptId, u1.address)).not.to.be.reverted;

    // check balances
    expect(await stoken.balanceOf(u1.address)).to.equal(0);
    expect(await usdt.allowance(u1.address, stoken.target)).to.equal(0);
    expect(await usdt.balanceOf(u1.address)).to.equal(toN(1000, 6));
  });

  it("Withdraw check - caller != owner", async function () {
    const {
      deployer,
      stoken,
      usdt,
      u1,
      receipt
    }: { deployer: any; stoken: any; usdt: any; u1: any; receipt: any } = await loadFixture(
      deployYToken
    );

    await expect(stoken.connect(u1).deposit(toN(1000, 6), u1.address)).not.to.be
      .reverted; // deposit 1000 usdt

    expect(await stoken.balanceOf(u1.address)).to.equal(toN(1000, 18));

    await stoken.connect(deployer).setCoolingPeriod(1 * 24 * 60 * 60); // 1 day as cooling period
    await expect(
      stoken
        .connect(deployer)
        .withdrawRequest(toN(1000, 18), deployer.address, u1.address)
    ).to.be.reverted; // missing allowance

    await stoken.connect(u1).approve(deployer.address, toN(1000, 18));
    expect(await stoken.allowance(u1.address, deployer.address)).to.equal(
      toN(1000, 18)
    );

    await expect(
      stoken
        .connect(deployer)
        .withdrawRequest(toN(1000, 18), deployer.address, u1.address)
    ).not.to.be.reverted;

    expect(await receipt.balanceOf(deployer)).to.equal(1);
    let receiptId = await receipt.tokenOfOwnerByIndex(deployer.address, 0); // get receipt at 0 index
    expect(await receipt.ownerOf(receiptId)).to.equal(deployer.address);

    // claim should fail with out cooldown -- Claim is only requested by the owner of NFT
    await expect(
      stoken.connect(deployer).claim(receiptId, u1.address)
    ).to.be.revertedWith("!cooling");

    // wait for 3 days - claim should not fail
    await ethers.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);
    await expect(stoken.connect(u1).claim(receiptId, u1.address)).to.be.revertedWith(
      "!owner"
    );
    await expect(stoken.connect(deployer).claim(receiptId, deployer.address)).not.to.be
      .reverted;

    // check balances
    expect(await stoken.balanceOf(u1.address)).to.equal(0);
    expect(await stoken.balanceOf(deployer.address)).to.equal(0);
    expect(await usdt.allowance(u1.address, stoken.target)).to.equal(0);

    expect(await usdt.balanceOf(u1.address)).to.equal(0); // claim goes to deployer address

    expect(await stoken.allowance(u1.address, deployer.address)).to.equal(0);
    expect(await usdt.balanceOf(deployer.address)).to.equal(toN(1000, 6)); // usdt should be delivered to deployer
  });

  it("Mint / Burn checks ", async function () {
    const {
      deployer,
      administrator,
      stoken,
    }: { deployer: any; administrator: any; stoken: any; usdt: any } =
      await loadFixture(deploySToken);

    await expect(
      stoken.connect(deployer).mint(deployer.address, toN(1000, 18))
    ).to.be.revertedWith("!minter");

    await expect(
      stoken.connect(deployer).burn(deployer.address, toN(1000, 18))
    ).to.be.revertedWith("!minter");

    // allow deployer to be minter
    await expect(
      administrator.grantRoles(MINTER_AND_REDEEMER, [deployer.address])
    ).not.to.be.reverted;

    await expect(stoken.connect(deployer).mint(deployer.address, toN(1000, 18)))
      .not.to.be.reverted;

    expect(await stoken.balanceOf(deployer.address)).to.equal(toN(1000, 18));

    await expect(stoken.connect(deployer).burn(deployer.address, toN(1000, 18)))
      .not.to.be.reverted;

    expect(await stoken.balanceOf(deployer.address)).to.equal(0);
  });
});
