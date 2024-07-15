pragma solidity =0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {CyberFinance} from "../src/CyberFinance.sol";

contract CyberFinanceScript is Script {

    function setUp() public {}

    function run() public {
        vm.broadcast();
        CyberFinance cyberFinance = new CyberFinance(msg.sender);
    }
}
