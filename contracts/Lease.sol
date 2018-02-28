pragma solidity ^0.4.19;

interface USDOracle {
  function getPrice() external constant returns (uint);
  function priceNeedsUpdate() external constant returns (bool);
  function usdToWei(uint usd) external constant returns (uint256);
}

contract Lease {

  address public landlord;
  address public tenant;

  uint public collateralUsd;
  uint public rentPerDayUsd;
  uint public minimumDays;

  uint public rentStartTimestamp;

  address public usdOracle;

  function Lease(
    uint _collateralUsd,
    uint _rentPerDayUsd,
    uint _minimumDays
  ) public {
    landlord = msg.sender;
    collateralUsd = _collateralUsd;
    rentPerDayUsd = _rentPerDayUsd;
  }

  function rent() payable {
    require(leaseIsActive());
    require(msg.value >= collateralWei());
    tenant = msg.sender;
    rentStartTimestamp = block.timestamp;
  }

  function leaseIsActive() public constant (bool) {
    return tenant == 0x0;
  }

  function collateralWei() public constant (uint) {
    return USDOracle(usdOracle).usdToWei(collateralUsd);
  }

  /**
   * Returns a boolean indicating whether the minimum number of days have passed
   **/
  function minimumDaysPassed() public constant (bool) {
    /**
     * Not sure I like this conditional, the math should work in 0 case
     **/
    if (!leaseIsActive()) return false;

    return (block.timestamp - rentStartTimestamp) / (60 * 60 * 24) >= minimumDays;
  }

  function terminate() public constant (bool) {
    require(leaseIsActive());
    if (msg.sender == tenant) {
      return tenantTermination();
    } else if (msg.sender == landlord) {
      return landlordTermination();
    } else {
      return false;
    }
  }

  function tenantTermination() public constant (bool) {
    if (minimumDaysPassed()) {

    }
  }

  function landlordTermination() public constant (bool) {
    return false;
  }

}
