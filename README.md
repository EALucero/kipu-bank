# KipuBank

KipuBank es un contrato que permite a los usuarios depositar y retirar ETH con restricciones de su bóveda.

## 📋 Características

- Depósitos de ETH en bóvedas personales.
- Retiros limitados por transacción.
- Límite global de depósitos (`bankCap`).
- Seguridad con errores personalizados.
- Eventos en depósitos y retiros.
- Contadores de operaciones.

## 🛠️ Despliegue

1. Clona el repositorio:
   git clone https://github.com/EALucero/kipu-bank.git
   cd kipu-bank

## ☝🏼 Como interactuar
- Deployar en Remix.
- La variable bankCap y por extensión withdrawalLimit, deben ser seteados antes de deployar. En este caso use el límite recomendado de 10 ETH (1e19 wei) para desarrollo.
- Depositar y extraer dentro de ese rango.
- Se utiliza depositCount para conocer el número de depósitos y withdrawalCount para el de retiros, también se puede acceder a los 2 datos con getStats.
- Con totalDeposited sabremos la cantidad de ETH guardado en KipuBank.
- Se utiliza vaults y la dirección del cliente para mostrar información específica del cliente y si quiere saber su balance, getVaultBalance. Devuelven la misma info, pero pensandolo utilizado junto a una extructura más amigable al cliente (front), su separación ayudaría a la lógica a implementar.

## ✅ Verificación de contrato
https://sepolia.etherscan.io/address/0xbb74c1cdf4417606dfd634ef87c0fe376ca90a7a
