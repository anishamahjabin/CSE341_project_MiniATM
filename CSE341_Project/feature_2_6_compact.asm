; Feature 2 + Feature 6 (compact merge version, no MAIN program)
; Map the three adapter names below to the shared ATM variables/procedure.

LOAN_ACCOUNT_INDEX EQU currentUser
LOAN_BALANCES      EQU balances
LOAN_PUSH_TX        EQU PUSH_TRANSACTION

MAX_ACCOUNTS EQU 10

LOAN_NONE   EQU 0
LOAN_ACTIVE EQU 1
LOAN_PAID   EQU 2

LOAN_TX_APPROVED  EQU 31
LOAN_TX_REPAYMENT EQU 32
LOAN_TX_PAID      EQU 33

LOAN_PRINT MACRO message
    LEA DX, message
    MOV AH, 09H
    INT 21H
ENDM

TX_ACCOUNT_INDEX EQU currentUser
TX_ACCOUNT_IDS   EQU accountIDs

MAX_TRANSACTIONS EQU 100

TX_DEPOSIT    EQU 1
TX_WITHDRAWAL EQU 2
TX_TRANSFER   EQU 3

loanMax       DD 50000, 30000, 100000, 500000
loanRate      DW 8, 5, 6, 7
loanNameTable DW OFFSET personalLoanName, OFFSET emergencyLoanName
              DW OFFSET educationLoanName, OFFSET homeLoanName

personalLoanName  DB 'Personal Loan$'
emergencyLoanName DB 'Emergency Loan$'
educationLoanName DB 'Education Loan$'
homeLoanName      DB 'Home Loan$'
activeText        DB 'ACTIVE$'
paidText          DB 'PAID$'
noneText          DB 'NONE$'

loanMenuText DB 13,10,'========== LOAN MANAGEMENT ==========',13,10
             DB '1. Apply for Loan',13,10
             DB '2. View Current Loan',13,10
             DB '3. Repay Loan',13,10
             DB '4. Back',13,10,'Choose option: $'
loanTypeText DB 13,10,'Select loan type:',13,10
             DB '1. Personal (max 50000, 8%)',13,10
             DB '2. Emergency (max 30000, 5%)',13,10
             DB '3. Education (max 100000, 6%)',13,10
             DB '4. Home (max 500000, 7%)',13,10,'Choose type: $'
amountPrompt       DB 13,10,'Enter loan amount: $'
repayPrompt        DB 13,10,'Enter repayment amount: $'
invalidChoiceText  DB 13,10,'Invalid selection.$'
invalidAmountText  DB 13,10,'Amount must be greater than zero.$'
lowBalanceText     DB 13,10,'Loan denied: minimum account balance is 10000.$'
activeLoanText     DB 13,10,'Loan denied: an active loan already exists.$'
maxExceededText    DB 13,10,'Loan denied: amount exceeds this loan type maximum.$'
noLoanText         DB 13,10,'No loan exists for this account.$'
noActiveLoanText   DB 13,10,'No active loan to repay.$'
fundsText          DB 13,10,'Insufficient account balance for this repayment.$'
approvedText       DB 13,10,'Loan approved.$'
repaymentText      DB 13,10,'Loan repayment recorded.$'
excessText         DB 13,10,'Excess amount retained in account: $'
loanPaidText       DB 13,10,'Loan is now fully paid.$'
loanTypeLabel      DB 13,10,'Loan type: $'
originalLabel      DB 13,10,'Original amount: $'
rateLabel          DB 13,10,'Interest rate: $'
interestLabel      DB 13,10,'Interest amount: $'
totalLabel         DB 13,10,'Total repayment: $'
remainingLabel     DB 13,10,'Remaining loan: $'
statusLabel        DB 13,10,'Status: $'
percentText        DB '%$'
newlineText        DB 13,10,'$'

loanType       DW MAX_ACCOUNTS DUP(0)
loanAmount     DD MAX_ACCOUNTS DUP(0)
loanInterest   DW MAX_ACCOUNTS DUP(0)
loanTotal      DD MAX_ACCOUNTS DUP(0)
loanRemaining  DD MAX_ACCOUNTS DUP(0)
loanStatus     DB MAX_ACCOUNTS DUP(LOAN_NONE)

