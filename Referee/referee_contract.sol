pragma solidity 0.5.17;

contract scRDoC{

    //---- Constructor and Intitialization variables ----
    address public referee_owner;
    address public PG;
    bytes32 public task_commitment;
    bytes32 public input_commitment;
    bytes32 public program_instruction_root;
    uint public index; //index to count the number of clouds
    //--- Registration variables -------------------
    //uint public count = 0;
    address[2] public Cloud; //array to store clouds addresses
    //uint[2] public deposit; //array to store deposits from clouds


    //all the states
    enum States {INIT, Computation_complete, MCId_complete}
    //current state
    States public current_state = States.INIT;

    //---- Variables for result---------------------------
    bytes32[2] public com_result;
    //bytes32[2] public Result;
    uint256 [10][10] public Result1;
    uint256 [10][10] public Result2;
    bytes32[2] public MRoot;
    uint[2] public tape_length;
    mapping (address => bool) public hasDeliver;
    mapping (address => bool) public sentResult;
    bytes32[2] public com_key;
    bool public resultMatch;
    string public resultStatus = "No Result";
    uint256 [10][10] public final_output;

    //-- Variable for resultConfirmation------
    uint public  _case;

    //----- variables for query generation---------------------
    uint256 k;
    uint256 d;
    uint idx; // index to store the block number of the first received result
    uint256 seed;
    struct query{
        uint256 value;
        bytes32[] proof;
        bool MHproofTruth;
    }
    mapping(address => query) public queries;
    mapping (address => bool ) public hasProof;


    //---------- variables for for MCId -----------------
    struct RConfig{
        bytes32 Enc_RC;
        bytes32[] RC_proof;
        bool copyDetected;
    }
    mapping(address => RConfig) rc; //reduced_confuration (rc)
    mapping (address => bool ) public rcReceived;


    //------------- variables for Single step execution ---------------------
    struct SingleStep {
        //address Cid;
        bytes previousState_Data; //stores state bytecode with constructor
        bool sentStateData;
        address cloud_previousState_address; // stores deployed previousState contract address
        bytes previousState_RuntimeData; // stores runtime bytecode
        bool execution_Status; //returns call status
        bytes PreviousStateOutput;
        bytes claimedOutput_NextState; //stores final value after executing previousState contract
        bytes actualOutput_PreviousState;
        bytes32 prevStateRoot;
        bytes32[] MTproof;
        bool singleStepTruth;
        bytes32 op_ng;
        bytes32[] MTproof_op_ng;
        bool op_truth;
    }
   mapping(address => SingleStep) clouds;

    //---- Events ---------------------
    event taskInitialized(bytes32 _com_f, bytes32 _com_x);
    event revealResult(string _reveal);
    event sendProof(address cloud_i, uint256 q_i);
    event provideConfig(uint last_matched_index, uint first_mismatch_index, address cloud_id);
    event sendMidConfiguration(uint mid);
    event Transfer(address sender, address receiver, uint amount);

    //=========== scCRR Contract Functions ========================================================================

    constructor() public {
       // Set the creator of contract as the owner of the referee contract
       referee_owner = msg.sender;
    }

    //modifier ownerOnly {
        //if (msg.sender == PG) _;
    //}

    //_B_f: computation bytecode; _com_x: commitment to input; _Mroot: Merkle root on computation
    function Initialize (bytes32 _B_f, bytes32 _com_x, bytes32 _Mroot) public{
        PG = msg.sender;
        //initialize contract parameters
        index = 0;
        task_commitment = _B_f;
        input_commitment = _com_x;
        program_instruction_root = _Mroot;
        emit taskInitialized(task_commitment, input_commitment);
    }

    function Register () public {
        require (index < 2, "Registration complete");
        Cloud[index] = msg.sender;
        index = index+1;
	}

    //Function to receive commitment to result from server
    //Each server sends the commitment to the result, merkle root on reduced config and number of steps required
    function receiveResultCommitment (bytes32 com_y, bytes32 _root, uint N) public{
        assert(msg.sender == Cloud[0] || msg.sender == Cloud[1]);
        //record the commitment to encrypted result, Mroot on reduced config and #of steps
        if (msg.sender == Cloud[0]){
            com_result[0] = com_y;
            MRoot[0] = _root;
            tape_length[0] = N;
        }
        else {
            com_result[1] = com_y;
            MRoot[1] = _root;
            tape_length[1] = N;
        }
        hasDeliver[msg.sender] = true;
        // if both servers delivered then ask for revealing the encrypted result
        if (hasDeliver[Cloud[0]] == true && hasDeliver[Cloud[1]] == true) {
                emit revealResult("Reveal encrypted results");
        }
    }

    //Function to receive revealed results of the servers
    function receiveResult (uint256[10][10] memory _y, bytes32 _key_y) public{
        assert(msg.sender == Cloud[0] || msg.sender == Cloud[1]);
        if (msg.sender == Cloud[0]){
            Result1 = _y;
            com_key[0] = _key_y;
        }
        else {
            Result2 = _y;
            com_key[1] = _key_y;
        }
        sentResult[msg.sender] = true;
        // if both clouds revealed the encrypted result
        if (sentResult[Cloud[0]] == true && sentResult[Cloud[1]] == true) {
                Compare();
         }
    }

    //function to Compare received receiveResults: takes the results and roots as input
    //if matches, result confirmation phase starts
    //if mismatch, binary_search phase starts
    //Finally, assigns a case value based on the results of the above phases.
    function Compare () internal {
        //require (hasDeliver[Cloud[0]] == true && hasDeliver[Cloud[1]] == true,"Both results not received");
        bytes32 r1 =  keccak256(abi.encodePacked(Result1));
        bytes32 r2 =  keccak256(abi.encodePacked(Result2));
        if (r1 == r2 && tape_length[0]==tape_length[1]){ //results match
            resultMatch = true;
            //verify commitment to encrypted result
            bool valid_opening1;
            bool valid_opening2;
            valid_opening1 = verify_commitment(com_result[0], Result1, com_key[0]);
            valid_opening2 = verify_commitment(com_result[1], Result2, com_key[1]);
            if (valid_opening1 == true && valid_opening2 == true){
                resultStatus = "Correct result";
                final_output = Result1;
            }
            else if (valid_opening1 == true && valid_opening2 == false){
                resultStatus = "Correct result";
                final_output = Result2;
            }
            else if (valid_opening1 == false && valid_opening2 == true){
                resultStatus = "Correct result";
                final_output = Result2;
            }
            //Update computation state to complete
            current_state = States.Computation_complete;
        }
        else{   //results mismatch
            resultMatch = false;
            uint nb = minimum (tape_length[0],tape_length[1]);
            uint ng = binary_search(nb);
            if (ng == 0){
                current_state = States.Computation_complete;
            }
            else{
                for (uint j = 0; j < 2; j++){
                    emit provideConfig(ng, ng+1, Cloud[j]);
                    emit sendProof(Cloud[j], ng);
                }
            }
        }
    }


    function verify_commitment (bytes32 _com_y, uint256[10][10] memory _result, bytes32 _key_y) internal pure returns (bool){
        bytes32 com_msg = keccak256(abi.encodePacked(_key_y, _result));
        if (com_msg == _com_y){
            return true;
        }
        else{
            return false;
        }

    }

    //======================== MCId =========================================
    function minimum(uint _x, uint _y) internal pure returns (uint){
        if(_x>_y){
          return _y;
        } else
          return  _x;
    }


    function binary_search (uint n_b) public returns (uint){
        uint idx_s = 0;
        uint idx_e = n_b;
        bool _match;
        uint mid = ((idx_e - idx_s)/2)+idx_s;
        while(idx_e > idx_s + 1){
            //receiveConfiguration(mid,Cloud[0]);
            //receiveConfiguration(mid,Cloud[1]);
            emit sendMidConfiguration (mid); //event to notify the clouds for sending "mid" reduced configuration

            //check whether both configurations received or not
            require (rcReceived[Cloud[0]] == true && rcReceived[Cloud[1]] == true);
                  _match = checkMatch();

            if (_match==true){
                idx_s=mid;
                mid=((idx_e - idx_s)/2)+idx_s;
                //return idx_s;
            } else{
                if (rc[Cloud[0]].copyDetected == false && rc[Cloud[1]].copyDetected == false){
                    idx_e=mid;
                    mid=((idx_e - idx_s)/2)+idx_s;
                    //return idx_e;
                }
                else if(rc[Cloud[0]].copyDetected == true && rc[Cloud[1]].copyDetected == false){
                   final_output = Result2;
                   return 0;
                }
                else if(rc[Cloud[0]].copyDetected == false && rc[Cloud[1]].copyDetected == true){
                   final_output = Result1;
                   return 0;
                }
            }
        }
        return idx_s;
    }

    function receiveConfiguration (bytes32 _Enc_rc, bytes32[] memory _rc_proof) public {
        assert(msg.sender == Cloud[0] || msg.sender == Cloud[1]);
        if (msg.sender==Cloud[0]){
            rc[Cloud[0]].Enc_RC= _Enc_rc;
            rc[Cloud[0]].RC_proof = _rc_proof;
        }
        else{
            rc[Cloud[1]].Enc_RC = _Enc_rc;
            rc[Cloud[1]].RC_proof = _rc_proof;
        }
        rcReceived[msg.sender] = true;
    }


    function checkMatch() internal returns (bool){
        if (rc[Cloud[0]].Enc_RC == rc[Cloud[1]].Enc_RC){
            bool b1 = VerifyMHProof(rc[Cloud[0]].Enc_RC, rc[Cloud[0]].RC_proof, MRoot[0], Cloud[0]);
            bool b2 = VerifyMHProof(rc[Cloud[1]].Enc_RC, rc[Cloud[1]].RC_proof, MRoot[1], Cloud[1]);
            if (b1==true && b2==true){
                return true;
            }
            else if (b1==true && b2==false) {
                rc[Cloud[1]].copyDetected = true;
                return false;
            }
            else if (b1==false && b2==true){
                rc[Cloud[0]].copyDetected = true;
                return false;
            }
        }
        else{
            return false;
        }
    }

//======================= MHProof ============================================

    function receiveProof (bytes32[] memory merkleProof) public{
        assert(msg.sender == Cloud[0] || msg.sender == Cloud[1]);
        if (msg.sender==Cloud[0]){
            queries[Cloud[0]].proof = merkleProof;
        }
        else{
            queries[Cloud[1]].proof = merkleProof;
        }
        hasProof[msg.sender] = true;
    }

    //Code source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/MerkleProof.sol
    function VerifyMHProof (bytes32 _leaf, bytes32[] memory merkleProof, bytes32 _MHroot, address _CloudId) private view returns (bool){
        require (hasProof[_CloudId] == true,"Proof not received");
        bytes32 node;
        node =  keccak256(abi.encodePacked(_leaf));
        for (uint16 i = 0; i < merkleProof.length; i++) {
            bytes32 proofElement = merkleProof[i];
            if (node <= proofElement) {
                node = keccak256(abi.encodePacked(node, proofElement));
            } else {
                node = keccak256(abi.encodePacked(proofElement, node));
            }
        }

        // Check the merkle proof
        if (node == _MHroot){
            return true;
        }
        else{
            return false;
        }
    }

    // =============== Single step execution ==================================

    function receive_state_data (bytes memory  _stateBytecode, bytes memory _PrevOutput, bytes32 _op_ng, bytes32 _RCroot, bytes memory _claimedOutput, bytes32[] memory _proof_op, bytes32[] memory _proof_RC) public {
        assert(msg.sender == Cloud[0] || msg.sender == Cloud[1]);
        uint256 x;
        if (msg.sender == Cloud[0]) x=0;
        else x=1;
        if (clouds[Cloud[x]].sentStateData) return;
            clouds[Cloud[x]].previousState_Data = _stateBytecode;
            clouds[Cloud[x]].PreviousStateOutput = _PrevOutput;
            clouds[Cloud[x]].prevStateRoot = _RCroot;
            clouds[Cloud[x]].claimedOutput_NextState = _claimedOutput;
            clouds[Cloud[x]].MTproof = _proof_RC;
            clouds[Cloud[x]].sentStateData = true;
            clouds[Cloud[x]].op_ng = _op_ng;
            clouds[Cloud[x]].MTproof_op_ng = _proof_op;
    }

    function Single_step () public {
        uint256 PrevValue;
        PrevValue = sliceUint (clouds[Cloud[0]].PreviousStateOutput, 0);
        clouds[Cloud[0]].singleStepTruth = Verify_MHProof(PrevValue, clouds[Cloud[0]].MTproof, clouds[Cloud[0]].prevStateRoot, Cloud[0]);
        clouds[Cloud[0]].op_truth = VerifyMHProof(clouds[Cloud[0]].op_ng,clouds[Cloud[0]].MTproof_op_ng, MRoot[0], Cloud[0]);
        if (clouds[Cloud[0]].singleStepTruth == true && clouds[Cloud[0]].op_truth == true) {
            (clouds[Cloud[0]].cloud_previousState_address, clouds[Cloud[0]].previousState_RuntimeData, clouds[Cloud[0]].execution_Status, clouds[Cloud[0]].actualOutput_PreviousState) = VerifyReducedStep(clouds[Cloud[0]].previousState_Data);
            if (keccak256(abi.encodePacked(clouds[Cloud[0]].claimedOutput_NextState)) == keccak256(abi.encodePacked(clouds[Cloud[0]].actualOutput_PreviousState))){
                clouds[Cloud[0]].singleStepTruth = true;
            }
            else{
                clouds[Cloud[0]].singleStepTruth = false;
            }
        }


        PrevValue = sliceUint (clouds[Cloud[1]].PreviousStateOutput, 0);
        clouds[Cloud[1]].singleStepTruth = Verify_MHProof(PrevValue, clouds[Cloud[1]].MTproof, clouds[Cloud[1]].prevStateRoot, Cloud[1]);
        clouds[Cloud[1]].op_truth = VerifyMHProof(clouds[Cloud[1]].op_ng,clouds[Cloud[1]].MTproof_op_ng, MRoot[1], Cloud[1]);
        if (clouds[Cloud[1]].singleStepTruth == true && clouds[Cloud[1]].op_truth == true) {
            (clouds[Cloud[1]].cloud_previousState_address, clouds[Cloud[1]].previousState_RuntimeData, clouds[Cloud[1]].execution_Status, clouds[Cloud[1]].actualOutput_PreviousState) = VerifyReducedStep(clouds[Cloud[1]].previousState_Data);
            if (keccak256(abi.encodePacked(clouds[Cloud[1]].claimedOutput_NextState)) == keccak256(abi.encodePacked(clouds[Cloud[1]].actualOutput_PreviousState))){
                clouds[Cloud[1]].singleStepTruth = true;
            }
            else{
                clouds[Cloud[1]].singleStepTruth = false;
            }
        }


        if (clouds[Cloud[0]].singleStepTruth==true && clouds[Cloud[1]].singleStepTruth==false){
            _case = 2;
            resultStatus = "Correct result";
            final_output = Result1;
        }
        else if (clouds[Cloud[0]].singleStepTruth==false && clouds[Cloud[1]].singleStepTruth==true) {
            _case = 4;
            resultStatus = "Correct result";
            final_output = Result2;
        }
        else if (clouds[Cloud[0]].singleStepTruth==false && clouds[Cloud[1]].singleStepTruth==false) {
            _case = 5;
        }

        current_state = States.MCId_complete;
       // Pay(_case);
   }

   function VerifyReducedStep (bytes memory _stateBytecode) internal returns (address, bytes memory, bool, bytes memory){
        address cloud_data_addr;
        bytes memory state_value;
        bool TF;
        bytes memory val;

        cloud_data_addr = deploy(_stateBytecode);

        //The following statement will return the final memory value if _stateBytecode is sent without constructor
        //otherwise it will retrun the runtime code in the given address
        state_value = Runtime_code(cloud_data_addr);

        //The following statement will return the final memory value (val) if _stateBytecode is sent with constructor
        //use this following statement to get the final memory value (in val) only when _stateBytecode is sent with constructor
        //otherwise don not use it.
        (TF,val) = cloud_data_addr.call(" ");  //returns (bool, bytes memory)
        return (cloud_data_addr, state_value, TF,val);
    }

    //Following function deploys the bytecode and returns a contract address
    function deploy(bytes memory _bytecode) internal returns (address) {
        address addr;
        bytes memory bytecode = _bytecode;
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        return addr;
    }

    //Following function returns the runtime bytecode in the given address
    function Runtime_code(address _addr) private view returns (bytes memory o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
        return o_code;
    }


    //function to convert bytes to uint
    function sliceUint(bytes memory bs, uint start) internal pure returns (uint256){
        require(bs.length >= start + 32, "slicing out of range");
        uint256 x;
        assembly {
        x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }

    function Verify_MHProof (uint256 Qindex, bytes32[] memory merkleProof, bytes32 _MHroot, address _CloudId) private view returns (bool){
        require (hasProof[_CloudId] == true,"Proof not received");
        bytes32 node;
        node =  keccak256(abi.encodePacked(Qindex));
        for (uint16 i = 0; i < merkleProof.length; i++) {
            bytes32 proofElement = merkleProof[i];
            if (node <= proofElement) {
                node = keccak256(abi.encodePacked(node, proofElement));
            } else {
                node = keccak256(abi.encodePacked(proofElement, node));
            }
        }

        // Check the merkle proof
        if (node == _MHroot){
            return true;
        }
        else{
            return false;
        }
    }


    function getfinalResult() public view returns (string memory, uint[10][10] memory) {
        return (resultStatus, final_output);
    }


}
