pragma solidity ^0.4.19;

interface Lease {
  address public landlord;
  address public tenant;
}

contract LeaseRegistry {

  address[] public leases;
  mapping (address => bool) public registeredLeases;

  mapping (address => bool) public operators;

  modifier operator {
    require(operators[msg.sender]);
    _;
  }

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
        leases.length--;
      }
    }
  }

}
