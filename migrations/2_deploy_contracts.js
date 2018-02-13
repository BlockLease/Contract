'use strict';

const RollingRent = artifacts.require('./RollingRent.sol');
const USDOracle = artifacts.require('./USDOracle.sol');

module.exports = function(deployer) {
  deployer.deploy(USDOracle);
  deployer.deploy(RollingRent);
};
