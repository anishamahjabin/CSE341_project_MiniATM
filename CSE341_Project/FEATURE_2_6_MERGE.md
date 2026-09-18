# Feature 2 + Feature 6 merged integration

The two features are now integrated through one transaction-stack contract:

```text
Loan Management                         Transaction History & Summary
---------------                         -----------------------------
APPLY_LOAN      ── LOAN APPROVED ───▶  PUSH_TRANSACTION
REPAY_LOAN      ── LOAN REPAYMENT ──▶  transactionType[]
REPAY_LOAN      ── LOAN PAID ────────▶  transactionAmount[]
                                         transactionAccount[]
                                         transactionTop
                                              │
                                              ├── DISPLAY_HISTORY (newest first)
                                              └── ACCOUNT_SUMMARY / statistics
```

## Paste order in the shared ATM source

There is no shared ATM program in this workspace yet, so do **not** paste the two source files one after the other unchanged. Each file marks its data and code portions. Merge them in this order:

```asm
; Existing shared .DATA section
; 1. Data declarations from loan_management.asm
; 2. Data declarations from transaction_history.asm

; Existing shared .CODE section
; 3. Procedures from loan_management.asm
; 4. Procedures from transaction_history.asm
```

Keep just one stack procedure: `PUSH_TRANSACTION` from `transaction_history.asm`.

## Shared transaction call contract

All completed transactions record one entry using:

```asm
; AL    = type
; DX:BX = amount (DX high word, BX low word)
CALL PUSH_TRANSACTION
```

Feature 2 is already updated to use this contract:

- Loan approval records type `31` with the approved amount.
- Each loan repayment records type `32` with the amount actually paid.
- A fully paid loan additionally records type `33` once.
- Overpayment records only the actual remaining loan amount; the retained excess is never recorded as a payment.

Feature 6 supplies `PUSH_TRANSACTION` and makes its recorded data available to `DISPLAY_HISTORY` and `CALCULATE_STATISTICS`. Deposit, withdrawal, and transfer code should use type `1`, `2`, or `3` and call the same procedure exactly once after completing their balance update.

When the teammates' source arrives, only map these existing names at the top of the modules: `loggedInAccountIndex`, `balances`, and `accountIDs`, then add `CALL LOAN_MENU` and `CALL TRANSACTION_MENU` to the shared main menu.
