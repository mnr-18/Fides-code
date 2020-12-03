pragma solidity ^0.7.0;

contract Addition{
    uint public result;
    uint public count = 0;
    event AddResult(uint _eventOutput, uint in1, uint in2);
    function add(uint a, uint b) public{
        if (count < 4){
            result = a + b;
            testEvent(result, a, b);
            add(result, 5);
        }
    }
    
    function testEvent (uint _IntermediateOutput, uint _input1, uint _input2) internal {
        count = count + 1;
        emit AddResult(_IntermediateOutput, _input1, _input2);
    }
    
}