selectedLoanType DW 0
requestedAmount  DD 0
calculatedInterest DD 0
repayExcess         DD 0
repayActual         DD 0

transactionType    DB MAX_TRANSACTIONS DUP(0)
transactionAmount  DD MAX_TRANSACTIONS DUP(0)
transactionAccount DW MAX_TRANSACTIONS DUP(0)
transactionTop     DW 0

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

; Loan menu.
LOAN_MENU PROC NEAR
loan_menu_again:
    LOAN_PRINT loanMenuText
    CALL READ_DWORD
    OR DX, DX
    JNZ loan_menu_bad
    CMP AX, 1
    JE loan_menu_apply
    CMP AX, 2
    JE loan_menu_view
    CMP AX, 3
    JE loan_menu_repay
    CMP AX, 4
    JE loan_menu_done
loan_menu_bad:
    LOAN_PRINT invalidChoiceText
    JMP loan_menu_again
loan_menu_apply:
    CALL APPLY_LOAN
    JMP loan_menu_again
loan_menu_view:
    CALL VIEW_LOAN
    JMP loan_menu_again
loan_menu_repay:
    CALL REPAY_LOAN
    JMP loan_menu_again
loan_menu_done:
    RET
LOAN_MENU ENDP

; Apply and store a loan.
APPLY_LOAN PROC NEAR
    LOAN_PRINT loanTypeText
    CALL READ_DWORD
    OR DX, DX
    JNZ apply_bad_type
    CMP AX, 1
    JB apply_bad_type
    CMP AX, 4
    JA apply_bad_type
    DEC AX
    MOV selectedLoanType, AX

    LOAN_PRINT amountPrompt
    CALL READ_DWORD
    MOV WORD PTR requestedAmount, AX
    MOV WORD PTR requestedAmount+2, DX
    CALL CHECK_ELIGIBILITY
    JC apply_done

    MOV BX, selectedLoanType
    SHL BX, 1
    MOV BX, loanRate[BX]
    MOV AX, WORD PTR requestedAmount
    MOV DX, WORD PTR requestedAmount+2
    CALL CALCULATE_INTEREST

    MOV BX, LOAN_ACCOUNT_INDEX
    SHL BX, 1
    MOV SI, selectedLoanType
    INC SI
    MOV loanType[BX], SI
    MOV AX, WORD PTR calculatedInterest
    MOV loanInterest[BX], AX

    SHL BX, 1
    MOV AX, WORD PTR requestedAmount
    MOV DX, WORD PTR requestedAmount+2
    MOV WORD PTR loanAmount[BX], AX
    MOV WORD PTR loanAmount[BX+2], DX
    ADD AX, WORD PTR calculatedInterest
    ADC DX, WORD PTR calculatedInterest+2
    MOV WORD PTR loanTotal[BX], AX
    MOV WORD PTR loanTotal[BX+2], DX
    MOV WORD PTR loanRemaining[BX], AX
    MOV WORD PTR loanRemaining[BX+2], DX

    MOV SI, LOAN_ACCOUNT_INDEX
    MOV loanStatus[SI], LOAN_ACTIVE
    MOV BX, WORD PTR requestedAmount
    MOV DX, WORD PTR requestedAmount+2
    MOV AL, LOAN_TX_APPROVED
    CALL LOAN_PUSH_TX
    LOAN_PRINT approvedText
    CALL VIEW_LOAN
    JMP apply_done
apply_bad_type:
    LOAN_PRINT invalidChoiceText
apply_done:
    RET
APPLY_LOAN ENDP

; Eligibility validation.
CHECK_ELIGIBILITY PROC NEAR

    MOV AX, WORD PTR requestedAmount
    OR AX, WORD PTR requestedAmount+2
    JNZ eligibility_balance
    LOAN_PRINT invalidAmountText
    STC
    RET
