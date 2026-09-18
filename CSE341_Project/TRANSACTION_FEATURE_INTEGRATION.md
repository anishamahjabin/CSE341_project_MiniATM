# Transaction History & Account Summary integration

`transaction_history.asm` is Feature 6 only. It provides the **one shared** transaction stack plus `TRANSACTION_MENU`, history display, account summary, and per-account statistics.

It is designed to merge after `loan_management.asm`; it intentionally reuses that module's `LOAN_PRINT`, `READ_DWORD`, `PRINT_DWORD`, `GET_BALANCE`, and `VIEW_LOAN` rather than redeclaring the same helpers or loan data.

## Merge steps

1. Paste its data and code into the existing ATM program (or include the file according to the project layout).
2. Set `TX_ACCOUNT_INDEX` to the real logged-in account-index variable and `TX_ACCOUNT_IDS` to the existing `accountIDs` array. The default expects word-sized account IDs.
3. Keep exactly one `PUSH_TRANSACTION`: this module's procedure is the common stack mechanism for the whole project. Do not add a second history stack.
4. Update every completed deposit, withdrawal, and transfer to call it once with this convention:

   ```asm
   ; AL = TX_DEPOSIT / TX_WITHDRAWAL / TX_TRANSFER
   ; DX:BX = completed amount (DX high word, BX low word)
   CALL PUSH_TRANSACTION
   ```

   The logged-in account is recorded automatically. The Loan feature uses its existing IDs 31, 32, and 33.
5. Add `CALL TRANSACTION_MENU` to the main ATM menu's transaction/history option.

`transactionTop` is a count, so entries always occupy `0 .. transactionTop-1`. `DISPLAY_HISTORY` reads them backwards without popping, which gives genuine newest-first LIFO history and avoids reading beyond the valid range.
