pragma solidity ^0.5.8;

import "node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

contract Token is ERC20Detailed {
    constructor(string _name, string _symbol, uint8 _decimals)
        DetailedERC20(_name, _symbol, _decimals)
        public
    {

    }    
}