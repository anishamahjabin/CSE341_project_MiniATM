; ============================================================================
; Loan Management System -- Feature 2
; 8086 / Emu8086 source to be MERGED into the existing Mini ATM program.
;
; This file deliberately contains no MAIN and does not define account data or
; the transaction stack.  Change the three adapter EQU names below once the
; shared program is available, then paste this file's DATA and CODE sections
; into its existing .DATA and .CODE sections respectively.
;
; Shared-system contract used by this module
;   loggedInAccountIndex  DW  current zero-based account number
;   balances              DD  one unsigned 32-bit balance per account
;   PUSH_TRANSACTION      procedure: AL = type, DX:BX = transaction amount
;
; If the shared balance array is DW rather than DD, only GET_BALANCE and
; DEDUCT_BALANCE need adapting.  All loan values are DD because Home Loan
; permits 500,000, which cannot fit in a 16-bit word.
; ============================================================================

; ----- merge adapters: rename these three symbols to the shared project -----
LOAN_ACCOUNT_INDEX EQU currentUser
LOAN_BALANCES      EQU balances
LOAN_PUSH_TX        EQU PUSH_TRANSACTION

; The value must match the number of accounts allocated by the shared system.
MAX_ACCOUNTS EQU 10

; Loan statuses and transaction activity IDs.  Adapt activity IDs to match
; the existing transaction stack's IDs, if its PUSH_TRANSACTION uses others.
LOAN_NONE   EQU 0
LOAN_ACTIVE EQU 1
LOAN_PAID   EQU 2

LOAN_TX_APPROVED  EQU 31
LOAN_TX_REPAYMENT EQU 32
LOAN_TX_PAID      EQU 33

; Meaningful output macro used by repeated loan prompts/messages.
; Rename it if the team program already has a macro with this name.
LOAN_PRINT MACRO message
    LEA DX, message
    MOV AH, 09H
    INT 21H
ENDM

; ===================== ADD THESE DECLARATIONS TO .DATA =====================

; Configuration arrays, indexed by loan type 0..3.
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

; Per-account loan arrays.  DD is required for loan amounts up to 500,000.
loanType       DW MAX_ACCOUNTS DUP(0)
loanAmount     DD MAX_ACCOUNTS DUP(0)
loanInterest   DW MAX_ACCOUNTS DUP(0)
loanTotal      DD MAX_ACCOUNTS DUP(0)
loanRemaining  DD MAX_ACCOUNTS DUP(0)
loanStatus     DB MAX_ACCOUNTS DUP(LOAN_NONE)

; Temporary request data used between APPLY_LOAN, CHECK_ELIGIBILITY and
; CALCULATE_INTEREST.  They are module-private, not account data.
selectedLoanType DW 0             ; zero-based type: 0..3
requestedAmount  DD 0
calculatedInterest DD 0
repayExcess         DD 0             ; nonzero only for an overpayment
repayActual         DD 0             ; amount actually applied to the loan

; =================== ADD THESE PROCEDURES TO .CODE =========================

; ---------------------------------------------------------------------------
; LOAN_MENU - loops until the account holder chooses Back.
; ---------------------------------------------------------------------------
LOAN_MENU PROC NEAR
loan_menu_again:
    LOAN_PRINT loanMenuText
    CALL READ_DWORD                 ; DX:AX = choice
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

; ---------------------------------------------------------------------------
; APPLY_LOAN - gets a type and amount, validates it, stores the new loan.
; ---------------------------------------------------------------------------
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
    CALL CHECK_ELIGIBILITY           ; CF set means rejected and message shown
    JC apply_done

    ; Rate is loaded from loanRate[selectedLoanType].
    MOV BX, selectedLoanType
    SHL BX, 1
    MOV BX, loanRate[BX]
    MOV AX, WORD PTR requestedAmount
    MOV DX, WORD PTR requestedAmount+2
    CALL CALCULATE_INTEREST          ; DX:AX interest, calculatedInterest set

    ; Store type, amount, interest, total, remaining and active state.
    MOV BX, LOAN_ACCOUNT_INDEX
    SHL BX, 1
    MOV SI, selectedLoanType
    INC SI                           ; store display type 1..4
    MOV loanType[BX], SI
    MOV AX, WORD PTR calculatedInterest
    MOV loanInterest[BX], AX

    SHL BX, 1                        ; account * 4 for DD arrays
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

