pragma solidity ^0.4.19;

interface USDOracle {
  function getPrice() external constant returns (uint);
  function priceNeedsUpdate() external constant returns (bool);
  function usdToWei(uint usd) external constant returns (uint256);
}

contract Lease {

  address public landlord;
  address public tenant;

  mapping (address => uint) public balancesWei;

  uint public collateralUsd;
  uint public rentPerDayUsd;

  uint public totalRentPaidWei;
  uint public totalRentOwedWei;

  /**
   * The minimum number of days that must be paid for during the contract
   *
   * This can be 0
   **/
  uint public minimumDays;

  /**
   * Days of notice that must be supplied before termination by either party
   *
   * This can be 0
   **/
  uint public terminationDays;

  uint public leaseStartTimestamp;
  uint public leaseEndTimestamp;

  address public usdOracle;

  bool public terminated;

  function Lease(
    uint _collateralUsd,
    uint _rentPerDayUsd,
    uint _minimumDays
  ) public {
    landlord = msg.sender;
    collateralUsd = _collateralUsd;
    rentPerDayUsd = _rentPerDayUsd;
  }

  /**
   * Deposit wei into the contract balance.
   *
   * This will be used for rent and collateral payments.
   **/
  function deposit() public payable {
    balancesWei[msg.sender] += msg.value;
  }

  function withdraw(uint amount) public {
    require(amount >= 0);
    require(balancesWei[msg.sender] >= amount);
    balancesWei[msg.sender] -= amount;
    msg.sender.transfer(balancesWei[msg.sender]);
  }

  function balanceSend(address sender, address receiver, uint amount) public {
    require(balancesWei[sender] >= amount);
    require(this.balance >= amount;)
    balancesWei[sender] -= amount;
    balancesWei[receiver] += amount;
  }

  /**
   * Called to begin the rental contract
   *
   * Must send collateral and first month of rent
   **/
  function rent() payable returns (bool) {
    require(!leaseIsActive());
    require(msg.value >= collateralWei());
    tenant = msg.sender;
    leaseStartTimestamp = block.timestamp;
    balancesWei[tenant] += msg.value;
    return true;
  }

  /**
   * Pay the landlord from the tenant balance the termination cost as well as
   * the early termination fee (if necessary)
   **/
  function tenantTermination() private {
    uint earlyTerminationFeeWei = minimumDaysPassed() ? 0 : collateralWei();
    uint terminationCostWei = terminateWei() + earlyTerminationFeeWei;
    balanceSend(tenant, landlord, terminationCostWei);
  }

  function landlordTermination() private {
    uint earlyTerminationFeeWei = minimumDaysPassed() ? 0 : collateralWei();
    uint tenantCost = terminationWei();
    uint landlordCost = earlyTerminationFeeWei;

    if (!minimumDaysPassed()) {
      balanceSend(landlord, tenant, collateralWei());
    }
    balanceSend(tenant, landlord, tenantCost);
  }

  function terminate() public {
    require(leaseIsActive());
    require(msg.sender == tenant || msg.sender == landlord);
    if (msg.sender == tenant) {
      tenantTermination();
    } else {
      landlordTermination();
    }
    leaseEndTimestamp = block.timestamp + daysToSeconds(terminationDays);
    terminated = true;
  }

  function leaseIsActive() public constant (bool) {
    return tenant == 0x0;
  }

  function collateralWei() public constant (uint) {
    return USDOracle(usdOracle).usdToWei(collateralUsd);
  }

  function terminationWei() public constant (uint) {
    return USDOracle(usdOracle).usdToWei(terminationDays * rentPerDayUsd);
  }

  function daysToSeconds(uint days) public returns (uint) {
    return days * 24 * 60 * 60;
  }

  function secondsToDays(uint seconds) public returns (uint) {
    return seconds / 24 / 60 / 60;
  }

  /**
   * Returns a boolean indicating whether the minimum number of days have passed
   **/
  function minimumDaysPassed() public constant (bool) {
    /**
     * Not sure I like this conditional, the math should work in 0 case
     **/
    if (!leaseIsActive()) return false;

    return secondsToDays(block.timestamp - leaseStartTimestamp) >= minimumDays;
  }

}
