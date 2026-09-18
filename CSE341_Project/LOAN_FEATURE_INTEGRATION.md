# Loan Management Feature integration

`loan_management.asm` is Feature 2 only: it provides the required loan menu and procedures, plus loan-specific arrays. It intentionally does **not** create a main program, account arrays, login state, or a separate transaction history.

When the shared Mini ATM code arrives:

1. Paste the module's data declarations into the existing `.DATA` section and procedures into its `.CODE` section.
2. Update the three adapter names at the top of the module:
   - `LOAN_ACCOUNT_INDEX` → existing zero-based logged-in account index (`DW`)
   - `LOAN_BALANCES` → existing balance array
   - `LOAN_PUSH_TX` → existing transaction-push procedure
3. Ensure `MAX_ACCOUNTS` matches the team program.
4. Map `LOAN_TX_APPROVED`, `LOAN_TX_REPAYMENT`, and `LOAN_TX_PAID` to its transaction identifiers. The module supplies the event in `AL` and its associated amount in `DX:BX` before the call.
5. Add `CALL LOAN_MENU` as the handler for the ATM's Loan Management option.

The default adapter assumes balances are unsigned `DD` entries so repayments and the `500000` Home Loan limit are representable. If the project currently keeps balances as `DW`, adapt only `GET_BALANCE` and `DEDUCT_BALANCE`; upgrading the shared balance array to `DD` is the safer merge.

Important merge note: do not introduce another `PUSH_TRANSACTION`. The feature calls the team's existing one. Also rename `LOAN_PRINT` if that exact macro name is already used.
