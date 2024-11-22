import { deployYToken, toN, fromN, COLLATERAL_ROLE } from "../utils";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("MPC Checks", function () {
  it("Transfer to MPC", async function () {
    const { ytoken, stoken, user, administrator, usdt, deployer, u1 } =
      await deployYToken();

    
    const u4 = (await ethers.getSigners())[4];

    // transfer to mpc
    const m1 = (await ethers.getSigners())[6];
    const m2 = (await ethers.getSigners())[7];
    const m3 = (await ethers.getSigners())[8];

    await usdt.connect(u1).approve(ytoken.target, toN(100, 6));

    await expect(ytoken.connect(u1).depositUSDT(usdt.target, toN(100, 6), u1?.address)).not.to
      .be.reverted;

    expect(await ytoken.balanceOf(u1?.address)).to.be.equal(toN(100));
    expect(await stoken.balanceOf(ytoken?.target)).to.be.equal(toN(100));
    expect(await usdt.balanceOf(stoken?.target)).to.be.equal(toN(100, 6));

    // set the stage for mpc whitelisting
    await expect(
      stoken.connect(deployer).setMPCs([m1.address, m2.address, m3.address], true)
    ).not.to.be.reverted;

    // transfer to mpc
    await expect(
      stoken
        .connect(user)
        .transferToMPCs(
          toN(10, 6),
          [m1.address, m2.address],
          [toN(20), toN(80)]
        )
    ).to.be.revertedWith("!cmgr");

    // set the c manager for user
    await administrator
      .connect(deployer)
      .grantRoles(COLLATERAL_ROLE, [user?.address]);

    await stoken.connect(deployer).setUSDT(usdt.target);

    // transfer to mpc
    await expect(
      stoken
        .connect(user)
        .transferToMPCs(
          toN(10, 6),
          [m1.address, m2.address],
          [toN(20), toN(80)]
        )
    ).not.to.be.reverted;

    expect(await usdt.balanceOf(m1.address)).to.be.equal(toN(2, 6));
    expect(await usdt.balanceOf(m2.address)).to.be.equal(toN(8, 6));
    expect(await usdt.balanceOf(m3.address)).to.be.equal(toN(0, 6));

    expect(await ytoken.balanceOf(u1?.address)).to.be.equal(toN(100));
    expect(await stoken.balanceOf(ytoken?.target)).to.be.equal(toN(100));
  });

});
