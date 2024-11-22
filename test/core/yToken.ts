import {
  deployYToken,
  MINTER_AND_REDEEMER,
  ADMIN_ROLE,
  toN,
} from "../utils";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";


// Load the utils
describe("yToken checks!", function () {
  // deploy yToken
  it("Should deploy the yToken", async function () {
    const {
      deployer,
      administrator,
      ytoken,
      usdt,
      stoken,
    }: { deployer: any; administrator: any; ytoken: any; usdt: any, stoken: any } =
      await loadFixture(deployYToken);
    expect(await administrator.hasRole(ADMIN_ROLE, deployer.address)).to.equal(
      true
    );

    expect(await stoken.usdt()).to.equal(usdt.target);
    expect(await ytoken.balanceOf(deployer.address)).to.equal(0);
    expect(await ytoken.administrator()).to.equal(administrator.target)
    expect(await ytoken.asset()).to.equal(stoken.target);

    // intialize again which should revert
    await expect(ytoken. connect(deployer).init(administrator.target, stoken.target, usdt.target)).to.be.reverted;
  });


  const mintSToken = async (stoken: any, deployer: any, administrator: any, amount: any, user: any) => {
    await administrator.connect(deployer).grantRoles(MINTER_AND_REDEEMER, [deployer.address]);
    await stoken.connect(deployer).mint(user, amount);
  };

  it("Deposit checks", async function () { 
    const {
      deployer,
      administrator,
      ytoken,
      usdt,
      stoken,
      user,
    }: { deployer: any; administrator: any; ytoken: any; usdt: any, stoken: any, user: any } =
      await loadFixture(deployYToken);

    await mintSToken(stoken, deployer, administrator, toN(100), user);
    await stoken.connect(user).approve(ytoken.target, toN(100));
    await ytoken.connect(user).deposit(toN(100), user.address);

    expect(await ytoken.balanceOf(user.address)).to.equal(toN(100)); // price of share is 1

    expect(await ytoken.totalSupply()).to.equal(toN(100));
    expect(await ytoken.totalAssets()).to.equal(toN(100));

    expect(await stoken.balanceOf(ytoken.target)).to.equal(toN(100));
  });


  it("Redeem checks", async function () {
    const {
      deployer,
      administrator,
      ytoken,
      usdt,
      stoken,
      user,
    }: {
      deployer: any;
      administrator: any;
      ytoken: any;
      usdt: any;
      stoken: any;
      user: any;
    } = await loadFixture(deployYToken);

    await mintSToken(stoken, deployer, administrator, toN(100), user);
    await stoken.connect(user).approve(ytoken.target, toN(100));
    await ytoken.connect(user).deposit(toN(100), user.address);

    expect(await ytoken.balanceOf(user.address)).to.equal(toN(100)); // price of share is 1

    expect(await ytoken.totalSupply()).to.equal(toN(100));
    expect(await ytoken.totalAssets()).to.equal(toN(100));

    expect(await stoken.balanceOf(ytoken.target)).to.equal(toN(100));


    await expect(ytoken.connect(user).redeem(toN(100), user.address, user.address)).not.to.be.reverted;

    expect(await ytoken.totalSupply()).to.equal(0);
    expect(await ytoken.totalAssets()).to.equal(0);

    expect(await stoken.balanceOf(ytoken.target)).to.equal(0);
    expect(await stoken.balanceOf(user.address)).to.equal(toN(100));

    expect(await ytoken.convertToShares(toN(100))).to.equal(toN(100));
    expect(await ytoken.exchangeRate()).to.equal(toN(1));

  });


  it("Deposit with usdt", async function () {
    const {
      deployer,
      administrator,
      ytoken,
      usdt,
      stoken,
      u1,
    }: {
      deployer: any;
      administrator: any;
      ytoken: any;
      usdt: any;
      stoken: any;
      u1: any;
    } = await loadFixture(deployYToken);


    await usdt.connect(u1).approve(ytoken.target, toN(1000, 6));
    await ytoken.connect(u1).depositUSDT(usdt.target, toN(1000, 6), u1.address);

    // allowance should be consumed
    expect(await usdt.allowance(u1.address, ytoken.target)).to.equal(0);
    expect(await usdt.balanceOf(u1.address)).to.equal(0);

    // user should have y token balance
    expect(await ytoken.balanceOf(u1.address)).to.equal(toN(1000)); // price of share is 1

    expect(await ytoken.totalSupply()).to.equal(toN(1000));
    expect(await ytoken.totalAssets()).to.equal(toN(1000));

    expect(await stoken.balanceOf(ytoken.target)).to.equal(toN(1000));

    expect(await usdt.balanceOf(ytoken.target)).to.equal(0);
    expect(await usdt.balanceOf(stoken.target)).to.equal(toN(1000, 6));

    expect(await ytoken.totalAssets()).to.equal(await stoken.balanceOf(ytoken.target));
    expect(await ytoken.totAssets()).to.equal(
      await stoken.balanceOf(ytoken.target)
    );

    expect(await ytoken.getUnvestedAmount()).to.equal(0);
  });
});
