pragma solidity ^0.4.19;

interface USDOracle {
  function getPrice() public constant returns (uint);
  function usdToWei(uint usd) public constant returns (uint);
  function priceNeedsUpdate() public constant returns (bool);
}

contract Lease {

  /**
   * This is supplied by the BlockLease DAC automatically.
   *
   * 1% of all landlord payouts are sent to the usdOracle as funding for the
   * service and the DAC
   *
   * https://github.com/BlockLease/USDOracle
   **/
  address public usdOracle;

  /**
   * Landlord and tenant wallet addresses.
   *
   * These should _not_ be exchange addresses.
   **/
  address public landlord;
  address public tenant;

  /**
   * Seconds per payment cycle. Determines how often funds are released to
   * landlord.
   **/
  uint public cycleTime;

  /**
   * The US Dollar value that should be paid to the landlord each month.
   */
  uint public cyclePriceUsd;

  /**
   * The minimum number of cycles that must have passed before `terminate` can
   * be called.
   **/
  uint public minCycleCount;

  /**
   * The balance owed to the landlord in wei.
   **/
  uint public landlordBalance;
  uint public tenantBalance;

  /**
   * The number of payment cycle that have been credited to `landlordBalance`.
   **/
  uint public landlordCyclesPaid;

  /**
   * Signatures for activation of contract.
   **/
  mapping(address => bool) public signatures;

  /**
   * Signatures for agreement about contract destruction.
   **/
  mapping(address => bool) public destroySignatures;

  string public descriptionAddress;
  string[] public imageAddresses;

  /**
   * Create a lease agreement between a landowner and a tenant.
   *
   * Rent is credited to the landlord wallet at the `startTime` and after every
   * `cycleTime` seconds.
   *
   * Rent is converted from USD to Ethereum using the `usdOracle` supplied.
   *
   * The usdOracle must have been updated within the last hour for most
   * operations.
   **/
  function Lease(
    address _usdOracle,
    address _landlord,
    uint _cycleTime,
    uint _cyclePriceUsd,
    uint _minCycleCount
  ) public {
    // Ensure the lease start is in the future
    require(_startTime > block.timestamp);
    // Ensure lease cycle is at least 1 hour
    require(_cycleTime > 60 * 60 * 1);
    usdOracle = _usdOracle;
    landlord = _landlord;
    cyclePriceUsd = _cyclePriceUsd;
    cycleTime = _cycleTime;
    minCycleCount = _minCycleCount;
  }

  /**
   * Sign the contract.
   *
   * This must be called before `startTime`.
   **/
  function sign() public {
    require(msg.sender == landlord || msg.sender == tenant);
    selfdestructIfNecessary();
    signatures[msg.sender] = true;
  }

  /**
   * Collateral and rent may be supplied here.
   **/
  function () payable public {
    selfdestructIfNecessary();
    require(msg.sender == tenant);
  }

  /**
   * If the `startTime` passes and the contract has not been signed by both the
   * landlord and the tenant then selfdestruct send money to tenant.
   *
   * The tenant is the only one capable of sending money into the contract.
   **/
  function selfdestructIfNecessary() public {
    if (block.timestamp > startTime && !signed()) {
      selfdestruct(tenant);
    }
  }

  /**
   * Helper to ensure both parties have signed.
   *
   * If the contract has failed signature and the 'startTime' has passed
   * then selfdestruct.
   **/
  function assertSigned() internal constant {
    require(signed());
  }

  /**
   * Whether landlord and tenant have signed.
   **/
  function signed() constant public returns (bool) {
    return (signatures[landlord] && signatures[tenant]);
  }

  /**
   * Return the current lease cycle
   **/
  function leaseCycle() constant public returns (uint) {
    if (block.timestamp < startTime) {
      return 0;
    } else {
      return 1 + ((block.timestamp - startTime) / cycleTime);
    }
  }

  function landlordBalanceDiff(uint _currentCycle) public constant returns (uint256) {
    if (landlordCyclesPaid < _currentCycle) {
      return (_currentCycle - landlordCyclesPaid) * rentWeiValue();
    } else {
      return 0;
    }
  }

  /**
   * Update the landlord balance based on the current cycle.
   **/
  function updateLandlordBalance() public {
    require(msg.sender == landlord || msg.sender == tenant);
    uint currentCycle = leaseCycle();
    landlordBalance += landlordBalanceDiff(currentCycle);
    landlordCyclesPaid = currentCycle;
  }

  /**
   * Called by landlord, this will send the available landlord balance to the
   * landlord address.
   *
   * It can be called to collect all outstanding rent belonging to the landlord.
   **/
  function receiveRent() public {
    selfdestructIfNecessary();
    assertSigned();
    require(msg.sender == landlord);
    updateLandlordBalance();
    require(landlordBalance > 0);
    require(this.balance >= landlordBalance);
    uint256 balance = landlordBalance;
    // Take a 1% oracle fee
    uint256 oracleFee = balance / 100;
    landlordBalance = 0;
    landlord.transfer(balance - oracleFee);
    usdOracle.transfer(oracleFee);
  }

  /**
   * Called by the tenant, money is stored in the smart contract
   **/
  function payRent() public payable {
    selfdestructIfNecessary();
    assertSigned();
    require(msg.sender == tenant);
    require(msg.value >= rentOwed());
  }

  /**
   * A convenience method for determining how much eth is currently owed for
   * rent
   **/
  function rentOwed() public constant returns (uint256) {
    uint currentCycle = leaseCycle();
    uint256 unclaimedLandlordBalance = landlordBalanceDiff(currentCycle);
    uint256 netLandlordBalance = landlordBalance + unclaimedLandlordBalance;
    if (this.balance > netLandlordBalance) return 0;
    return netLandlordBalance - this.balance;
  }

  /**
   * Returns the current rent price in ETH based on the GDAX exchange rate
   * stored in the USDOracle contract.
   *
   * The USDOracle contract should be updated whenever rent is being operated on.
   **/
  function rentWeiValue() public constant returns (uint256) {
    // USDOracle must have been updated recently
    require(!USDOracle(usdOracle).priceNeedsUpdate());
    return USDOracle(usdOracle).usdToWei(cyclePriceUsd);
  }

  /**
   * Terminates the lease contract on behalf of the tenant
   *
   * Termination requires that the current cycle and an additional cycle be paid
   *
   * At least 1 cycle of notification must be supplied to the landlord
   **/
  function terminate() public {
    selfdestructIfNecessary();
    assertSigned();
    require(leaseCycle() >= minCycleCount - 1);
    require(msg.sender == tenant);
    updateLandlordBalance();
    require(this.balance >= landlordBalance + rentWeiValue());
    // Ensure the landlord is paid through the current cycle, plus one more
    landlordBalance += rentWeiValue();
    // Transfer funds out to landlord
    uint256 balance = landlordBalance;
    landlordBalance = 0;
    landlord.transfer(balance);
    // Send any other balance to the tenant as a refund
    selfdestruct(tenant);
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
  function destroy() public {
    selfdestructIfNecessary();
    assertSigned();
    require(msg.sender == landlord || msg.sender == tenant);
    destroySignatures[msg.sender] = true;

    if (destroySignatures[landlord] && destroySignatures[tenant]) {
      updateLandlordBalance();
      uint256 balance = landlordBalance;
      landlordBalance = 0;
      landlord.transfer(balance);
      selfdestruct(tenant);
    }
  }

  /**
   * Convenenience accessors to avoid interacting with the `signatures` mapping
   * outside of solidity.
   **/
  function tenantSigned() public constant returns (bool) {
    return signatures[tenant];
  }

  function landlordSigned() public constant returns (bool) {
    return signatures[landlord];
  }
}
