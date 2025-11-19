# Agent Guidelines for Nexus Contracts

## Commands
- **Build**: `forge build`
- **Test all**: `forge test`
- **Test single**: `forge test --match-test <TestName>`
- **Format**: `forge fmt`
- **Lint**: `forge fmt --check`
- **Security**: `slither .` (excludes assembly, low-level calls, etc.)

## Code Style
- **Solidity version**: 0.8.30
- **License**: MIT (SPDX header required)
- **Imports**: Named imports with braces, group by external/internal
- **Naming**: camelCase for functions/variables, PascalCase for contracts/structs, UPPER_CASE for constants
- **Events**: Comprehensive logging for all state changes
- **Error handling**: Use custom errors, avoid magic numbers
- **Types**: Explicit types, avoid implicit conversions
- **Constants**: Use immutable for deployment-time constants
- **Structs**: Group related data, use memory for function parameters
- **Functions**: External/public first, then internal/private; use view/pure when possible