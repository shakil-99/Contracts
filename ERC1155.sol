// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// import "openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "localhost/ERC1155/IERC1155_1.sol";
import "localhost/ERC1155/AddressLib.sol";

contract NFTs is IERC1155{
    
    using Address for address;

    uint[] private _Id;
    uint256 AuctionEnd;
	uint public highBid;

    address public highestBidder; //topBidder
    address  owner = msg.sender;
            //Mapping from TokenId to account address
    mapping (uint256 =>mapping(address =>uint256))private _balances;
            //Mapping from account to operator approval
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => uint) returnsPending;


    event HighbidIncereased(address bidder, uint bidAmount);

    modifier Owner{
        require(msg.sender == owner,"Only owner can access");
        _;
    }


    function balanceOf(address _owner, uint256 _id) public view virtual override  returns(uint256){
        require(_owner != address(0),"Blance Query for the zero address");
        return _balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) public view virtual override returns (uint256[] memory){
        require(_owners.length == _ids.length,"Owner and TokenId is MisMatch");

        uint256[] memory batchBalances = new uint256[](_owners.length);

        for(uint256 i =0; i <_owners.length;i++){
            batchBalances[i] =balanceOf(_owners[i],_ids[i]);
        }
        return batchBalances;
    }

    function setApprovalForAll(address _operator, bool _approved) public virtual override{
        _setApprovalForAll(msg.sender,_operator,_approved);

    }
    
    function _setApprovalForAll(address owner,address operator,bool approved) internal virtual {
        require(owner != operator, "setting approval status for self");

        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool){
        _operatorApprovals[_owner][_operator];
    }

    function safeTranseferFrom(address from,address to,uint256 _id,uint256 value,bytes calldata _data)public virtual override {
        require(from == msg.sender || isApprovedForAll(from, msg.sender),"caller is not owner nor approved");
        require(to != address(0), "transfer to the zero address");

        uint fromBalance = _balances[_id][from];
        require(fromBalance >= value, "insufficient balance for transfer");
    
        _balances[_id][to] += value;
        _balances[_id][from] -= value;
    }

    function safeBatchTransferFrom(address from,address to,uint256[] memory _id,uint256[] memory _value,bytes memory _data) public virtual override {
        require(from == msg.sender || isApprovedForAll(from, msg.sender),"ERC1155: transfer caller is not owner nor approved");
        require(_id.length == _value.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

         address operator = msg.sender;
         _beforeTokenTransfer(operator,from,to,_id,_value,_data);

        for (uint256 i = 0; i<_id.length;i++){
	            uint256 id =_id[i];
	            uint256 value = _value[i];

	            uint256 fromBalance = _balances[id][from];
	            require(fromBalance >= value,"Not sufficient balance");
	            unchecked{
			            _balances[id][from]= fromBalance - value;
	    }
	_balances[id][to] += value;
    }
    emit TransferBatch(operator,from,to,_id,_value);

    _afterTokenTransfer(operator, from, to, _id, _value, _data);
    }

     function _mint(address to,uint256 _id,uint256 _value,bytes memory _data) public Owner {
         require(exists(_id)==false,"This token ID is already exits");
         _Id.push(_id);
        require(to != address(0), "mint to the zero address");

        address operator = msg.sender;
        uint256[] memory _ids = _asSingletonArray(_id);
        uint256[] memory amounts = _asSingletonArray(_value);

        _beforeTokenTransfer(operator, address(0), to, _ids, amounts, _data);

        _balances[_id][to] += _value;
        emit TransferSingle(operator, address(0), to, _id, _value);

        _afterTokenTransfer(operator, address(0), to, _ids, amounts, _data);

        // _doSafeTransferAcceptanceCheck(operator, address(0), to, _id, _value, _data);
    }

    function _mintBatch(address to,uint256[] memory _id,uint256[] memory _value,bytes memory _data)public Owner{
        require(to!=address(0),"mint to zero address");
        require(_id.length == _value.length,"ID and Amount length is not correct");

        address operator =msg.sender;

        _beforeTokenTransfer(operator,address(0),to,_id,_value,_data);

        for(uint256 i=0;i<_id.length; i++){
            _balances[_id[i]][to] += _value[i];
        }
        emit TransferBatch(operator,address(0),to,_id,_value);

        _afterTokenTransfer(operator,address(0),to,_id,_value,_data);
    }

    function _burn(address from,uint256 _id,uint256 _value) public {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(_id);
        uint256[] memory amounts = _asSingletonArray(_value);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[_id][from];
        require(fromBalance >= _value, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[_id][from] = fromBalance - _value;
        }

        emit TransferSingle(operator, from, address(0), _id, _value);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _burnBatch(address from,uint256[] memory _id,uint256[] memory _value) public {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(_id.length == _value.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, address(0), _id, _value, "");

        for (uint256 i = 0; i < _id.length; i++) {
            uint256 id = _id[i];
            uint256 amount = _value[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), _id, _value);

        _afterTokenTransfer(operator, from, address(0), _id, _value, "");
    }

    function Auction (address _owner,uint256 _id,uint256 _value,uint256 AuctionStartTime)public Owner {
        require(exists(_id),"This token ID is not exists");
        require(_value>0,"You did not mention any value");
        AuctionEnd= AuctionStartTime + block.timestamp;
        
    }

    function Bid(uint256 _id)public payable{
        require(exists(_id),"You cannot bit at this ID ");
        require(block.timestamp<AuctionEnd,"Auction is Already ended");

        require(msg.value > highBid,"The Bid is not high Enough");
		
		if( highBid != 0){
			returnsPending[highestBidder] += highBid;
            payable(owner).transfer(_id);
		}
		highestBidder = msg.sender;
		highBid = msg.value;
        emit HighbidIncereased(msg.sender,msg.value);
    }

    function Buy(uint256 _id,uint256 _value)public payable{
        require(exists(_id),"This is ID not exists");
        require(msg.value>1 ether,"You entered zero value");
        require(owner != msg.sender,"You already owned this token");
        _balances[_id][owner] += _value;
        _balances[_id][msg.sender] -= _value;
        payable(owner).transfer(msg.value);
        [_id][_value] = msg.value;
    }
        
              

    function sell(address to,uint256 _id,uint256 _value)public Owner{
        require(exists(_id),"This ID is not available");
        transfer(msg.sender,to,_id,_value);
    }

    function withdraw()public returns (bool) {
		uint bidAmount = returnsPending[msg.sender];
		if(bidAmount > 0) {
		
			// It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
			
			returnsPending[msg.sender] = 0;
			
			if (!payable(msg.sender).send(bidAmount)) {
                // No need to call throw here, just reset the amount owing
                returnsPending[msg.sender] = bidAmount;
                return false;
            }
        }
        return true;
    }

    function transfer(address from, address to, uint _id, uint _value) private {
        require(to!=address(0),"transfer to zero address");
        _balances[_id][from] -= _value;
        _balances[_id][to] += _value;
        emit TransferSingle(msg.sender, from, to, _id, _value);
    }


    /*Useful for scenarios such as preventing trades until the end of an evaluation period,
     or having an emergency switch for freezing all token transfers in the event of a large bug.*/
    function _beforeTokenTransfer(address operator,address from,address to,uint256[] memory _id,uint256[] memory _value,bytes memory _data) internal virtual {

    }

    function _afterTokenTransfer(address operator,address from,address to,uint256[] memory _id,uint256[] memory _value,bytes memory _data) internal virtual {

    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function exists(uint256 _id) public view returns(bool){
        for (uint i=0;i<_Id.length;i++){
            if(_id == _Id[i]){
                return true;
            }
            return false;

        }
    }


    fallback()external payable{}


}

