pragma solidity 0.5.0;

// Deploy this to the quorum Sidechain
// https://github.com/DZariusz/BinaryMerkleTree/blob/master/contracts/BinaryMerkleTree.sol

//                                                                                  c=====e
//                                           GALATIONS 3:28                            H
//     ____________                                                                _,,_H__
//    (__((__((___()                                                              //|     |
//   (__((__((___()()____________________________________________________________// |ACME |
//  (__((__((___()()()-----------------------------------------------------------'  |_____|

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Sidechain{
	
	struct loanApp{
// The index in the loanApps array
    	uint ID;
// the amount in gbp
    	uint amount;
// the reason why the loan is needed
    	string description;
    	address applicant;
    	address[] upVote;
    	address[] downVote;
        address[] allowedVoters;
    	bool approved;
    	bool passedDeadline;
// The user can only vote once per loan application
    	bool userVoted;
        mapping(address => bool) voted;
    }

	struct voter{
// is the voters index in the voters array
        uint ID;
        address voter;
// this is the array of apps the voter is eligible to vote on
        loanApp[] appsToVote;
        uint appCounter;
	}

// this is item in our tree, `parent` is pointer to next item, `  nodeType` will tell us what king of node this is
    struct TreeItem {
        bytes32 parent;
        NodeTypes nodeType;
    }

	loanApp[] apps;
    loanApp[] approvedd;
    voter[] voters;
    uint DGcounter;
    uint approvedCounter;
    address oracle;
    enum NodeTypes { Leaf, Node, Root }
// @dev this is tree root hash
    bytes32 public root;
/// @dev this is our simple Merkle Tree
/// @notice looks "small"? well.. it does the job. Merkle tree (as well as any other hash tree) are just items/nodes
/// connected from one to another by pointer (sometimes not only one). Solidity has this great feature of mapping data,
/// and this is just perfect data type for building any kind of trees or lists structures.
    mapping (bytes32 => TreeItem) public tree;
/// @dev this are our data, in real product we probably keep them eg in IPFS, but just for this example,
/// I will keep them in the contract. Key is of course a hash of data.
/// Since I have them, I will use this to validate uniqueness of the data
    mapping (bytes32 => uint256) public leaves;
//   mapping(address => voter) voters;
    mapping (address => voter) voterss;

// create oracle that listens for this and adds the approved address's to the main net FCB contract
    event approved(string memory approved);
// event will be emitted after creation of each leaf
    event LogCreateLeaf(uint256 data, bytes32 dataHash);
// event will be emitted on each item creation
    event LogCreateTreeItem(bytes32 hash, bytes32 left, bytes32 right);
    event LogCreateRoot(bytes32 root);
// notice events are ususally about state change in contract, this event helped me with debugging process
// it just inform us how many items we have in each level 
    event LogLevelNodes(uint256 count);

    modifier onlyOracle(){
    	require (msg.sender == oracle);
    	_;
    }

// gets a loan application for a voter
    function getUsersLoanApp(uint index) public view returns(uint ID, uint amount, string memory description,
                                         address applicant, address[] memory upVote, address[] memory downVote,
                                         bool approved, bool passedDeadline, bool userVoted){
        voter storage f = voterss[msg.sender];
        loanApp storage l = f.appsToVote[index];
        return (l.ID, l.amount, l.description, l.applicant, l.upVote, l.downVote, l.approved, 
                l.passedDeadline, l.userVoted);
    }

	function vote(bool _vote, uint index) public{
        voter storage b = voterss[msg.sender];
        uint c = b.ID;
        loanApp storage a = voters[c].appsToVote[index];
        require(a.passedDeadline == false);
        require(a.userVoted == false);
        loanApp storage v = apps[a.ID];
        if(_vote == true && a.voted[msg.sender] == false){
        	v.upVote.push(msg.sender);
            a.voted[msg.sender] = true;
        } if(_vote == false && a.voted[msg.sender] == false){
            v.downVote.push(msg.sender);
            a.voted[msg.sender] = true;
        }
        a.userVoted = true;
	}

    function addVoter(address _voter) public payable onlyOracle{
        voter storage m = voterss[msg.sender];
        m.ID = voters.length + 1;
        voters.push(m);
    }

    function createLoanApp(address _appllicant, uint _amount, string memory _description) public onlyOracle{
        voter storage v = voterss[msg.sender];
        require(v.voter == msg.sender);
        loanApp storage ap = apps[apps.length + 1];
    	ap.ID = apps.length;
    	ap.amount = _amount;
    	ap.description = _description;
    	ap.applicant = _appllicant;
    	ap.approved = false;
    	ap.passedDeadline = false;
    	apps.push(ap);
    }

// Gets all of the loan apps that passed the votes and passed the deadline -- makes them in to a merkle tree 
// and emits the merkle tree in an event that the oracle is listening for -- Oracle then writes the tree
// to the FCB Contract on the main net
    function getApproved() public payable returns(uint n){
        uint num = approvedCounter;
        for (uint i = approvedCounter; i < apps.length; i++) {
            loanApp storage l = apps[i];
            if (l.passedDeadline == true && l.upVote.length > l.downVote.length){
                approvedd.push(l);
            } else if(l.passedDeadline == false){
// crete a merkle tree using the 'approvedd' array
                approvedd.push(l);
            	approvedCounter = i;
            }
        }
        return num;
    }

// set precisioin to 3
    function percent(uint numerator, uint denominator, uint precision) public pure returns(uint quotient) {
// caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
// with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

// This function gets all the eligible loan apps and sets voters to each app randomly and evenly
// e.g. 100 loanApps and 10 Veri accounts = 10 voters per app (randomly selected)
    function delegateVotes() public onlyOracle {
    	uint[] memory array;
        for (uint i = DGcounter; i < apps.length; i++) {
            uint256 n = 7;
    // fix below vvv
//            uint256 n = i + uint256(keccak256((block.timestamp, block.difficulty))) % (apps.length - i);
            uint256 temp = apps[n].ID;
            array[n] = apps[i].ID;
            array[i] = temp;
        }
// How many votes are delegated to each account
        uint deno = apps.length - DGcounter;
        uint delegatedVotes = percent(voters.length, deno, 3);
        for(uint256 i = 0; i < voters.length; i++){
        	voter storage account = voters[i];
        	for(uint256 l = 0; l < delegatedVotes; l++){
        		account.appsToVote.push(apps[array[l]]);
        		delete array[l];
        	}
        }
        DGcounter = apps.length;
    }

// returns a list of all the applications by ID the user can vote on
//    function getVotersApps() public view returns (uint[] memory array){
//        voter storage v = voterss[msg.sender];
//        uint index = 0;
//        bool breakk = false;
//        uint[] storage arrayy;
//        for(uint i = v.appCounter; i < v.appsToVote.length; i++){
//            uint ins = v.appsToVote[i];
//            loanApp storage a = apps[index];
//            if(a.passedDeadline == true && breakk == false){
//                index + 1;
//            }if(a.passedDeadline == false && breakk == false){
//                breakk = true;
//                arrayy.push(ins);
//            }if(a.passedDeadline == false && breakk == true){
//                arrayy.push(ins);
//            }
//        }
//        v.appCounter + index;
//        return arrayy;
//    }

// The sidechain contract creates a merkle tree of all the result every 7 days
// and writes the hash to FCB contract
//
//              * *    
//           *    *  *
//      *  *    *     *  *
//     *     *    *  *    *
// * *   *    *    *    *   *           --------------------
// *     *  *    * * .#  *   *          --- MERKLE TREE  ---
// *   *     * #.  .# *   *             --------------------
//  *     "#.  #: #" * *    *
// *   * * "#. ##"       *
//   *       "###
//             "##
//              ##.
//              .##:
//              :###
//              ;###
//            ,####.
///\/\/\/\/\/.######.\/\/\/\/\

/// @dev because I use zero, when I have odd number of hashes in tree level, I don't want to use zeros as input data
/// @return true if all our data are ok, throw otherwise

    function validateData(uint[] memory _data) private pure returns (bool){
        for (uint i=0; i < _data.length; i++) {
            require(_data[i] > 0, "You cannot use zeros in this demonstration");
        }
        return true;
    }

/// @dev it does this ceil(a/2)
    function div2ceil(uint a) public pure returns (uint) {
        return ((a + (a % 2)) / 2);
    }

/// I create it to check, if I can save some gas, if I use memory table instead of `leafs` state,
/// to check, if all data is unique, but it turns out, it uses more gas.

/*  function inArray(bytes32[] memory array, bytes32 v) public pure returns (bool yes){
        for (uint i=0; !yes && i < array.length; i++) {
            if (array[i] == v) yes = true;
        }
    } // */

/// @dev this function create bottom level or the tree
/// @param _data array of input data
/// @return array of hashes for created tree level and count of that array
    function createLeafs(uint256[] memory _data) private returns (bytes32[] memory, uint256){
// here we will save all leafs hashes
        bytes32[] memory tmp = new bytes32[](_data.length);
        uint256 index = 0;
// loop for generating hashes for all input data
        for (uint i=0; i < _data.length; i++) {
            bytes32 h = keccak256(abi.encodePacked(_data[i]));
            require(leaves[h] == 0, "This example require unique data");
//require(!inArray(tmp, h), "This example require unique data");  // this uses more gas
            tmp[index] = h;
            index++;
// save data to the contract state
            leaves[h] = _data[i];
// and create our first tree level
            tree[h] = TreeItem({parent: bytes32(0), nodeType: NodeTypes.Leaf});
            emit LogCreateLeaf(_data[i], h);
        }
        return (tmp, index);
    }

/// @dev this function creates one tree level
/// @param _childrenHashes Children hashes from previous level or data hashes, if we start building the tree
/// @return array of hashes for created tree level and count of that array
    function createTreeLevel(bytes32[] memory _childrenHashes, uint256 _childrenCount) private
                                                          returns (bytes32[] memory, uint256){
        require(_childrenCount > 0, "_childrenCount must be > 0");
        bytes32[] memory tmp = new bytes32[](div2ceil(_childrenCount));
        uint256 index = 0;
// if we have only one hash, means our tree is ready and this is our root
        if (_childrenCount == 1) {
            root = _childrenHashes[0];
            tree[_childrenHashes[0]].  nodeType = NodeTypes.Root;
            emit LogCreateRoot(_childrenHashes[0]);
            return (tmp, 0);
        }
        uint256 len = _childrenHashes.length;
// go through every hash by step of 2, because every iteration takes 2 items to generate parent hash
        for (uint i=0; i < len; i += 2) {
// if we don't have even number of hashes, we use 0 in place of last one
// how we handle that case is also depends on our implementation,
// eg. we can have implementation where we pass current hash without change to next level
// but here, we are using hashes also as pointers, so we can't do that
            bytes32 h = createItem(_childrenHashes[i],  //left child
            i + 1 < len ? _childrenHashes[i+1] : bytes32(0)); //right child
//save our hash, so we can pass it to the next level
            tmp[index] = h;
            index++;
        }
        return (tmp, index);
    }

// @dev this function create tree item based on children hashes
// @return item hash
    function createItem(bytes32 _left, bytes32  _right) private returns (bytes32 hash) {
// create item hash
        hash = keccak256(abi.encodePacked(_left, _right));
// save pointers from children to parent
        tree[_left].parent = hash;
        tree[_right].parent = hash;
// save our current hash
        tree[hash] = TreeItem({parent: bytes32(0), nodeType: NodeTypes.Node});
        emit LogCreateTreeItem(hash, _left, _right);
        return hash;
    }

// @dev checks if type `nt` is correct according to the level.
// @param nt node type
// @param level current level of the node
// @param branchNodesCount - maximum number of levels (count of all nodes in a branch)
    function validateNodeType(NodeTypes nt, uint level, uint branchNodesCount) private pure returns (bool) {
// first level is a leaf
        if (level == 0 && nt == NodeTypes.Leaf) return true;
// last level is a root
        if (level == branchNodesCount - 1 && nt == NodeTypes.Root) return true;
// all other should be nodes
        if (nt == NodeTypes.Node) return true;
        return false;
    }

// @dev this is entry point for creating merkle tree. In real product, you probably will keep data externally
// and input for creating a tree would be only hashes of the data, but I wanted to demonstrate whole process.
// Limitation of this example: you can't pass big amount of data,
// because you will run out of gas while processing them. You also need to pass different/unique values.
//
// @param _data Array of unique numbers
    function createTree(uint256[] memory _data) public returns (bool){
        require(_data.length > 1, "Number of items must be greater than 1");
        require(root == bytes32(0), "This implementation allow to create a tree only once");
        validateData(_data);
// first step - create data hashes
        bytes32[] memory h;
        uint256 index;
        (h, index) = createLeafs(_data);
        emit LogLevelNodes(index);
// for this example purposes I will create a loop here, but this is not good solution for real product
// unless you are 100% sure that you will never ever - even in 100 years ;-) - have large amount of data
// otherwise your contract will be useless, because you will never be able to create tree (gas limitation)
// in real implementation it might be better to use eg. this pattern:
// 1. call `createTreeLevel()` externally with your hashes
// 2. watch for events from DAPP and save generated hashes
// 3. with results from point 2. if we have any hashes left, go to 1. if not go to 4.
// 4. we don't have any hashes, then our tree is ready
// This is just a proposition of better and more complex solution, implementation always depends of requirements.
// now let's generate our tree with easy fast way, just for recruitment demonstration
// keep this loop going until we create every level of the tree
        do {
            (h, index) = createTreeLevel(h, index);
            emit LogLevelNodes(index);
        } while (index > 0);
        return true;
        }
}
