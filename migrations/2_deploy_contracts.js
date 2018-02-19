'use strict';

const Lease = artifacts.require('Lease.sol');

const landlord = '0xb180cF51649691Db7864bB9f01B06ACf383Fb356';
const tenant = '0xddeC6C333538fCD3de7cfB56D6beed7Fd8dEE604';

module.exports = async function(deployer) {
  await deployer.deploy(
    Lease,
    '0xd15c88e2c2ca6756e4fdb73b75a1d5443f6c096d', // usd oracle
    landlord,
    tenant,
    (Date.now() / 1000) + (60 * 30),
    60 * 60 * 4,
    1500,
    6
  );
};
