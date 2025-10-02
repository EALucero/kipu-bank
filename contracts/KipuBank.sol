// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title KipuBank
 * @notice Bóveda personal con límite de retiro y manejo de errores
 * @author EALucero
 */
contract KipuBank {
    // ─────── CONSTANTES & VARIABLES IMMUTABLE ────────

    /// @notice Umbral máximo de retiro por transacción
    uint256 public immutable withdrawalLimit;

    /// @notice Límite global de depósitos en el banco
    uint256 public immutable bankCap;

    // ─────── VARIABLES DE ESTADO ────────

    /// @notice Total de ETH depositado en el contrato
    uint256 public totalDeposited;

    /// @notice Número total de depósitos realizados
    uint256 public depositCount;

    /// @notice Número total de retiros realizados
    uint256 public withdrawalCount;

    /// @notice Mapeo de bóvedas personales por usuario
    mapping(address => uint256) public vaults;

    // ─────── EVENTOS ────────

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event UnexpectedCall(address sender, uint256 value, bytes data);

    // ─────── ERRORES PERSONALIZADOS ────────

    error DepositLimitExceeded();
    error InsufficientBalance();
    error WithdrawalLimitExceeded();

    // ─────── CONSTRUCTOR ────────

    constructor(uint256 _withdrawalLimit, uint256 _bankCap) {
        require(_withdrawalLimit > 0, "Limite de retiro debe ser > 0");
        require(_bankCap > 0, "Limite de banco debe ser > 0");
        withdrawalLimit = _withdrawalLimit;
        bankCap = _bankCap;
    }

    // ─────── MODIFICADORES ────────

    modifier withinBankCap(uint256 amount) {
        if (totalDeposited + amount > bankCap) revert DepositLimitExceeded();
        _;
    }

    // ─────── FUNCIONES ────────

    receive() external payable withinBankCap(msg.value) {
        _handleDeposit(msg.sender, msg.value);
    }

    fallback() external payable {
        emit UnexpectedCall(msg.sender, msg.value, msg.data);
        revert("Fallback: llamada invalida");
    }

    function deposit() external payable withinBankCap(msg.value) {
        _handleDeposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        if (amount > withdrawalLimit) revert WithdrawalLimitExceeded();

        uint256 userBalance = vaults[msg.sender];
        if (userBalance < amount) revert InsufficientBalance();

        vaults[msg.sender] = userBalance - amount;
        totalDeposited -= amount;

        unchecked {withdrawalCount++;}

        _safeTransfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    function getVaultBalance(address user) external view returns (uint256 balance) {
        return vaults[user];
    }

    function getStats() external view returns (uint256 totalDeposits, uint256 totalWithdrawals) {
        return (depositCount, withdrawalCount);
    }

    // ─────── FUNCIONES INTERNAS & PRIVADAS ────────

    function _handleDeposit(address user, uint256 amount) internal {
        vaults[user] += amount;
        totalDeposited += amount;

        unchecked {depositCount++;}

        emit Deposit(user, amount);
    }

    function _safeTransfer(address to, uint256 amount) private {
        payable(to).transfer(amount);
    }
}