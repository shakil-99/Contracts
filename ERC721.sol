// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 is IERC165{
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFroms(address _from, address _to, uint256 _tokenId, bytes memory data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

}

interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint tokenId,bytes calldata data) external view returns (bytes4);
}

contract ERC721 is IERC721{
    using Address for address;

   
    mapping(uint256=>address)private _owners;
    mapping(address=>uint256)private _balances;
    mapping(uint256=>address)private _tokenApprovals;
    mapping(address=>mapping(address=>bool)) private _operatorApprovals;

    
    function supportsInterface(bytes4 interfaceId)external pure override returns (bool){
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
    function balanceOf(address _owner) external view override returns (uint256){
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balances[_owner];
        //Returns the number of NFTs in `owner’s account.
    }

    function ownerOf(uint256 _tokenId) external view override returns (address){
        address _owner = _owners[_tokenId];
        require(_owner != address(0), "Insufficient token");
        return _owner;
        //Returns the owner of the NFT specified by tokenId.
    }

	
	function setApprovalForAll(address operator,bool approved) external override{
		_operatorApprovals[msg.sender][operator] = approved;
		emit ApprovalForAll(msg.sender,operator,approved);
	}
    function isApprovedForAll(address owner, address operator)external view override returns (bool){
        return _operatorApprovals[owner][operator];
    }

	
	function getApproved(uint tokenId) external view override returns(address){
		require(_owners[tokenId] != address(0),"token doesn't exit");
		return _tokenApprovals[tokenId];
	}
	
	function _approve(address owner,address to,uint tokenId)private {
		_tokenApprovals[tokenId] = to;
		emit Approval(owner,to,tokenId);
	}
	
	function approve(address to, uint tokenId) external override{
		address owner = _owners[tokenId];
		require(msg.sender == owner,"Only Owner can Approve");
		_approve(owner,to,tokenId);
	}

    function _isApprovedOrOwner(address owner,address spender,uint tokenId) private view returns (bool) {
        return (spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender]);
    }


    function _transfer(address owner,address from,address to,uint tokenId) private{
		require(from == owner,"You are not Owner");
		require(to != address(0), "Transefer to zero address");
		_approve(owner,address(0),tokenId);
		
		_balances[from] -=1;
		_balances[to] += 1;
		
		emit Transfer(from, to , tokenId);
	}
	
	function transferFrom(address from,address to,uint tokenId)external override {
		address owner = _owners[tokenId];
		require(_isApprovedOrOwner(owner,msg.sender,tokenId),"Only Owner can access");
		_transfer(owner ,from,to,tokenId);
	}

    function _safeTransfer(address owner, address from,address to, uint tokenId,bytes memory _data) private{
		_transfer(owner,from,to,tokenId);
		// require(onERC721Received(from,to,tokenId,_data),"you are not ERC721 Receiver");
	}
	
	// function onERC721Received(address from,address to,uint tokenId,bytes memory _data)public override view returns (bool){
	// 	if (to.isContract()){
	// 		return IERC721Receiver(to).onERC721Received(msg.sender,from,tokenId,_data) == IERC721Receiver.onERC721Received.selector;
	// 	}
	// 	else{
	// 		return true;
	// 	}
	// }
	
	function safeTransferFroms(address from,address to,uint tokenId,bytes memory _data) public override  {
        address owner = _owners[tokenId];
        require(_isApprovedOrOwner(owner, msg.sender, tokenId), "not owner nor approved");
        _safeTransfer(owner, from, to, tokenId, _data);
    }

    function safeTransferFrom(address from,address to,uint tokenId) external override {
        safeTransferFroms(from, to, tokenId, "");
    }
	
	function mint(address to,uint tokenId) external{
		require(to != address(0),"mint at zero address");
		require(_owners[tokenId] == address(0),"already token has been minted");
		_balances[to] +=1;
		_owners[tokenId] = to;
		
		emit Transfer(address(0),to,tokenId);
	}
	
	function burn(uint tokenId) external{
		address owner = _owners[tokenId];
		_approve(owner,address(0),tokenId);
		_balances[owner]-=1;
		delete _owners[tokenId];
		
		emit Transfer(owner,address(0),tokenId);
	}


}