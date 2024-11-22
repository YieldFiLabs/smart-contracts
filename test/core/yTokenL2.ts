import { deployYTokenL2, MINTER_AND_REDEEMER, ADMIN_ROLE, toN } from "../utils";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";

// Load the utils
describe("yTokenL2 checks!", function () {
  // deploy yToken
  it("Should deploy the yTokenL2", async function () {
    const {
      deployer,
      administrator,
      ytokenL2,
      usdt,
      stokenL2,
      oracle,
    }: {
      deployer: any;
      administrator: any;
      ytokenL2: any;
      usdt: any;
      stokenL2: any;
      oracle: any;
    } = await loadFixture(deployYTokenL2);
    expect(await administrator.hasRole(ADMIN_ROLE, deployer.address)).to.equal(
      true
    );

    expect(await stokenL2.usdt()).to.equal(usdt.target);
    expect(await ytokenL2.balanceOf(deployer.address)).to.equal(0);
    expect(await ytokenL2.administrator()).to.equal(administrator.target);
    expect(await ytokenL2.sToken()).to.equal(stokenL2.target);
    expect(await ytokenL2.oracle()).to.equal(oracle.target);

    // intialize again which should revert
    await expect(
      ytokenL2
        .connect(deployer)
        .init(administrator.target, oracle.target, stokenL2.target)
    ).to.be.reverted;
  });

  const mintSTokenL2 = async (
    stokenL2: any,
    deployer: any,
    administrator: any,
    amount: any,
    user: any
  ) => {
    await administrator
      .connect(deployer)
      .grantRoles(MINTER_AND_REDEEMER, [deployer.address]);
    await stokenL2.connect(deployer).mint(user, amount);
  };

  it("Deposit checks", async function () {
    const {
      deployer,
      administrator,
      ytokenL2,
      usdt,
      stokenL2,
      user,
      oracle,
    }: {
      deployer: any;
      administrator: any;
      ytokenL2: any;
      usdt: any;
      stokenL2: any;
      user: any;
      oracle: any;
    } = await loadFixture(deployYTokenL2);

    expect(await oracle.getPrice(ytokenL2.target)).to.equal(toN(1));

    await mintSTokenL2(stokenL2, deployer, administrator, toN(100), user);
    await stokenL2.connect(user).approve(ytokenL2.target, toN(100));
    await ytokenL2
      .connect(user)
      .deposit(stokenL2.target, toN(100), user.address);

    expect(await ytokenL2.balanceOf(user.address)).to.equal(toN(100)); // price of share is 1

    expect(await ytokenL2.totalSupply()).to.equal(toN(100));

    expect(await stokenL2.balanceOf(ytokenL2.target)).to.equal(toN(0));
  });

  it("Withdraw checks", async function () {
    const {
      deployer,
      administrator,
      ytokenL2,
      usdt,
      stokenL2,
      user,
    }: {
      deployer: any;
      administrator: any;
      ytokenL2: any;
      usdt: any;
      stokenL2: any;
      user: any;
    } = await loadFixture(deployYTokenL2);

    await mintSTokenL2(stokenL2, deployer, administrator, toN(100), user);
    await stokenL2.connect(user).approve(ytokenL2.target, toN(100));
    await ytokenL2
      .connect(user)
      .deposit(stokenL2.target, toN(100), user.address);

    expect(await ytokenL2.balanceOf(user.address)).to.equal(toN(100)); // price of share is 1

    expect(await ytokenL2.totalSupply()).to.equal(toN(100));

    expect(await stokenL2.balanceOf(ytokenL2.target)).to.equal(toN(0));

    await expect(
      ytokenL2.connect(user).withdraw(toN(100), user.address, user.address)
    ).not.to.be.reverted;

    expect(await ytokenL2.totalSupply()).to.equal(0);

    expect(await stokenL2.balanceOf(ytokenL2.target)).to.equal(0);
    expect(await stokenL2.balanceOf(user.address)).to.equal(toN(100));
  });

  it("Deposit with usdt", async function () {
    const {
      deployer,
      administrator,
      ytokenL2,
      usdt,
      stokenL2,
      u1,
    }: {
      deployer: any;
      administrator: any;
      ytokenL2: any;
      usdt: any;
      stokenL2: any;
      u1: any;
    } = await loadFixture(deployYTokenL2);

    await usdt.connect(u1).approve(ytokenL2.target, toN(1000, 6));
    await ytokenL2.connect(u1).deposit(usdt.target, toN(1000, 6), u1.address);

    // allowance should be consumed
    expect(await usdt.allowance(u1.address, ytokenL2.target)).to.equal(0);
    expect(await usdt.balanceOf(u1.address)).to.equal(0);

    // user should have yToken balance
    expect(await ytokenL2.sToken()).to.equal(stokenL2.target);
    expect(await stokenL2.usdt()).to.equal(usdt.target);

    expect(await ytokenL2.balanceOf(u1.address)).to.equal(toN(1000)); // price of share is 1

    expect(await ytokenL2.totalSupply()).to.equal(toN(1000));

    expect(await stokenL2.balanceOf(ytokenL2.target)).to.equal(toN(0));

    expect(await usdt.balanceOf(ytokenL2.target)).to.equal(0);
    expect(await usdt.balanceOf(stokenL2.target)).to.equal(toN(1000, 6));
  });
});
