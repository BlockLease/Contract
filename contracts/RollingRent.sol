pragma solidity ^0.4.4;

import './USDOracle.sol';

contract RollingRent {

  address owner;

  address landlord;
  address tenant;

  uint lastRentBlock;
  uint rentBlockRate;

  // The cents value of 2592000 seconds (30 days) worth of rent
  uint rentPrice = 165000;
  // February 20, 2018 00:00+00
  uint rentStartTime = 1519084800;
  // 60 * 60 * 24 * 30 = 2592000 seconds = 30 days
  uint rentPeriod = 2592000;

  uint periodsPaidOut = 0;

  bool landlordBailout = false;
  bool tenantBailout = false;

  /**
   * A rolling rent system where rent is paid a total of 2 months in advance
   **/
  function RollingRent() {
    owner = msg.sender;
  }

  /**
   * Called by landlord, this will send the rent to the landlord address
   *
   * It can be called to collect any outstanding rent belonging to the landlord.
   **/
  function collectRent() {
    assertContractEnabled();
    require(msg.sender == landlord);
    // Rent can be collected anytime after the beginning of the month
    require(block.timestamp > periodsPaidOut * rentPeriod + rentStartTime);
    // Rent is sent to the landlord address
    landlord.transfer(rentEthValue());
    periodsPaidOut++;
  }

  /**
   * Called by the tenant, money is stored in the smart contract
   **/
  function payRent() payable {
    assertContractEnabled();
    require(msg.sender == tenant);
    require(msg.value >= rentEthValue());
  }

  /**
   * Returns the current rent price in ETH based on the GDAX exchange rate
   * stored in the USDOracle contract.
   *
   * The USDOracle contract should be updated whenever rent is being operated on.
   **/
  function rentEthValue() returns (uint) {
    return rentPrice / USDOracle.getPrice();
  }

  /**
   * Send all money to owner address and prevent subsequant deposits
   *
   * Must be called by landlord _and_ tenant in two separate transactions
   *
   * Once both have called it either the tenant or the landlord can call this
   * function and release money from the contract to the owner. Subsequent calls
   * to functions will fail when either of the bailout flags are true.
   **/
  function bailout() {
    require(msg.sender == landlord || msg.sender == tenant);
    if (msg.sender == landlord) {
      landlordBailout = true;
    } else if (msg.sender == tenant) {
      tenantBailout = true;
    }

    if (tenantBailout && landlordBailout) {
      owner.transfer(this.balance);
    }
  }

  /**
   * Throw if bailout conditions are true
   **/
  function assertContractEnabled() {
    require(contractEnabled());
  }

  /**
   * Check if either bailout condition is true
   **/
  function contractEnabled() returns (bool) {
    return (tenantBailout == false && landlordBailout == false);
  }

}