eligibility_balance:
    CALL GET_BALANCE
    OR DX, DX
    JNZ eligibility_active
    CMP AX, 10000
    JAE eligibility_active
    LOAN_PRINT lowBalanceText
    STC
    RET
eligibility_active:
    MOV BX, LOAN_ACCOUNT_INDEX
    CMP loanStatus[BX], LOAN_ACTIVE
    JNE eligibility_max
    LOAN_PRINT activeLoanText
    STC
    RET
eligibility_max:

    MOV BX, selectedLoanType
    SHL BX, 1
    SHL BX, 1
    MOV AX, WORD PTR requestedAmount+2
    CMP AX, WORD PTR loanMax[BX+2]
    JA eligibility_too_large
    JB eligibility_ok
    MOV AX, WORD PTR requestedAmount
    CMP AX, WORD PTR loanMax[BX]
    JA eligibility_too_large
eligibility_ok:
    CLC
    RET
eligibility_too_large:
    LOAN_PRINT maxExceededText
    STC
    RET
CHECK_ELIGIBILITY ENDP

; Integer interest calculation.
CALCULATE_INTEREST PROC NEAR
    PUSH BX
    PUSH SI
    PUSH DI
    MOV SI, AX
    MOV AX, DX
    MUL BX
    MOV DI, AX
    MOV AX, SI
    MUL BX
    ADD DX, DI
    MOV BX, 100
    CALL DIV_DWORD_BY_WORD
    MOV WORD PTR calculatedInterest, AX
    MOV WORD PTR calculatedInterest+2, DX
    POP DI
    POP SI
    POP BX
    RET
CALCULATE_INTEREST ENDP

; Current loan display.
VIEW_LOAN PROC NEAR
    MOV BX, LOAN_ACCOUNT_INDEX
    CMP loanStatus[BX], LOAN_NONE
    JNE view_has_loan
    LOAN_PRINT noLoanText
    RET
view_has_loan:
    LOAN_PRINT loanTypeLabel
    MOV BX, LOAN_ACCOUNT_INDEX
    SHL BX, 1
    MOV AX, loanType[BX]
    DEC AX
    SHL AX, 1
    MOV BX, AX
    MOV DX, loanNameTable[BX]
    MOV AH, 09H
    INT 21H

    MOV BX, LOAN_ACCOUNT_INDEX
    SHL BX, 1
    SHL BX, 1
    LOAN_PRINT originalLabel
    MOV AX, WORD PTR loanAmount[BX]
    MOV DX, WORD PTR loanAmount[BX+2]
    CALL PRINT_DWORD

    LOAN_PRINT rateLabel
    MOV SI, LOAN_ACCOUNT_INDEX
    SHL SI, 1
    MOV AX, loanType[SI]
    DEC AX
    SHL AX, 1
    MOV SI, AX
    MOV AX, loanRate[SI]
    XOR DX, DX
    CALL PRINT_DWORD
    LOAN_PRINT percentText

    LOAN_PRINT interestLabel
    MOV AX, WORD PTR loanInterest[BX]
    XOR DX, DX
    CALL PRINT_DWORD
    LOAN_PRINT totalLabel
    MOV AX, WORD PTR loanTotal[BX]
    MOV DX, WORD PTR loanTotal[BX+2]
    CALL PRINT_DWORD
    LOAN_PRINT remainingLabel
    MOV AX, WORD PTR loanRemaining[BX]
    MOV DX, WORD PTR loanRemaining[BX+2]
    CALL PRINT_DWORD
    LOAN_PRINT statusLabel
    MOV SI, LOAN_ACCOUNT_INDEX
    CMP loanStatus[SI], LOAN_ACTIVE
    JE view_active
    CMP loanStatus[SI], LOAN_PAID
    JE view_paid
    LEA DX, noneText
    JMP view_status_print
view_active:
    LEA DX, activeText
    JMP view_status_print
view_paid:
    LEA DX, paidText
view_status_print:
    MOV AH, 09H
    INT 21H
    RET
VIEW_LOAN ENDP

