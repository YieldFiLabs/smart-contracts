import { BRIDGE_ROLE, deployYToken, MINTER_AND_REDEEMER, toN } from "../utils";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";

describe("LockBox Checks", function () { 
  it("Should deploy the LockBox", async function () {
    
    const { deployer, administrator, lockbox } = await loadFixture(deployYToken);
    expect(await lockbox.administrator()).to.equal(administrator.target);
  });

  
  it("Sync checks", async function () { 

    const { deployer, administrator, lockbox, ytoken, stoken, u2 } = await loadFixture(deployYToken);
    expect(await lockbox.administrator()).to.equal(administrator.target);

    await administrator
      .connect(deployer)
      .grantRoles(MINTER_AND_REDEEMER, [lockbox.target]);

    await expect(lockbox.connect(deployer).sync(ytoken.target, 100)).to.be.revertedWith("!cmgr");
    await expect(lockbox.connect(u2).sync(ytoken.target, 100)).not.to.be.reverted;

    expect(await ytoken.balanceOf(lockbox.target)).to.equal(100);
    expect(await stoken.balanceOf(lockbox.target)).to.equal(0);
    expect(await stoken.balanceOf(ytoken.target)).to.equal(100);
  });


  it("Unlock checks", async function () {
    const { deployer, administrator, lockbox, ytoken, stoken, u2 } =
      await loadFixture(deployYToken);
    expect(await lockbox.administrator()).to.equal(administrator.target);

    await administrator
      .connect(deployer)
      .grantRoles(MINTER_AND_REDEEMER, [lockbox.target]);

    await expect(lockbox.connect(u2).sync(ytoken.target, 100)).not.to.be
      .reverted;
    
    await administrator.grantRoles(BRIDGE_ROLE, [deployer.address]);

    await expect(lockbox.connect(deployer).unlock(ytoken.target, u2.address, 100)).not.to.be.reverted;

    expect(await ytoken.balanceOf(lockbox.target)).to.equal(0);
    expect(await stoken.balanceOf(ytoken.target)).to.equal(100);
    expect(await ytoken.balanceOf(u2.address)).to.equal(100);
  });
});