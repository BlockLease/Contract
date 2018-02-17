pragma solidity ^0.4.19;

interface USDOracle {
  function getPrice() external constant returns (uint);
}

contract RollingRent {

  address owner;

  address public landlord;
  address public tenant;
  address public usdOracle;

  // The cents value of rentPeriod seconds worth of rent
  uint public rentPrice = 165000;
  // February 20, 2018 00:00+00
  /* uint rentStartTime = 1519084800; */
  // 60 * 60 * 24 * 30 = 2592000 seconds = 30 days
  /* uint rentPeriod = 2592000; */

  uint public rentStartTime = 1518858300;
  uint public rentPeriod = 86400;

  uint256 public landlordBalance = 0;

  // Bailout flags for terminating the contract
  bool public landlordBailout = false;
  bool public tenantBailout = false;

  /**
   * A rolling rent system where rent is paid in advance into the contract
   **/
  function RollingRent(address _usdOracle, address _landlord, address _tenant) {
    owner = msg.sender;
    usdOracle = _usdOracle;
    landlord = _landlord;
    tenant = _tenant;
  }

  /**
   * Called by landlord, this will send the rent to the landlord address
   *
   * It can be called to collect any outstanding rent belonging to the landlord.
   **/
  function collectRent() {
    assertContractEnabled();
    require(msg.sender == landlord);

    require(landlordBalance > 1**9);
    landlord.transfer(landlordBalance);
    landlordBalance = 0;
  }

  function contractBalance() constant returns (uint256) {
    return this.balance - landlordBalance;
  }

  /**
   * Called by the tenant, money is stored in the smart contract
   **/
  function () payable {
    assertContractEnabled();
    require(msg.sender == tenant);
    require(contractBalance() + msg.value > rentWeiValue());
    landlordBalance += rentWeiValue();
  }

  /**
   * Returns the current rent price in ETH based on the GDAX exchange rate
   * stored in the USDOracle contract.
   *
   * The USDOracle contract should be updated whenever rent is being operated on.
   **/
  function rentWeiValue() constant returns (uint256) {
    return 10**18 / USDOracle(usdOracle).getPrice() * rentPrice;
  }

  /**
   * Send all money to owner address and prevent subsequent deposits
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
    require(block.timestamp > rentStartTime);
    require(contractEnabled());
  }

  /**
   * Check if either bailout condition is true
   **/
  function contractEnabled() constant returns (bool) {
    return (tenantBailout == false && landlordBailout == false);
  }

}
