import {
  deploySTokenL2,
  deployYTokenL2,
  expectArray,
  MINTER_AND_REDEEMER,
  toN,
} from "../utils";
import { ADMIN_ROLE, MANAGER_ROLE } from "../utils";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

// Load the utils
describe("sTokenL2 checks!", function () {
  // deploy sToken
  it("Should deploy the sTokenL2", async function () {
    const {
      deployer,
      administrator,
      stokenL2,
      usdt,
    }: { deployer: any; administrator: any; stokenL2: any; usdt: any } =
      await loadFixture(deploySTokenL2);
    expect(await administrator.hasRole(ADMIN_ROLE, deployer.address)).to.equal(
      true
    );
    expect(await stokenL2.usdt()).to.equal(usdt.target);
    expect(await stokenL2.balanceOf(deployer.address)).to.equal(0);
    expect(await stokenL2.administrator()).to.equal(administrator.target);

    // intialize again which should revert
    await expect(stokenL2.connect(deployer).init(administrator.target)).to.be
      .reverted;
  });

  // check roles
  it("Roles checks", async function () {
    const {
      deployer,
      administrator,
      stokenL2,
      usdt,
    }: { deployer: any; administrator: any; stokenL2: any; usdt: any } =
      await loadFixture(deploySTokenL2);
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
      stokenL2,
      usdt,
      u1,
    }: { deployer: any; stokenL2: any; usdt: any; u1: any } = await loadFixture(
      deployYTokenL2
    );

    expect(await usdt.allowance(deployer.address, stokenL2.target)).to.equal(0);
    expect(await usdt.allowance(u1.address, stokenL2.target)).to.equal(
      toN(1000, 6)
    );
    expect(await stokenL2.balanceOf(u1.address)).to.equal(0);

    await expect(stokenL2.connect(u1).deposit(toN(1000, 6), u1.address)).not.to
      .be.reverted;

    // check balances u1 stokenL2 - 1000
    expect(await stokenL2.balanceOf(u1.address)).to.equal(toN(1000, 18));
    expect(await usdt.allowance(u1.address, stokenL2.target)).to.equal(0);
    expect(await usdt.balanceOf(u1.address)).to.equal(0);
  });
});
