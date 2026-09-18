; ============================================================================
; Transaction History & Account Summary -- Feature 6
; 8086 / Emu8086 source to be merged after loan_management.asm.
;
; This module OWNS the project's single transaction stack.  It does not define
; account IDs, balances, login state, or loan arrays.  Loan data and the shared
; PRINT_DWORD, READ_DWORD, GET_BALANCE and LOAN_PRINT helpers are reused from
; Feature 2 rather than duplicated.
;
; PUSH_TRANSACTION interface for every feature:
;   AL    = transaction type (TX_* below; Loan types remain 31, 32, 33)
;   DX:BX = unsigned transaction amount (0 is permitted for legacy callers)
;   loggedInAccountIndex supplies the account automatically.
; Output CF clear = recorded, CF set = stack full (no write occurs).
; ============================================================================

; ----- merge adapters: rename to exact symbols in the shared ATM program ----
TX_ACCOUNT_INDEX EQU currentUser            ; shared logged-in account offset
TX_ACCOUNT_IDS   EQU accountIDs             ; DW array, one ID per account

MAX_TRANSACTIONS EQU 100

; Deposit/withdrawal/transfer identifiers.  Feature 2 already declares
; LOAN_TX_APPROVED=31, LOAN_TX_REPAYMENT=32 and LOAN_TX_PAID=33.
TX_DEPOSIT    EQU 1
TX_WITHDRAWAL EQU 2
TX_TRANSFER   EQU 3

; ===================== ADD THESE DECLARATIONS TO .DATA =====================

; The one shared transaction stack, with transactionTop as its count/top.
; Valid entries are always 0 through transactionTop-1.
transactionType    DB MAX_TRANSACTIONS DUP(0)
transactionAmount  DD MAX_TRANSACTIONS DUP(0)
transactionAccount DW MAX_TRANSACTIONS DUP(0)
transactionTop     DW 0

; These are result/work variables, not duplicate account data.
summaryDeposits    DD 0
summaryWithdrawals DD 0
summaryTransfers   DD 0
summaryCount       DW 0

transactionMenuText DB 13,10,'====== TRANSACTION & SUMMARY ======',13,10
                    DB '1. Transaction History',13,10
                    DB '2. Account Summary',13,10
                    DB '3. Back',13,10,'Choose option: $'
historyHeader      DB 13,10,'--- Transaction History (newest first) ---$'
summaryHeader      DB 13,10,'--- Account Summary ---$'
noTransactionsText DB 13,10,'No transactions available.$'
invalidTxChoice    DB 13,10,'Invalid selection.$'
accountIdLabel     DB 13,10,'Account ID: $'
balanceLabel       DB 13,10,'Current balance: $'
depositsLabel      DB 13,10,'Total deposits: $'
withdrawalsLabel   DB 13,10,'Total withdrawals: $'
transfersLabel     DB 13,10,'Total transfers: $'
countLabel         DB 13,10,'Total number of transactions: $'
depositText        DB 13,10,'Deposit: $'
withdrawText       DB 13,10,'Withdrawal: $'
transferText       DB 13,10,'Transfer: $'
loanApprovedText   DB 13,10,'Loan Approved: $'
loanRepaymentText  DB 13,10,'Loan Repayment: $'
loanPaidHistoryText DB 13,10,'Loan Paid: $'
unknownTxText      DB 13,10,'Unknown transaction: $'

; =================== ADD THESE PROCEDURES TO .CODE =========================

; ---------------------------------------------------------------------------
; PUSH_TRANSACTION - records exactly one event at the next stack position.
; This is the transaction-stack procedure called by deposit, withdrawal,
; transfer and loan features.  It never writes or increments when stack full.
; ---------------------------------------------------------------------------
PUSH_TRANSACTION PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    MOV CX, transactionTop
    CMP CX, MAX_TRANSACTIONS
    JAE push_transaction_full

    MOV SI, CX
    MOV transactionType[SI], AL
    SHL SI, 1
    MOV AX, TX_ACCOUNT_INDEX
    MOV transactionAccount[SI], AX

    MOV DI, CX
    SHL DI, 1
    SHL DI, 1
    MOV WORD PTR transactionAmount[DI], BX
    MOV WORD PTR transactionAmount[DI+2], DX
    INC transactionTop
    CLC
    JMP push_transaction_done
