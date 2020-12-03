pragma solidity ^0.5.12;

//in solidity: Array [Column] [Row]
//indexing starts at 0
//defining 2-dim fixed length array: uint[2][3] T =[[1,2],[3,4],[5,6]];
//T[][] : Two-Dimensional, Dynamic-size
//T[][k] or T[k][] : Two-Dimensional, Mixed-size

contract Matrix {
    //uint256[3][3]  matA = [[1,2,3],[3,4,5],[5,6,7]];
    //uint256[3][3]  matB = [[0,2,1],[4,1,0],[2,5,1]];
	uint256 [3][3] public output;
	
	function compute (uint256[3][3] memory matA, uint256[3][3] memory matB) public {
		output = mat3Mult(matA,matB);
	}
	
	function mat3Mult(uint256[3][3] memory mat1, uint256[3][3] memory mat2) private pure returns (uint[3][3] memory) { 
        uint r1 = mat1.length; // rows of mat1
        uint c1 = mat1[0].length; // columns of mat1
        uint c2 = mat2[0].length; // columns of mat2

        uint256[3][3] memory result; 

        for(uint i = 0; i < r1; ++i) {
            for(uint j = 0; j < c2; ++j) {
                for(uint k = 0; k < c1; ++k) {
                    result[i][j]+= mat1[i][k] * mat2[k][j];
                }
            }
        }

        return result;
    }
  
}

