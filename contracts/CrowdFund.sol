//SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;
pragma experimental ABIEncoderV2;
import "hardhat/console.sol";
//import "@openzeppelin/contracts/utils/Strings.sol";


contract CrowdFund {
    address public owner;
    uint public projectTax;
    uint public projectCount;
    uint public balance;
    statsStruct public stats;
    projectStruct[] projects;

    mapping(address => projectStruct[]) projectsOf;
    mapping(uint => backerStruct[]) backersOf;
    mapping(uint => bool) public projectExist;

    enum statusEnum {
        OPEN,
        APPROVED,
        REVERTED,
        DELETED,
        PAIDOUT
    }

    struct statsStruct {
        uint totalProjects;
        uint totalBacking;
        uint totalDonations;
    }

    struct backerStruct {
        address owner;
        uint contribution;
        uint timestamp;
        bool refunded;
    }

    struct projectStruct {
        uint id;
        address owner;
        string title;
        string description;
        string imageURL;
        uint cost;
        uint raised;
        uint timestamp;
        uint expiresAt;
        uint backers;
        statusEnum status;
    }

    modifier ownerOnly(){
        require(msg.sender == owner, "Owner reserved only");
        _;
    }

    event Action (
        uint256 id,
        string actionType,
        address indexed executor,
        uint256 timestamp
    );

    constructor(uint _projectTax) {
        owner = msg.sender;
        projectTax = _projectTax;
    }

    function createProject(
        string memory title,
        string memory description,
        string memory imageURL,
        uint cost,
        uint expiresAt
    ) public returns (bool) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(bytes(imageURL).length > 0, "ImageURL cannot be empty");
        require(cost > 0 ether, "Cost cannot be zero");

        projectStruct memory project;
        project.id = projectCount;
        project.owner = msg.sender;
        project.title = title;
        project.description = description;
        project.imageURL = imageURL;
        project.cost = cost;
        project.timestamp = block.timestamp;
        project.expiresAt = expiresAt;

        projects.push(project);
        projectExist[projectCount] = true;
        projectsOf[msg.sender].push(project);
        stats.totalProjects += 1;

        return true;
    }

    function updateProject(
        uint id,
        string memory title,
        string memory description,
        string memory imageURL,
        uint cost,
        uint expiresAt

    ) public returns (bool) {
        require(msg.sender == projects[id].owner, "Unauthorized Entity");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(bytes(imageURL).length > 0, "ImageURL cannot be empty");

        projects[id].title = title;
        projects[id].description = description;
        projects[id].imageURL = imageURL;
        projects[id].expiresAt = expiresAt;

        if(cost > projects[id].cost && projects[id].status == statusEnum.APPROVED) {
            projects[id].status = statusEnum.OPEN;
            
        }
        if(cost <= projects[id].raised && projects[id].status == statusEnum.OPEN) {
            projects[id].status = statusEnum.APPROVED;
        }

        projects[id].cost = cost;

        emit Action (
            id,
            "PROJECT UPDATED",
            msg.sender,
            block.timestamp
        );

        return true;
    }

    function deleteProject(uint id) public returns (bool) {
        require(projects[id].status == statusEnum.OPEN, "Project no longer opened");
        require(msg.sender == projects[id].owner, "Unauthorized Entity");

        projects[id].status = statusEnum.DELETED;
        performRefund(id);

        emit Action (
            id,
            "PROJECT DELETED",
            msg.sender,
            block.timestamp
        );

        return true;
    }

    function performRefund(uint id) internal {
        for(uint i = 0; i < backersOf[id].length; i++) {

            address _owner = backersOf[id][i].owner;
            uint _contribution = backersOf[id][i].contribution;
            
            backersOf[id][i].refunded = true;
            backersOf[id][i].timestamp = block.timestamp;
            payTo(_owner, _contribution);

            stats.totalBacking -= 1;
            stats.totalDonations -= _contribution;
        }
    }
    function preformRefundTo(uint id, address initiator) public payable returns (bool) {
        for(uint i = 0; i < backersOf[id].length; i++) {

            if(backersOf[id][i].owner == initiator) {
            
                address _owner = backersOf[id][i].owner;
                uint _contribution = backersOf[id][i].contribution;

                backersOf[id][i].refunded = true;
                backersOf[id][i].timestamp = block.timestamp;

                projects[id].backers -=1;
                projects[id].raised -= _contribution;

                payTo(_owner, _contribution);

                stats.totalBacking -= 1;
                stats.totalDonations -= _contribution;

                return true;
            }
        }
        emit Action (
            id,
            "PROJECT DELETED",
            msg.sender,
            block.timestamp
        );
        return false;

    }

    function backProject(uint id) public payable returns (bool) {
        require(msg.value > 0 ether, "Ether must be greater than zero");
        require(projectExist[id], "Project not found");
        require(projects[id].status == statusEnum.OPEN, "Project no longer opened");

        bool isBacker = false;
        uint index = 0;
        for(uint i = 0; i < backersOf[id].length; i++) {

            if(backersOf[id][i].owner == msg.sender) {
                isBacker = true;
                index = i;
            }
        }
        
        if(isBacker) {

            if(backersOf[id][index].refunded) {
                stats.totalBacking += 1;
                projects[id].backers += 1;
                backersOf[id][index].contribution = msg.value;

            }
            else{
                backersOf[id][index].contribution += msg.value;
            }
            
            backersOf[id][index].timestamp = block.timestamp;
            backersOf[id][index].refunded = false; 
        }
        else {
            stats.totalBacking += 1; 
            projects[id].backers += 1;
            backersOf[id].push(
                backerStruct(
                    msg.sender,
                    msg.value,
                    block.timestamp,
                    false
                )
            );

        }
        stats.totalDonations += msg.value;
        projects[id].raised += msg.value;

    
        if(projects[id].raised >= projects[id].cost) {
            projects[id].status = statusEnum.APPROVED;
            balance += projects[id].raised;
            return true;
        }

        if(block.timestamp >= projects[id].expiresAt) {
            projects[id].status = statusEnum.REVERTED;
            performRefund(id);
            return true;
        }

        emit Action (
            id,
            "PROJECT BACKED",
            msg.sender,
            block.timestamp
        );

        return true;
    }

    function transferDonatorFunds(uint fromProjectId, uint toProjectId) external payable returns (bool) {
        require(projectExist[fromProjectId], "Project not found");
        require(projectExist[toProjectId], "Project not found");
        require(projects[fromProjectId].raised > 0, "Nothing raised");

        uint contribution = 0;
        uint index = 0;
        for(uint i = 0 ; i< backersOf[fromProjectId].length ; i++) {

            if(backersOf[fromProjectId][i].owner == msg.sender) {
                contribution = backersOf[fromProjectId][i].contribution;
                index = i;
            }
        }

        projects[fromProjectId].raised -= contribution;
        projects[fromProjectId].backers -= 1;
        backersOf[fromProjectId][index].refunded = true;

        projects[toProjectId].raised += contribution;
        projects[toProjectId].backers += 1;

        backersOf[toProjectId].push(
            backerStruct(
                msg.sender,
                contribution,
                block.timestamp,
                false
            )
        );

        if(projects[toProjectId].raised >= projects[toProjectId].cost) {
            projects[toProjectId].status = statusEnum.APPROVED;
            balance += projects[toProjectId].raised;
            projects[toProjectId].status = statusEnum.APPROVED;
            //performPayout(toProjectId);
            return true;
        }

        return true;
    }
    // function claimFunds(uint id) public payable returns(bool) {
    //     require(projects[id].status == statusEnum.APPROVED, "Project not APPROVED");

    //     performPayout(id);

    // }

    function performPayout(uint id) internal {
        uint raised = projects[id].raised;
        uint tax = (raised * projectTax) / 100;

        projects[id].status = statusEnum.PAIDOUT;

        payTo(projects[id].owner, (raised - tax));
        payTo(owner, tax);

        balance -= projects[id].raised;
    }

    function requestRefund(uint id) public returns (bool) {
        require(
            projects[id].status != statusEnum.REVERTED ||
            projects[id].status != statusEnum.DELETED,
            "Project not marked as revert or delete"
        );
        
        projects[id].status = statusEnum.REVERTED;
        performRefund(id);
        return true;
    }

    function payOutProject(uint id) public returns (bool) {
        require(projects[id].status == statusEnum.APPROVED, "Project not APPROVED");
        require(
            msg.sender == projects[id].owner ||
            msg.sender == owner,
            "Unauthorized Entity"
        );

        performPayout(id);
        return true;
    }

    function checkProjectStatusType() public {
        for(uint i = 0 ; i< projects.length ; i++) {
            if(projects[i].status == statusEnum.OPEN && block.timestamp >= projects[i].expiresAt) {

                projects[i].status = statusEnum.REVERTED;
                performRefund(i);
            }
        }
    }

    function changeTax(uint _taxPct) public ownerOnly {
        projectTax = _taxPct;
    }

    function getProject(uint id) public view returns (projectStruct memory) {
        require(projectExist[id], "Project not found");

        return projects[id];
    }
    
    function getProjects() public view returns (projectStruct[] memory) {
        return projects;
    }
    
    function getBackers(uint id) public view returns (backerStruct[] memory) {
        return backersOf[id];
    }
    
    function getUnbackedProjects(address backer) public view returns (projectStruct[] memory) {
    projectStruct[] memory unbackedProjects = new projectStruct[](projectCount);
    uint unbackedCount = 0;

    for (uint i = 0; i < projects.length; i++) {
        bool found = false;
        for (uint j = 0; j < backersOf[projects[i].id].length; j++) {
            if (backersOf[projects[i].id][j].owner == backer) {
                found = true;
                break;
            }
        }

        if (!found) {
            unbackedProjects[unbackedCount] = projects[i];
            unbackedCount++;
        }
    }

    projectStruct[] memory result = new projectStruct[](unbackedCount);
    for (uint i = 0; i < unbackedCount; i++) {
        result[i] = unbackedProjects[i];
    }

    return result;
}

    function payTo(address to, uint amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success);
    }
}