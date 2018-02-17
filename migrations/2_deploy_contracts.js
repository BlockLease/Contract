'use strict';

const RollingRent = artifacts.require('RollingRent.sol');
const USDOracle = artifacts.require('USDOracle.sol');

const landlord = '0xb180cF51649691Db7864bB9f01B06ACf383Fb356';
const tenant = '0xddeC6C333538fCD3de7cfB56D6beed7Fd8dEE604';

module.exports = async function(deployer) {
  await deployer.deploy(USDOracle);
  await deployer.deploy(RollingRent, USDOracle.address, landlord, tenant);
};
