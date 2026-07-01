// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPaymaster} from "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ICreditRegistry} from "./interfaces/ICreditRegistry.sol";

contract CreditLinePaymaster is IPaymaster, Ownable, ReentrancyGuard {

    uint256 public constant CREDIT_THRESHOLD  = 700;
    uint256 public constant MAX_DEBT_PER_AGENT = 100_000;

    IEntryPoint public immutable entryPoint;
    ICreditRegistry public creditRegistry;

    mapping(address => uint256) public outstandingDebt;
    mapping(address => bool)    public blacklisted;
    uint256 public totalGasSponsored;

    event GasSponsored(address indexed agent, uint256 maxCost, uint256 score);
    event DebtRepaid(address indexed agent, uint256 amount);
    event AgentBlacklisted(address indexed agent);

    error ScoreBelowThreshold(uint256 score, uint256 required);
    error CreditLimitExceeded(uint256 outstanding, uint256 requested, uint256 limit);
    error AgentIsBlacklisted(address agent);
    error OnlyEntryPoint();

    constructor(
        IEntryPoint _entryPoint,
        ICreditRegistry _creditRegistry,
        address _owner
    ) Ownable(_owner) {
        entryPoint    = _entryPoint;
        creditRegistry = _creditRegistry;
    }

    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256 maxCost
    ) external override returns (bytes memory context, uint256 validationData) {
        if (msg.sender != address(entryPoint)) revert OnlyEntryPoint();

        address agent = userOp.sender;
        if (blacklisted[agent]) revert AgentIsBlacklisted(agent);

        uint256 score = creditRegistry.getScore(agent);
        if (score < CREDIT_THRESHOLD) revert ScoreBelowThreshold(score, CREDIT_THRESHOLD);

        uint256 creditLine = (score - 300) * 100;
        if (creditLine > MAX_DEBT_PER_AGENT) creditLine = MAX_DEBT_PER_AGENT;

        uint256 debt = outstandingDebt[agent];
        if (debt + maxCost > creditLine) revert CreditLimitExceeded(debt, maxCost, creditLine);

        outstandingDebt[agent] += maxCost;
        totalGasSponsored      += maxCost;

        emit GasSponsored(agent, maxCost, score);
        context        = abi.encode(agent, maxCost);
        validationData = 0;
    }

    function postOp(
        PostOpMode,
        bytes calldata context,
        uint256 actualGasCost
    ) external override {
        if (msg.sender != address(entryPoint)) revert OnlyEntryPoint();
        (address agent, uint256 maxCost) = abi.decode(context, (address, uint256));
        if (actualGasCost < maxCost) {
            uint256 refund = maxCost - actualGasCost;
            if (outstandingDebt[agent] >= refund) {
                outstandingDebt[agent] -= refund;
                totalGasSponsored      -= refund;
            }
        }
    }

    function repayDebt(address agent) external payable nonReentrant {
        uint256 debt = outstandingDebt[agent];
        require(debt > 0, "no debt");
        require(msg.value >= debt, "insufficient");
        outstandingDebt[agent] = 0;
        emit DebtRepaid(agent, debt);
        if (msg.value > debt) payable(msg.sender).transfer(msg.value - debt);
    }

    function blacklistAgent(address agent) external onlyOwner {
        blacklisted[agent] = true;
        emit AgentBlacklisted(agent);
    }

    function deposit() external payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    function withdrawTo(address payable dest, uint256 amount) external onlyOwner {
        entryPoint.withdrawTo(dest, amount);
    }

    function updateCreditRegistry(ICreditRegistry r) external onlyOwner {
        creditRegistry = r;
    }

    function creditStatus(address agent) external view returns (
        uint256 score, uint256 creditLine, uint256 debt,
        uint256 available, bool eligible
    ) {
        score      = creditRegistry.getScore(agent);
        creditLine = score >= CREDIT_THRESHOLD ? (score - 300) * 100 : 0;
        if (creditLine > MAX_DEBT_PER_AGENT) creditLine = MAX_DEBT_PER_AGENT;
        debt      = outstandingDebt[agent];
        available = creditLine > debt ? creditLine - debt : 0;
        eligible  = score >= CREDIT_THRESHOLD && !blacklisted[agent];
    }

    function getDeposit() external view returns (uint256) {
        return entryPoint.balanceOf(address(this));
    }

    receive() external payable {}
}