push_transaction_full:
    STC
push_transaction_done:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PUSH_TRANSACTION ENDP

; ---------------------------------------------------------------------------
; TRANSACTION_MENU - loops until Back is selected.
; ---------------------------------------------------------------------------
TRANSACTION_MENU PROC NEAR
transaction_menu_again:
    LOAN_PRINT transactionMenuText
    CALL READ_DWORD
    OR DX, DX
    JNZ transaction_menu_bad
    CMP AX, 1
    JE transaction_menu_history
    CMP AX, 2
    JE transaction_menu_summary
    CMP AX, 3
    JE transaction_menu_done
transaction_menu_bad:
    LOAN_PRINT invalidTxChoice
    JMP transaction_menu_again
transaction_menu_history:
    CALL DISPLAY_HISTORY
    JMP transaction_menu_again
transaction_menu_summary:
    CALL ACCOUNT_SUMMARY
    JMP transaction_menu_again
transaction_menu_done:
    RET
TRANSACTION_MENU ENDP

; ---------------------------------------------------------------------------
; DISPLAY_HISTORY - scans only valid stack entries from newest to oldest and
; shows entries belonging to the logged-in account.  It never pops the stack.
; ---------------------------------------------------------------------------
DISPLAY_HISTORY PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH BP
    LOAN_PRINT historyHeader
    MOV CX, transactionTop
    JCXZ display_history_empty
    XOR BP, BP                        ; number displayed for current account
display_history_loop:
    DEC CX                            ; top-1, top-2, ... 0 (LIFO order)
    MOV SI, CX
    MOV BX, SI
    SHL BX, 1
    MOV AX, transactionAccount[BX]
    CMP AX, TX_ACCOUNT_INDEX
    JNE display_history_next
    CALL DISPLAY_TRANSACTION          ; SI = valid stack entry index
    INC BP
display_history_next:
    OR CX, CX
    JNZ display_history_loop
    OR BP, BP
    JNZ display_history_done
display_history_empty:
    LOAN_PRINT noTransactionsText
display_history_done:
    POP BP
    POP SI
    POP CX
    POP BX
    POP AX
    RET
DISPLAY_HISTORY ENDP

; ---------------------------------------------------------------------------
; DISPLAY_TRANSACTION - prints one valid transaction stack entry.
; Input: SI = entry index, guaranteed 0 <= SI < transactionTop.
; ---------------------------------------------------------------------------
DISPLAY_TRANSACTION PROC NEAR
    PUSH AX
    PUSH BX
    PUSH DX
    MOV AL, transactionType[SI]
    CMP AL, TX_DEPOSIT
    JE display_deposit
    CMP AL, TX_WITHDRAWAL
    JE display_withdrawal
    CMP AL, TX_TRANSFER
    JE display_transfer
    CMP AL, 31                         ; LOAN_TX_APPROVED from Feature 2
    JE display_loan_approved
    CMP AL, 32                         ; LOAN_TX_REPAYMENT from Feature 2
    JE display_loan_repayment
    CMP AL, 33                         ; LOAN_TX_PAID from Feature 2
    JE display_loan_paid
    LOAN_PRINT unknownTxText
    JMP display_amount
display_deposit:
    LOAN_PRINT depositText
    JMP display_amount
display_withdrawal:
    LOAN_PRINT withdrawText
    JMP display_amount
display_transfer:
    LOAN_PRINT transferText
    JMP display_amount
display_loan_approved:
    LOAN_PRINT loanApprovedText
    JMP display_amount
display_loan_repayment:
    LOAN_PRINT loanRepaymentText
    JMP display_amount
display_loan_paid:
    LOAN_PRINT loanPaidHistoryText
display_amount:
    MOV BX, SI
    SHL BX, 1
    SHL BX, 1
    MOV AX, WORD PTR transactionAmount[BX]
    MOV DX, WORD PTR transactionAmount[BX+2]
    CALL PRINT_DWORD
    POP DX
    POP BX
    POP AX
    RET
DISPLAY_TRANSACTION ENDP