; Repayment and overpayment handling.
REPAY_LOAN PROC NEAR
    MOV BX, LOAN_ACCOUNT_INDEX
    CMP loanStatus[BX], LOAN_ACTIVE
    JE repay_show_remaining
    LOAN_PRINT noActiveLoanText
    RET
repay_show_remaining:
    LOAN_PRINT remainingLabel
    MOV BX, LOAN_ACCOUNT_INDEX
    SHL BX, 1
    SHL BX, 1
    MOV AX, WORD PTR loanRemaining[BX]
    MOV DX, WORD PTR loanRemaining[BX+2]
    CALL PRINT_DWORD
    LOAN_PRINT repayPrompt
    CALL READ_DWORD
    MOV SI, AX
    MOV DI, DX
    OR AX, DX
    JNZ repay_check_balance
    LOAN_PRINT invalidAmountText
    RET
repay_check_balance:
    CALL GET_BALANCE
    CMP DX, DI
    JB repay_insufficient
    JA repay_compare_remaining
    CMP AX, SI
    JB repay_insufficient
repay_compare_remaining:
    MOV WORD PTR repayExcess, 0
    MOV WORD PTR repayExcess+2, 0
    MOV BX, LOAN_ACCOUNT_INDEX
    SHL BX, 1
    SHL BX, 1

    CMP DI, WORD PTR loanRemaining[BX+2]
    JB repay_normal
    JA repay_clear
    CMP SI, WORD PTR loanRemaining[BX]
    JB repay_normal
    JE repay_exact
repay_clear:

    MOV AX, SI
    MOV DX, DI
    SUB AX, WORD PTR loanRemaining[BX]
    SBB DX, WORD PTR loanRemaining[BX+2]
    MOV WORD PTR repayExcess, AX
    MOV WORD PTR repayExcess+2, DX
    MOV AX, WORD PTR loanRemaining[BX]
    MOV DX, WORD PTR loanRemaining[BX+2]
    MOV WORD PTR repayActual, AX
    MOV WORD PTR repayActual+2, DX
    CALL DEDUCT_BALANCE
    MOV WORD PTR loanRemaining[BX], 0
    MOV WORD PTR loanRemaining[BX+2], 0
    JMP repay_mark_paid
repay_exact:
    MOV AX, SI
    MOV DX, DI
    MOV WORD PTR repayActual, AX
    MOV WORD PTR repayActual+2, DX
    CALL DEDUCT_BALANCE
    MOV WORD PTR loanRemaining[BX], 0
    MOV WORD PTR loanRemaining[BX+2], 0
    JMP repay_mark_paid
repay_normal:

    MOV AX, SI
    MOV DX, DI
    CALL DEDUCT_BALANCE
    SUB WORD PTR loanRemaining[BX], SI
    SBB WORD PTR loanRemaining[BX+2], DI
    MOV AX, WORD PTR loanRemaining[BX]
    OR AX, WORD PTR loanRemaining[BX+2]
    JZ repay_mark_paid
    MOV BX, SI
    MOV DX, DI
    MOV AL, LOAN_TX_REPAYMENT
    CALL LOAN_PUSH_TX
    LOAN_PRINT repaymentText
    RET
repay_mark_paid:
    MOV SI, LOAN_ACCOUNT_INDEX
    MOV loanStatus[SI], LOAN_PAID
    MOV BX, WORD PTR repayActual
    MOV DX, WORD PTR repayActual+2
    MOV AL, LOAN_TX_REPAYMENT
    CALL LOAN_PUSH_TX
    XOR BX, BX
    XOR DX, DX
    MOV AL, LOAN_TX_PAID
    CALL LOAN_PUSH_TX
    LOAN_PRINT repaymentText
    LOAN_PRINT loanPaidText
    MOV AX, WORD PTR repayExcess
    OR AX, WORD PTR repayExcess+2
    JZ repay_paid_done
    LOAN_PRINT excessText
    MOV AX, WORD PTR repayExcess
    MOV DX, WORD PTR repayExcess+2
    CALL PRINT_DWORD
repay_paid_done:
    RET
repay_insufficient:
    LOAN_PRINT fundsText
    RET
