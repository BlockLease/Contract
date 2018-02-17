pragma solidity ^0.4.19;

import "./oraclizeAPI_0.4.sol";

contract USDOracle is usingOraclize {

  // Price in cents as returned by the gdax api
  // GDAX is an fdic insured US based exchange
  // https://www.gdax.com/trade/ETH-USD
  uint256 price;

  function USDOracle() {
    update();
  }

  function () payable public { }

  function getPrice() constant returns (uint256) {
    return price;
  }

  function update() {
    oraclize_query("URL","json(https://api.gdax.com/products/ETH-USD/ticker).price");
  }

  function __callback(bytes32 _myid, string _result) {
    require(msg.sender == oraclize_cbAddress());
    price = parseInt(_result, 2);
  }

}
