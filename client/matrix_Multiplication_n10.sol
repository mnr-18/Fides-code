pragma solidity >=0.4.22 <0.6.0;

contract Matrix {
	uint public NoSteps = 0;
	uint256[10][10]  matA = [[5,7,9,10,1,2,3,4,5,6],[2,3,3,8,1,2,3,4,5,6],[8,10,2,3,1,2,3,4,5,6],[3,3,4,8,1,2,3,4,5,6],[5,7,9,10,1,2,3,4,5,6],[2,3,3,8,1,2,3,4,5,6],[8,10,2,3,1,2,3,4,5,6],[3,3,4,8,1,2,3,4,5,6],[3,3,4,8,1,2,3,4,5,6],[5,7,9,10,1,2,3,4,5,6]];
	uint256[10][10]  matB = [[3,10,12,18,3,4,3,4,5,6],[12,1,4,9,1,2,3,4,5,6],[9,10,12,2,3,4,3,4,5,6],[3,12,4,10,1,2,3,4,5,6],[5,7,9,10,1,2,3,4,5,6],[2,3,3,8,1,2,3,4,5,6],[8,10,2,3,1,2,3,4,5,6],[3,3,4,8,1,2,3,4,5,6],[3,3,4,8,1,2,3,4,5,6],[5,7,9,10,1,2,3,4,5,6]];
	uint256 [10][10] public output;


	function compute () public {
		output = mat3Mult(matA,matB);
	}

	function mat3Mult(uint256[10][10] memory mat1, uint256[10][10] memory mat2) private returns (uint[10][10] memory) {
        uint r1 = mat1.length; // rows of mat1
        uint c1 = mat1[0].length; // columns of mat1
        uint c2 = mat2[0].length; // columns of mat2

        uint256[10][10] memory result;

        for(uint i = 0; i < r1; ++i) {
            for(uint j = 0; j < c2; ++j) {
                for(uint k = 0; k < c1; ++k) {
                    result[i][j] += mat1[i][k] * mat2[k][j];
					NoSteps = NoSteps + 2;
                }
            }
        }

        return result;
    }

}
