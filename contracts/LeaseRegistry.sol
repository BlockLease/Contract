pragma solidity ^0.4.19;

interface Lease {
  address public landlord;
  address public tenant;
}

contract LeaseRegistry {

  /**
   * An array of lease contracts addresses in order of date created
   **/
  address[] public leases;

  /**
   * A mapping of lease addresses to booleans indicating whether they exist
   *
   * TODO: Change this to store integer index of the lease in the leases array
   **/
  mapping (address => bool) public registeredLeases;

  /**
   * A list of operators that can call operator functions
   **/
  mapping (address => bool) public operators;

  /**
   * Operator modifier to restrict user access
   **/
  modifier operator {
    require(operators[msg.sender]);
    _;
  }

  /**
   * Constructor
   * Add contract creator as first operator
   **/
  function LeaseRegistry() public {
    operators[msg.sender] = true;
  }

  function addOperator(address operator) public operator {
    operator[msg.sender] = true;
  }

  function addLease(address _lease) public {
    Lease lease = Lease(_lease);
    require(lease.landlord == msg.sender);
    require(!registeredLeases[_lease]);
    leases.push(_lease);
  }

  function removeLease(address _lease) public {
    Lease lease = Lease(_lease);
    require(lease.landlord == msg.sender);
    require(registeredLeases[_lease]);
    registeredLeases[_lease] = false;
    uint8 offset = 0;
    for (uint x = 0; x < leases.length; x++) {
      address __lease = leases[x];
      if (__lease == _lease) {
        delete leases[x];
        offset += 1;
      } else if (offset > 0) {
        leases[x - offset] = leases[x];
      }
    }
    leases.length -= offset;
  }

}