; ---------------------------------------------------------------------------
; CHECK_ELIGIBILITY - validates amount, balance, active-loan status, maximum.
; Input: selectedLoanType 0..3, requestedAmount DD.
; Output: CF clear = eligible, CF set = rejected.  Displays rejection reason.
; ---------------------------------------------------------------------------
CHECK_ELIGIBILITY PROC NEAR
    ; requested amount must be > 0.
    MOV AX, WORD PTR requestedAmount
    OR AX, WORD PTR requestedAmount+2
    JNZ eligibility_balance
    LOAN_PRINT invalidAmountText
    STC
    RET
eligibility_balance:
    CALL GET_BALANCE                 ; DX:AX current balance
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
    ; Compare requested DD with loanMax[selected type].
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

; ---------------------------------------------------------------------------
; CALCULATE_INTEREST
; Input: DX:AX = amount, BX = integer rate.
; Output: DX:AX = interest. calculatedInterest is also updated.
; Formula: (amount * rate) / 100, using 32-bit integer arithmetic on 8086.
; ---------------------------------------------------------------------------
CALCULATE_INTEREST PROC NEAR
    PUSH BX
    PUSH SI
    PUSH DI
    MOV SI, AX                       ; preserve amount low word
    MOV AX, DX
    MUL BX                           ; highWord(amount) * rate
    MOV DI, AX                       ; becomes high contribution
    MOV AX, SI
    MUL BX                           ; lowWord(amount) * rate -> DX:AX
    ADD DX, DI                       ; complete 32-bit product in DX:AX
    MOV BX, 100
    CALL DIV_DWORD_BY_WORD
    MOV WORD PTR calculatedInterest, AX
    MOV WORD PTR calculatedInterest+2, DX
    POP DI
    POP SI
    POP BX
    RET
CALCULATE_INTEREST ENDP

; ---------------------------------------------------------------------------
; VIEW_LOAN - shows all required loan fields for current account.
; ---------------------------------------------------------------------------
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

; ---------------------------------------------------------------------------
; REPAY_LOAN - settles normal and overpayment cases safely.
; The requested amount is never deducted wholesale: only actual amount owed
; is passed to DEDUCT_BALANCE.
; ---------------------------------------------------------------------------
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
    MOV SI, AX                       ; SI:DI = requested repayment
    MOV DI, DX
    OR AX, DX
    JNZ repay_check_balance
    LOAN_PRINT invalidAmountText
    RET
repay_check_balance:
    CALL GET_BALANCE                 ; DX:AX = balance
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
    ; Compare requested DI:SI against remaining loan DD.
    CMP DI, WORD PTR loanRemaining[BX+2]
    JB repay_normal
    JA repay_clear
    CMP SI, WORD PTR loanRemaining[BX]
    JB repay_normal
    JE repay_exact
repay_clear:
    ; Overpayment: deduct only remaining amount, then show retained excess.
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
    ; Deduct the requested amount and reduce remaining by exactly that amount.
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

; ---------------------------------------------------------------------------
; GET_BALANCE / DEDUCT_BALANCE are the only balance-array adapters.
; Default contract: LOAN_BALANCES is a DD array, indexed by account number.
; ---------------------------------------------------------------------------
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

; Input DX:AX = actual amount that must be paid (never the excess request).
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

; ---------------------------------------------------------------------------
; READ_DWORD - reads an unsigned decimal integer from keyboard.
; Output DX:AX.  Non-digits are ignored.  Enter returns the number typed.
; ---------------------------------------------------------------------------
READ_DWORD PROC NEAR
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH BP
    XOR SI, SI                        ; low word
    XOR DI, DI                        ; high word
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
    MOV BP, AX                        ; digit
    MOV AX, SI
    MOV DX, DI                        ; original number in DX:AX
    MOV BX, 9
read_dword_times_ten:
    ADD SI, AX
    ADC DI, DX
    DEC BX
    JNZ read_dword_times_ten          ; original + 9 originals = *10
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

; PRINT_DWORD - writes unsigned decimal DX:AX using DOS output service.
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
    DIV BX                            ; high quotient, high remainder
    MOV DI, AX
    MOV AX, SI
    DIV BX                            ; completes 32-bit / 10; DX = digit
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

; DIV_DWORD_BY_WORD - unsigned (DX:AX) / BX -> quotient DX:AX.
; It is valid here because product/rate values keep the high partial quotient
; below the divisor (100).
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