REPAY_LOAN ENDP

; Shared balance adapter.
GET_BALANCE PROC NEAR
    PUSH BX
    MOV BX, LOAN_ACCOUNT_INDEX
    SHL BX, 1
    SHL BX, 1
    MOV AX, WORD PTR LOAN_BALANCES[BX]
    MOV DX, WORD PTR LOAN_BALANCES[BX+2]
    POP BX
    RET
GET_BALANCE ENDP

; Shared balance update adapter.
DEDUCT_BALANCE PROC NEAR
    PUSH BX
    PUSH SI
    PUSH DI
    MOV SI, AX
    MOV DI, DX
    MOV BX, LOAN_ACCOUNT_INDEX
    SHL BX, 1
    SHL BX, 1
    SUB WORD PTR LOAN_BALANCES[BX], SI
    SBB WORD PTR LOAN_BALANCES[BX+2], DI
    POP DI
    POP SI
    POP BX
    RET
DEDUCT_BALANCE ENDP

; Unsigned decimal input.
READ_DWORD PROC NEAR
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH BP
    XOR SI, SI
    XOR DI, DI
read_dword_key:
    MOV AH, 01H
    INT 21H
    CMP AL, 13
    JE read_dword_done
    CMP AL, '0'
    JB read_dword_key
    CMP AL, '9'
    JA read_dword_key
    SUB AL, '0'
    XOR AH, AH
    MOV BP, AX
    MOV AX, SI
    MOV DX, DI
    MOV BX, 9
read_dword_times_ten:
    ADD SI, AX
    ADC DI, DX
    DEC BX
    JNZ read_dword_times_ten
    ADD SI, BP
    ADC DI, 0
    JMP read_dword_key
read_dword_done:
    MOV AX, SI
    MOV DX, DI
    POP BP
    POP DI
    POP SI
    POP CX
    POP BX
    RET
READ_DWORD ENDP

; Unsigned decimal output.
PRINT_DWORD PROC NEAR
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    MOV BX, 10
    XOR CX, CX
    OR DX, DX
    JNZ print_dword_divide
    OR AX, AX
    JNZ print_dword_divide
    MOV DL, '0'
    MOV AH, 02H
    INT 21H
    JMP print_dword_done
print_dword_divide:
    MOV SI, AX
    MOV AX, DX
    XOR DX, DX
    DIV BX
    MOV DI, AX
    MOV AX, SI
    DIV BX
    PUSH DX
    INC CX
    MOV DX, DI
    OR DX, DX
    JNZ print_dword_divide
    OR AX, AX
    JNZ print_dword_divide
print_dword_emit:
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    LOOP print_dword_emit
print_dword_done:
    POP DI
    POP SI
    POP CX
    POP BX
    RET
PRINT_DWORD ENDP

; 32-bit integer division.
DIV_DWORD_BY_WORD PROC NEAR
    PUSH SI
    PUSH DI
    MOV SI, AX
    MOV AX, DX
    XOR DX, DX
    DIV BX
    MOV DI, AX
    MOV AX, SI
    DIV BX
    MOV DX, DI
    POP DI
    POP SI
    RET
DIV_DWORD_BY_WORD ENDP

; Shared LIFO transaction stack.
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

; Transaction and summary menu.
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

; Newest-first transaction history.
DISPLAY_HISTORY PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH BP
    LOAN_PRINT historyHeader
    MOV CX, transactionTop
    JCXZ display_history_empty
    XOR BP, BP
display_history_loop:
    DEC CX
    MOV SI, CX
    MOV BX, SI
    SHL BX, 1
    MOV AX, transactionAccount[BX]
    CMP AX, TX_ACCOUNT_INDEX
    JNE display_history_next
    CALL DISPLAY_TRANSACTION
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

; One transaction entry.
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
    CMP AL, 31
    JE display_loan_approved
    CMP AL, 32
    JE display_loan_repayment
    CMP AL, 33
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

; Current-account summary.
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

    CALL VIEW_LOAN
    RET
ACCOUNT_SUMMARY ENDP

; Per-account transaction totals.
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
