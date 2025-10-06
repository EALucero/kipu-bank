// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title KipuBank
 * @notice Bóveda personal con límite de retiro y manejo de errores
 * @author EALucero
 */
contract KipuBank {
    // ─────── CONSTANTES & VARIABLES IMMUTABLES ──────── //

    /// @notice Umbral máximo de retiro por transacción
    uint256 public immutable withdrawalLimit;
    /// @notice Límite global de depósitos en el banco
    uint256 public immutable bankCap;

    // ─────── VARIABLES DE ESTADO ──────── //

    /// @notice Total de ETH depositado en el contrato
    uint256 public totalDeposited;
    /// @notice Número total de depósitos realizados
    uint256 public depositCount;
    /// @notice Número total de retiros realizados
    uint256 public withdrawalCount;
    /// @notice Mapeo de bóvedas personales por usuario
    mapping(address => uint256) public vaults;

    // ─────── EVENTOS ──────── //

    /// @notice Emitido cuando un usuario deposita ETH
    event Deposit(address indexed user, uint256 amount);
    /// @notice Emitido cuando un usuario retira ETH
    event Withdrawal(address indexed user, uint256 amount);

    // ─────── ERRORES PERSONALIZADOS ──────── //

    /// @notice Se lanza si el depósito excede el límite global
    error DepositLimitExceeded();
    /// @notice Si el usuario intenta retirar más de lo que tiene
    error InsufficientBalance();
    /// @notice Si la transferencia de ETH falla
    error TransferFailed();
    /// @notice Si el depósito excede el límite permitido
    error WithdrawalLimitExceeded();
    /// @notice Si el límite de banco es inválido
    error InvalidBankCap(uint256 provided);
    /// @notice Si se llama al fallback con datos no reconocidos
    error InvalidFallbackCall();
    /// @notice Si los parámetros del constructor son inconsistentes
    error InvalidParameters();
    /// @notice Si el límite de retiro es inválido
    error InvalidWithdrawalLimit(uint256 provided);

    // ─────── CONSTRUCTOR ──────── //

    /**
     * @param _withdrawalLimit Límite por retiro
     * @param _bankCap Límite global de depósitos
     */
    constructor(uint256 _withdrawalLimit, uint256 _bankCap) {
        if (_withdrawalLimit == 0) revert InvalidWithdrawalLimit(_withdrawalLimit);
        if (_bankCap == 0) revert InvalidBankCap(_bankCap);
        if (_withdrawalLimit > _bankCap) revert InvalidParameters();

        withdrawalLimit = _withdrawalLimit;
        bankCap = _bankCap;
    }

    // ─────── MODIFICADORES ──────── //

    /// @notice Verifica que el depósito no exceda el límite global
    modifier withinBankCap(uint256 amount) {
        if (totalDeposited + amount > bankCap) revert DepositLimitExceeded();
        _;
    }

    // ─────── FUNCIONES ──────── //

    /// @notice Maneja depósitos directos de ETH sin datos
    receive() external payable withinBankCap(msg.value) {
        _handleDeposit(msg.sender, msg.value);
    }

    /// @notice Rechaza llamadas con datos no reconocidos
    fallback() external payable {
        revert InvalidFallbackCall();
    }

    /// @notice Deposita ETH en la bóveda personal
    function deposit() external payable withinBankCap(msg.value) {
        _handleDeposit(msg.sender, msg.value);
    }

    /// @notice Retira ETH de la bóveda personal
    /// @param amount Monto a retirar
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

    /// @notice Retorna el balance de la bóveda del usuario
    /// @param user Dirección del usuario
    /// @return balance ETH en bóveda
    function getVaultBalance(address user) external view returns (uint256 balance) {
        return vaults[user];
    }

    /// @notice Retorna estadísticas globales del contrato
    /// @return totalDeposits Número total de depósitos
    /// @return totalWithdrawals Número total de retiros
    function getStats() external view returns (uint256 totalDeposits, uint256 totalWithdrawals) {
        return (depositCount, withdrawalCount);
    }

    // ─────── FUNCIONES INTERNAS & PRIVADAS ──────── //

    /// @notice Lógica centalizada para depósitos
    /// @dev Sigue el patrón checks-effects-interactions
    function _handleDeposit(address user, uint256 amount) internal {
        vaults[user] += amount;
        totalDeposited += amount;

        unchecked {depositCount++;}

        emit Deposit(user, amount);
    }

    /// @dev Maneja transferencias nativas de forma segura
    /// @param to Dirección de destino
    /// @param amount Monto a transferir
    function _safeTransfer(address to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert TransferFailed(); 
    }
}