; ---------------------------------------------------------------------------
; ACCOUNT_SUMMARY - displays shared account data, computed per-account totals,
; then calls VIEW_LOAN so the current loan fields are shown from loan arrays.
; ---------------------------------------------------------------------------
ACCOUNT_SUMMARY PROC NEAR
    LOAN_PRINT summaryHeader
    LOAN_PRINT accountIdLabel
    MOV BX, TX_ACCOUNT_INDEX
    SHL BX, 1
    MOV AX, TX_ACCOUNT_IDS[BX]
    XOR DX, DX
    CALL PRINT_DWORD

    LOAN_PRINT balanceLabel
    CALL GET_BALANCE
    CALL PRINT_DWORD

    CALL CALCULATE_STATISTICS
    LOAN_PRINT depositsLabel
    MOV AX, WORD PTR summaryDeposits
    MOV DX, WORD PTR summaryDeposits+2
    CALL PRINT_DWORD
    LOAN_PRINT withdrawalsLabel
    MOV AX, WORD PTR summaryWithdrawals
    MOV DX, WORD PTR summaryWithdrawals+2
    CALL PRINT_DWORD
    LOAN_PRINT transfersLabel
    MOV AX, WORD PTR summaryTransfers
    MOV DX, WORD PTR summaryTransfers+2
    CALL PRINT_DWORD
    LOAN_PRINT countLabel
    MOV AX, summaryCount
    XOR DX, DX
    CALL PRINT_DWORD

    ; Feature 2's procedure prints loan type, original, rate, interest,
    ; total repayment, remaining balance and status from the existing arrays.
    CALL VIEW_LOAN
    RET
ACCOUNT_SUMMARY ENDP

; ---------------------------------------------------------------------------
; CALCULATE_STATISTICS - actual indexed-array scan for the logged-in account.
; It counts every transaction for that account, but totals only Deposit,
; Withdrawal and Transfer amounts as required.
; ---------------------------------------------------------------------------
CALCULATE_STATISTICS PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    MOV WORD PTR summaryDeposits, 0
    MOV WORD PTR summaryDeposits+2, 0
    MOV WORD PTR summaryWithdrawals, 0
    MOV WORD PTR summaryWithdrawals+2, 0
    MOV WORD PTR summaryTransfers, 0
    MOV WORD PTR summaryTransfers+2, 0
    MOV summaryCount, 0
    MOV CX, transactionTop
    JCXZ statistics_done
    XOR SI, SI
statistics_loop:
    MOV BX, SI
    SHL BX, 1
    MOV AX, transactionAccount[BX]
    CMP AX, TX_ACCOUNT_INDEX
    JNE statistics_next
    INC summaryCount
    MOV AL, transactionType[SI]
    CMP AL, TX_DEPOSIT
    JE statistics_deposit
    CMP AL, TX_WITHDRAWAL
    JE statistics_withdrawal
    CMP AL, TX_TRANSFER
    JE statistics_transfer
    JMP statistics_next
statistics_deposit:
    MOV BX, SI
    SHL BX, 1
    SHL BX, 1
    MOV AX, WORD PTR transactionAmount[BX]
    MOV DX, WORD PTR transactionAmount[BX+2]
    ADD WORD PTR summaryDeposits, AX
    ADC WORD PTR summaryDeposits+2, DX
    JMP statistics_next
statistics_withdrawal:
    MOV BX, SI
    SHL BX, 1
    SHL BX, 1
    MOV AX, WORD PTR transactionAmount[BX]
    MOV DX, WORD PTR transactionAmount[BX+2]
    ADD WORD PTR summaryWithdrawals, AX
    ADC WORD PTR summaryWithdrawals+2, DX
    JMP statistics_next
statistics_transfer:
    MOV BX, SI
    SHL BX, 1
    SHL BX, 1
    MOV AX, WORD PTR transactionAmount[BX]
    MOV DX, WORD PTR transactionAmount[BX+2]
    ADD WORD PTR summaryTransfers, AX
    ADC WORD PTR summaryTransfers+2, DX
statistics_next:
    INC SI
    LOOP statistics_loop
statistics_done:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CALCULATE_STATISTICS ENDP
