// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title BlockFractal
 * @dev A modular fractal registry for linking parent-child content hashes on-chain
 * @notice Users can create fractal nodes, link children, and explore relationships between hashes
 */
contract BlockFractal {
    
    // State variables
    address public owner;
    uint256 public totalNodes;
    
    struct FractalNode {
        address creator;
        bytes32 dataHash;
        uint256 createdAt;
        uint256 parentId;      // 0 for root nodes (or use a sentinel)
        bool isRoot;
        bool isActive;
        string label;
    }
    
    // nodeId => FractalNode
    mapping(uint256 => FractalNode) public nodes;
    
    // parentId => childIds
    mapping(uint256 => uint256[]) public childrenOf;
    
    // creator => nodeIds
    mapping(address => uint256[]) public createdBy;
    
    // Events
    event NodeCreated(
        uint256 indexed nodeId,
        uint256 indexed parentId,
        address indexed creator,
        bytes32 dataHash,
        string label,
        bool isRoot,
        uint256 timestamp
    );
    
    event NodeDeactivated(
        uint256 indexed nodeId,
        address indexed caller,
        uint256 timestamp
    );
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    modifier nodeExists(uint256 nodeId) {
        require(nodes[nodeId].creator != address(0), "Node does not exist");
        _;
    }
    
    modifier onlyNodeCreator(uint256 nodeId) {
        require(nodes[nodeId].creator == msg.sender, "Not node creator");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Function 1: Create a root fractal node
     * @param dataHash The hash representing this fractal node
     * @param label A human-readable label or description
     * @notice Root nodes have no parent and can serve as fractal origins
     */
    function createRootNode(bytes32 dataHash, string calldata label) external returns (uint256 nodeId) {
        require(dataHash != bytes32(0), "Invalid hash");
        
        nodeId = totalNodes;
        totalNodes += 1;
        
        nodes[nodeId] = FractalNode({
            creator: msg.sender,
            dataHash: dataHash,
            createdAt: block.timestamp,
            parentId: 0,
            isRoot: true,
            isActive: true,
            label: label
        });
        
        createdBy[msg.sender].push(nodeId);
        
        emit NodeCreated(
            nodeId,
            0,
            msg.sender,
            dataHash,
            label,
            true,
            block.timestamp
        );
    }
    
    /**
     * @dev Function 2: Create a child fractal node under a parent
     * @param parentId ID of the parent node
     * @param dataHash Hash of the child content
     * @param label Label or description for the child node
     * @notice Parent must exist and be active
     */
    function createChildNode(
        uint256 parentId,
        bytes32 dataHash,
        string calldata label
    )
        external
        nodeExists(parentId)
        returns (uint256 nodeId)
    {
        require(dataHash != bytes32(0), "Invalid hash");
        require(nodes[parentId].isActive, "Parent inactive");
        
        nodeId = totalNodes;
        totalNodes += 1;
        
        nodes[nodeId] = FractalNode({
            creator: msg.sender,
            dataHash: dataHash,
            createdAt: block.timestamp,
            parentId: parentId,
            isRoot: false,
            isActive: true,
            label: label
        });
        
        childrenOf[parentId].push(nodeId);
        createdBy[msg.sender].push(nodeId);
        
        emit NodeCreated(
            nodeId,
            parentId,
            msg.sender,
            dataHash,
            label,
            false,
            block.timestamp
        );
    }
    
    /**
     * @dev Function 3: Deactivate a node
     * @param nodeId ID of the node
     * @notice Only node creator can deactivate their node
     */
    function deactivateNode(uint256 nodeId)
        external
        nodeExists(nodeId)
        onlyNodeCreator(nodeId)
    {
        require(nodes[nodeId].isActive, "Already inactive");
        nodes[nodeId].isActive = false;
        
        emit NodeDeactivated(nodeId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Function 4: Get node details
     * @param nodeId ID of the node
     */
    function getNode(uint256 nodeId)
        external
        view
        nodeExists(nodeId)
        returns (
            address creator,
            bytes32 dataHash,
            uint256 createdAt,
            uint256 parentId,
            bool isRoot,
            bool isActive,
            string memory label
        )
    {
        FractalNode memory n = nodes[nodeId];
        return (
            n.creator,
            n.dataHash,
            n.createdAt,
            n.parentId,
            n.isRoot,
            n.isActive,
            n.label
        );
    }
    
    /**
     * @dev Function 5: Get children IDs of a node
     * @param nodeId Parent node ID
     */
    function getChildren(uint256 nodeId)
        external
        view
        nodeExists(nodeId)
        returns (uint256[] memory)
    {
        return childrenOf[nodeId];
    }
    
    /**
     * @dev Function 6: Get all node IDs created by a specific address
     * @param user Address of the user
     */
    function getCreatedBy(address user) external view returns (uint256[] memory) {
        return createdBy[user];
    }
    
    /**
     * @dev Transfer contract ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
    
    /**
     * @dev Get basic stats about the fractal graph
     * @return nodeCount Total created nodes
     */
    function getStats() external view returns (uint256 nodeCount) {
        return totalNodes;
    }
}
