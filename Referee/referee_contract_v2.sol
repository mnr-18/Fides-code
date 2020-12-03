pragma solidity 0.5.17;

contract scCRR{
    
    //---- Constructor and Intitialization variables ----
    address public referee_owner;
    address public PG;
    bytes32 public task_commitment;
    bytes32 public input_commitment;
    bytes32 public program_instruction_root;
    uint public index; //index to count the number of clouds
    //--- Registration variables -------------------
    address[2] public Cloud; //array to store clouds addresses
    //uint[2] public deposit; //array to store deposits from clouds

    //all the states
    enum States {INIT, Registration_complete, Computation_complete, MCId_complete}
    //current state
    States public current_state = States.INIT;
    
    //---- Variables for result---------------------------
    bytes32[2] public com_result; //commitment to result
    bytes32[2] public Result;     //encrypted result 
    bytes32[2] public MRoot;      // MRoot on reduced configuration
    uint[2] public tape_length;   // size of reduced config array
    mapping (address => bool) public hasDeliver;  // has delivered the commitment?
    mapping (address => bool) public sentResult;  // has sent the enc. result?
    bytes32[2] public com_key;     // key to commitment
    bool public resultMatch;       // does the result match?
    string public resultStatus = "No Result"; 
    bytes32 public final_output;   // correct encrypted output
    uint public  _case;
    
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
        bytes claimedOutput_NextState; // claimed output for step n_b by the server
        bytes actualOutput_PreviousState; // output after executing single step
        bytes32 prevStateRoot;
        bytes32[] MTproof;                //Merkle proof for enc_reduced_config n_g
        bool singleStepTruth;             //Does the execution result match the claimed output? 
        bytes32 op_ng;                    //EVM instruction to execute for single step
        bytes32[] MTproof_op_ng;          //Merkle proof for op_ng
        bool op_truth;                    //Is op_ng a valid instruction based on MTproof_op_ng?
        
    }
   mapping(address => SingleStep) clouds;
    
    //---- Events ---------------------
    event taskInitialized(bytes32 _com_f, bytes32 _com_x);
    event revealResult(string _reveal);
    event sendProof(address cloud_i, uint256 q_i);
    event provideConfig(uint last_matched_index, uint first_mismatch_index, address cloud_id);
    event sendMidConfiguration(uint mid);

    //=========== scCRR Contract Functions ========================================================================
    
    constructor() public {
       // Set the creator of contract as the owner of the referee contract
       referee_owner = msg.sender;
    }
        
    //"0x60298f78cc0b47170ba79c10aa3851d7648bd96f2f8e46a19dbc777c36fb0c00","0x60298f78cc0b47170ba79c10aa3851d7648bd96f2f8e46a19dbc777c36fb0c63","0x60298f78cc0b47170ba79c10aa3851d7648bd96f2f8e46a19dbc777c36fb0c2f"
    function Initialize (bytes32 com_f, bytes32 com_x, bytes32 _Mroot) public{
        PG = msg.sender;
        //initialize contract parameters
        index = 0;
        task_commitment = com_f;
        input_commitment = com_x;
        program_instruction_root = _Mroot;
        emit taskInitialized(task_commitment, input_commitment);
    }
    
    function Register () public {
        require (index < 2, "Registration complete");    
        Cloud[index] = msg.sender;
        index = index+1;
        if (index == 2) current_state = States.Registration_complete;
	}
    
     
    //Function to receive commitment to encrypted result from cloud
    //Each cloud sends the commitment to encrypted result, merkle root on reduced config and number of steps required 
    function receiveResultCommitment (bytes32 _enc_com_y, bytes32 _root, uint N) public{  
        assert(msg.sender == Cloud[0] || msg.sender == Cloud[1]);
        //record the commitment to encrypted result, Mroot on reduced config and #of steps
        if (msg.sender == Cloud[0]){
            com_result[0] = _enc_com_y;
            MRoot[0] = _root;
            tape_length[0] = N;
        }
        else {
            com_result[1] = _enc_com_y;
            MRoot[1] = _root;
            tape_length[1] = N;
        }
        hasDeliver[msg.sender] = true;
        // if both clouds delivered then ask for revealing the encrypted result
        if (hasDeliver[Cloud[0]] == true && hasDeliver[Cloud[1]] == true) {
                emit revealResult("Reveal encrypted results");
        }
    }

    //Function to receive revealed encrypted results of the clouds 
    function receiveEncResult (bytes32 _enc_y, bytes32 _key_y) public{
        assert(msg.sender == Cloud[0] || msg.sender == Cloud[1]);
        if (msg.sender == Cloud[0]){
            Result[0] = _enc_y;
            com_key[0] = _key_y;
        }
        else {
            Result[1] = _enc_y;
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
    function Compare () internal {
        //require (hasDeliver[Cloud[0]] == true && hasDeliver[Cloud[1]] == true,"Both results not received");
        if (Result[0] == Result[1] && tape_length[0]==tape_length[1]){ //results match
            resultMatch = true;
            //verify commitment to encrypted result
            bool valid_opening1;
            bool valid_opening2;
            valid_opening1 = verify_commitment(com_result[0], Result[0], com_key[0]);
            valid_opening2 = verify_commitment(com_result[1], Result[1], com_key[1]);
            if (valid_opening1 == true && valid_opening2 == true){
                resultStatus = "Correct result";
                final_output = Result[0];
            }
            else if (valid_opening1 == true && valid_opening2 == false){
                resultStatus = "Correct result";
                final_output = Result[0];
            }
            else if (valid_opening1 == false && valid_opening2 == true){
                resultStatus = "Correct result";
                final_output = Result[1];
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
  
    function verify_commitment (bytes32 _com_y, bytes32 _enc_result, bytes32 _key_y) internal pure returns (bool){
        bytes32 com_msg = keccak256(abi.encodePacked(_key_y, _enc_result));
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
                  _match = checkMatch(); //check match in enc_configs and verify MProof
            
            if (_match==true){
                idx_s=mid;
                mid=((idx_e - idx_s)/2)+idx_s;
                return idx_s;
            } else{
                if (rc[Cloud[0]].copyDetected == false && rc[Cloud[1]].copyDetected == false){
                    idx_e=mid;
                    mid=((idx_e - idx_s)/2)+idx_s;
                    return idx_s;
                }
                else if(rc[Cloud[0]].copyDetected == true && rc[Cloud[1]].copyDetected == false){ 
                   final_output = Result[1]; //copy detected-->Cloud 0 
                   return 0; 
                } 
                else if(rc[Cloud[0]].copyDetected == false && rc[Cloud[1]].copyDetected == true){
                   final_output = Result[0]; //copy detected-->Cloud 1 
                   return 0;  
                }    
            }
        }
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
    //Code source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/MerkleProof.sol
    function VerifyMHProof (bytes32 _leaf, bytes32[] memory merkleProof, bytes32 _MHroot, address _CloudId) private pure returns (bool){
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

    //Sample input arguments for calling "receive_state_data" function
   // "0x600f80600b6000396000f36101016101020160005260206000f3", "0x0000000000000000000000000000000000000000000000000000000000000009", "0x10d25c89b673e0688e39a8bb427fcb1835479366affa54327ad3174030ab9dae", "0x0000000000000000000000000000000000000000000000000000000000000203", ["0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b", "0x891370df4fadf33f50e41f7c8a791e680c0655695ea3404385a909c8f5e13fb4", "0x3d414ff3f9f990e1bbed05697c0201a24bfd5be3780c459476843b865910fc61"]
   function receive_state_data (bytes memory  _stateBytecode, bytes memory _PrevOutput, bytes32 _op_ng, bytes32 _RCroot, bytes memory _claimedOutput, bytes32[] memory _proof_op, bytes32[] memory _proof_RC) public {
        assert(msg.sender == Cloud[0] || msg.sender == Cloud[1]);
        uint256 x;
        if (msg.sender == Cloud[0]) x=0;
        else x=1;
        require (clouds[Cloud[x]].sentStateData == false);
        clouds[Cloud[x]].previousState_Data = _stateBytecode;
        clouds[Cloud[x]].PreviousStateOutput = _PrevOutput;
        clouds[Cloud[x]].prevStateRoot = _RCroot;
        clouds[Cloud[x]].claimedOutput_NextState = _claimedOutput;
        clouds[Cloud[x]].MTproof = _proof_RC;
        clouds[Cloud[x]].sentStateData = true;
        clouds[Cloud[x]].op_ng = _op_ng;
        clouds[Cloud[x]].MTproof_op_ng = _proof_op;
        
        Single_step (x); //initiate single step execution with the data provided by Cloud x
    }
            
    function Single_step (uint x) internal {       
        uint256 PrevValue;
        PrevValue = sliceUint (clouds[Cloud[x]].PreviousStateOutput, 0);
        clouds[Cloud[x]].singleStepTruth = Verify_MHProof(PrevValue, clouds[Cloud[x]].MTproof, clouds[Cloud[x]].prevStateRoot);
        clouds[Cloud[x]].op_truth = VerifyMHProof(clouds[Cloud[x]].op_ng,clouds[Cloud[x]].MTproof_op_ng, MRoot[x], Cloud[x]);
        if (clouds[Cloud[x]].singleStepTruth == true && clouds[Cloud[x]].op_truth == true) {
            (clouds[Cloud[x]].cloud_previousState_address, clouds[Cloud[x]].previousState_RuntimeData, clouds[Cloud[x]].execution_Status, clouds[Cloud[x]].actualOutput_PreviousState) = VerifyReducedStep(clouds[Cloud[x]].previousState_Data);
            if (keccak256(abi.encodePacked(clouds[Cloud[x]].claimedOutput_NextState)) == keccak256(abi.encodePacked(clouds[Cloud[x]].actualOutput_PreviousState))){
                clouds[Cloud[x]].singleStepTruth = true;
            }
            else{
                clouds[Cloud[x]].singleStepTruth = false;
            }
        }
    
        if (clouds[Cloud[x]].singleStepTruth==true){
            resultStatus = "Correct result";
            final_output = Result[x];
        }
        else if (clouds[Cloud[x]].singleStepTruth==false) {
            uint y = 1-x;
            resultStatus = "Correct result";
            final_output = Result[y];
        }

        current_state = States.MCId_complete;
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
    
    function Verify_MHProof (uint256 Qindex, bytes32[] memory merkleProof, bytes32 _MHroot) private pure returns (bool){
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
    
    //function to get the final encrypted result
    function getfinalResult() public view returns (string memory, bytes32) {
        return (resultStatus, final_output);
    }   
}