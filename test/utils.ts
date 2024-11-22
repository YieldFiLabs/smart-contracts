import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { upgrades } from "hardhat";
import { expect } from "chai";

export function toN(n: any, d = 18) {
  return ethers.parseUnits(n.toString(), d);
}

export function fromN(n: any, d = 18) {
  return Number(Number(ethers.formatUnits(n, d)).toFixed(2));
}

export const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("ADMIN"));
export const MINTER_AND_REDEEMER = ethers.keccak256(
  ethers.toUtf8Bytes("MINTER_AND_REDEEMER")
);
export const COLLATERAL_ROLE = ethers.keccak256(
  ethers.toUtf8Bytes("COLLATERAL_MANAGER")
);
export const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MANAGER"));
export const REWARDER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("REWARDER"));
export const SIGNER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("SIGNER"));
export const BRIDGE_ROLE = ethers.keccak256(ethers.toUtf8Bytes("BRIDGE"));

export async function deployAsset(
  symbol: string = "USDT",
  decimals: number = 6,
  administrator: any
) {
  const Asset = await ethers.getContractFactory("Token");
  const usdt = await upgrades.deployProxy(
    Asset,
    [symbol + " Token", symbol, decimals, administrator],
    { initializer: "init" }
  );

  return usdt;
}

export async function deployAdmin() {
  const [deployer, user] = await ethers.getSigners();

  const Administrator = await ethers.getContractFactory("Administrator");
  const administrator = await upgrades.deployProxy(
    Administrator,
    [deployer.address],
    { initializer: "init" }
  );
  await administrator.waitForDeployment();
  const usdt = await deployAsset("USDT", 6, administrator.target);
  return { deployer, user, administrator, usdt };
}

export async function deploySToken() {
  const { deployer, user, administrator, usdt } = await loadFixture(
    deployAdmin
  );

  const SToken = await ethers.getContractFactory("SToken");
  const stoken = await upgrades.deployProxy(SToken, [administrator.target], {
    initializer: "init",
  });
  await stoken.waitForDeployment();

  const Receipt = await ethers.getContractFactory("Receipt");
  const receipt = await upgrades.deployProxy(Receipt, [administrator.target], {
    initializer: "init",
  });
  await receipt.waitForDeployment();

  await receipt.setSToken(stoken.target); // withdraw receipt
  await stoken.setUSDT(usdt.target);
  await stoken.setWithdrawReceipt(receipt.target);

  return { deployer, user, administrator, usdt, stoken , receipt};
}

export async function deployYToken() {
  const { deployer, user, administrator, usdt, stoken, receipt } = await loadFixture(
    deploySToken
  );

  const Yield = await ethers.getContractFactory("Yield");
  const yld = await upgrades.deployProxy(Yield, [administrator.target], {
    initializer: "init",
  });

  const YToken = await ethers.getContractFactory("YToken");
  const ytoken = await upgrades.deployProxy(
    YToken,
    [administrator.target, stoken.target, yld.target],
    { initializer: "init" }
  );
  await ytoken.waitForDeployment();

  const LockBox = await ethers.getContractFactory("LockBox");
  const lockbox = await upgrades.deployProxy(LockBox, [administrator.target], {
    initializer: "init",
  });
  await lockbox.waitForDeployment();

  // set roles to ytoken
  await administrator.grantRoles(MINTER_AND_REDEEMER, [
    deployer.address,
    ytoken.target,
  ]);

  // set rewarder role to user
  await administrator.grantRoles(REWARDER_ROLE, [user.address]);

  const u1 = (await ethers.getSigners())[3];
  const u2 = (await ethers.getSigners())[10];

  await administrator.grantRoles(COLLATERAL_ROLE, [u2.address]);

  // set SIGNER role to u2
  await administrator.grantRoles(SIGNER_ROLE, [u2.address]);

  await usdt.mint(u1.address, toN(1000, 6));
  await usdt.connect(u1).approve(stoken.target, toN(1000, 6));

  return { deployer, user, administrator, usdt, stoken, ytoken, u1, u2, yld, lockbox, receipt };
}

export async function deploySTokenL2() {
  const { deployer, user, administrator, usdt } = await loadFixture(
    deployAdmin
  );

  const STokenL2 = await ethers.getContractFactory("STokenL2");
  const stokenL2 = await upgrades.deployProxy(
    STokenL2,
    [administrator.target],
    {
      initializer: "init",
    }
  );
  await stokenL2.waitForDeployment();

  await stokenL2.setUSDT(usdt.target);

  return { deployer, user, administrator, usdt, stokenL2 };
}

export async function deployYTokenL2() {
  const { deployer, user, administrator, usdt, stokenL2 } = await loadFixture(
    deploySTokenL2
  );

  const Oracle = await ethers.getContractFactory("Oracle");
  const oracle = await upgrades.deployProxy(Oracle, [administrator.target], {
    initializer: "init",
  });
  const YTokenL2 = await ethers.getContractFactory("YTokenL2");
  const ytokenL2 = await upgrades.deployProxy(
    YTokenL2,
    [administrator.target, oracle.target, stokenL2.target],
    { initializer: "init" }
  );
  await ytokenL2.waitForDeployment();

  await oracle.setPrice(ytokenL2.target, toN(1));

  // set roles to ytoken
  await administrator.grantRoles(MINTER_AND_REDEEMER, [
    deployer.address,
    ytokenL2.target,
  ]);

  // set rewarder role to user
  await administrator.grantRoles(REWARDER_ROLE, [user.address]);

  const u1 = (await ethers.getSigners())[3];
  const u2 = (await ethers.getSigners())[10];

  // set SIGNER role to u2
  await administrator.grantRoles(SIGNER_ROLE, [u2.address]);

  await usdt.mint(u1.address, toN(1000, 6));
  await usdt.connect(u1).approve(stokenL2.target, toN(1000, 6));

  return {
    deployer,
    user,
    administrator,
    usdt,
    stokenL2,
    ytokenL2,
    u1,
    u2,
    oracle
  };
}

export async function expectArray(result: any[], expected: any[]) {
  expect(result.length).to.equal(expected.length);
  for (let i = 0; i < result.length; i++) {
    expect(result[i]).to.equal(expected[i]);
  }
}

export async function encodeABI(signer: any, types: any[], args: any[]) {
  expect(types.length).to.equal(args.length);
  let abi = new ethers.AbiCoder().encode(types, args);
  let sign = await signer.signMessage("" + ethers.keccak256(abi));
  console.log("wallet: ", "");
  return { abi, sign };
}

export function uuid() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

export async function getChainId() {
  return (await ethers.provider.getNetwork()).chainId;
}
