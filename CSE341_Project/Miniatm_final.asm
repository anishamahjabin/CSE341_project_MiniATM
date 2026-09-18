.MODEL SMALL

.STACK 100H


;====================================================
;                    MACROS
;====================================================

NEWLINE MACRO

    MOV AH,2
    MOV DL,13
    INT 21H

    MOV AH,2
    MOV DL,10
    INT 21H

ENDM


PRINT_STRING MACRO MSG

    LEA DX,MSG
    MOV AH,9
    INT 21H

ENDM


;====================================================
;                    DATA SEGMENT
;====================================================

.DATA


;====================================================
;                    MAIN MENU
;====================================================

welcomeMsg       DB "WELCOME TO MINI ATM & BANKING SYSTEM$"

startMsg         DB "1. Register New Account",13,10
                 DB "2. Login",13,10
                 DB "3. Exit",13,10
                 DB "Enter Choice: $"


;====================================================
;                    ACCOUNT MENU
;====================================================

accountMenu      DB "1. View Account Information",13,10
                 DB "2. Withdraw Money",13,10
                 DB "3. Deposit Money",13,10
                 DB "4. Money Transfer",13,10
                 DB "5. Change PIN",13,10
                 DB "6. Transaction History & Summary",13,10
                 DB "7. Loan Management",13,10
                 DB "8. Logout",13,10
                 DB "Enter Choice: $"


;====================================================
;                    ACCOUNT ARRAYS
;====================================================

; Maximum accounts = 100

accountIDs       DW 1001,1002,1003,97 DUP(?)

pins             DW 1234,1234,1234,97 DUP(?)

balances         DW 5000,8000,10000,97 DUP(0)


;====================================================
;                    NAME ARRAY
;====================================================

; EVERY NAME SLOT = EXACTLY 11 BYTES
;
; User 0 -> bytes 0-10
; User 1 -> bytes 11-21
; User 2 -> bytes 22-32

names            DB "Labiba$$$$$"
                 DB "Mashiyat$$$"
                 DB "Anisha$$$$$"

                 DB 1067 DUP('$')


;====================================================
;                  SECURITY ANSWERS
;====================================================

securityAnswers  DW 1111,2222,3333,97 DUP(?)


;====================================================
;                  USER CONTROL
;====================================================

userCount        DW 3

; currentUser stores BYTE OFFSET into arrays
;
; User 0 -> 0
; User 1 -> 2
; User 2 -> 4

currentUser      DW 0FFFFH


;====================================================
;              TRANSACTION STACK
;====================================================

; Each transaction = 4 WORDS = 8 bytes
;
; WORD 0 = Transaction Type
;          1 = Deposit
;          2 = Transfer
;
; WORD 1 = Sender / Account ID
;
; WORD 2 = Receiver Account ID
;
; WORD 3 = Amount
;
; Maximum transactions = 50

MAX_TRANSACTIONS EQU 50

transactionStack DW 250 DUP(?)

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
LOAN_PUSH_TX        EQU LOAN_PUSH_ADAPTER

; The value must match the number of accounts allocated by the shared system.
MAX_ACCOUNTS EQU 200

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



TX_DEPOSIT EQU 1
TX_TRANSFER EQU 2
TX_WITHDRAW EQU 3
TX_LOAN_APPROVED EQU 31
TX_LOAN_REPAY EQU 32
TX_LOAN_PAID EQU 33
TX_RECORD_WORDS EQU 5
sumDeposit DD 0
sumWithdraw DD 0
sumTransfer DD 0
sumCount DW 0
txMenuText DB 13,10,'TRANSACTION MENU',13,10,'1. Transaction History',13,10,'2. Account Summary',13,10,'3. Back',13,10,'Choose: $'
txTitle DB 13,10,'TRANSACTION HISTORY (newest first)$'
txNone DB 13,10,'No transactions available.$'
txFull DB 13,10,'Transaction history full.$'
txDeposit DB 13,10,'Deposit: $'
txWithdraw DB 13,10,'Withdrawal: $'
txTransfer DB 13,10,'Transfer: $'
txApproved DB 13,10,'Loan Approved: $'
txRepay DB 13,10,'Loan Repayment: $'
txPaid DB 13,10,'Loan Paid: $'
sumTitle DB 13,10,'ACCOUNT SUMMARY$'
sumId DB 13,10,'Account ID: $'
sumBal DB 13,10,'Current balance: $'
sumDep DB 13,10,'Total deposits: $'
sumWith DB 13,10,'Total withdrawals: $'
sumTrans DB 13,10,'Total transfers: $'
sumN DB 13,10,'Total transactions: $'


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



transactionTop   DW 0


;====================================================
;                    REGISTRATION
;====================================================

registerMsg      DB "ACCOUNT REGISTRATION$"

nameMsg          DB "Enter Name: $"

pinMsg           DB "Create 4-digit PIN: $"

regSuccessMsg    DB "Account Created Successfully!$"

generatedIDMsg   DB "Your Account ID: $"

fullMsg          DB "Maximum Account Limit Reached!$"

invalidPinMsg    DB "PIN Must Be 4 Digits!$"

nameErrorMsg     DB "Name Cannot Be Empty!$"


;====================================================
;                    LOGIN
;====================================================

loginMsg         DB "LOGIN$"

loginIDMsg       DB "Enter Account ID: $"

loginPinMsg      DB "Enter PIN: $"

loginSuccessMsg  DB "Login Successful!$"

wrongIDMsg       DB "Account ID Not Found!$"

wrongPinMsg      DB "Incorrect PIN!$"


;====================================================
;              ACCOUNT INFORMATION
;====================================================

accountInfoMsg   DB "ACCOUNT INFORMATION$"

showNameMsg      DB "Name: $"

showIDMsg        DB "Account ID: $"

showBalMsg       DB "Current Balance: $"


;====================================================
;                    CHANGE PIN
;====================================================

changePinMsg     DB "CHANGE PIN$"

oldPinMsg        DB "Enter Current PIN: $"

newPinMsg        DB "Enter New 4-digit PIN: $"

pinChangedMsg    DB "PIN Changed Successfully!$"

logoutMsg        DB "Logged Out Successfully!$"


;====================================================
;                    WITHDRAW
;====================================================

withdrawMsg      DB "WITHDRAW MONEY$"

withdrawPrompt   DB "Enter Withdrawal Amount: $"

withdrawSuccess  DB "Withdrawal Successful!$"

insufficientMsg  DB "Insufficient Balance!$"

zeroAmountMsg    DB "Amount Cannot Be Zero!$"

remainingMsg     DB "Remaining Balance: $"


;====================================================
;                    DEPOSIT
;====================================================

depositMsg       DB "DEPOSIT MONEY$"

depositAccountMsg DB "Enter Account ID for Deposit: $"

depositPrompt    DB "Enter Deposit Amount: $"

depositSuccess   DB "Deposit Successful!$"

depositOverflowMsg DB "Deposit Failed! Balance Limit Exceeded!$"


;====================================================
;                    TRANSFER
;====================================================

transferMsg      DB "MONEY TRANSFER$"

transferReceiverMsg DB "Enter Receiver Account ID: $"

transferAmountMsg DB "Enter Transfer Amount: $"

transferSuccess  DB "Transfer Successful!$"

transferSameMsg  DB "Sender And Receiver Cannot Be Same!$"

transferOverflowMsg DB "Transfer Failed! Receiver Balance Limit Exceeded!$"



;====================================================
;                  FORGOT PIN
;====================================================

securityMsg      DB "Enter Last 4 Digits of Phone Number: $"

forgotTitle      DB "FORGOT PIN$"

forgotIDMsg      DB "Enter Account ID: $"

wrongSecurityMsg DB "Incorrect Security Answer!$"

resetPinMsg      DB "Enter New 4-digit PIN: $"

resetSuccessMsg  DB "PIN Reset Successfully!$"

forgotAskMsg     DB "Forgot PIN? Press 1 to Recover, Any Other Key to Return: $"


;====================================================
;                  INPUT STATUS
;====================================================

; READ_NUMBER sets this to 1 if the entered
; number is greater than 65535.

inputOverflow    DB 0


;====================================================
;                    CODE SEGMENT
;====================================================

.CODE


;====================================================
;                     MAIN
;====================================================

MAIN PROC

    MOV AX,@DATA
    MOV DS,AX


;====================================================
;                  WELCOME SCREEN
;====================================================

START_SCREEN:

    NEWLINE

    PRINT_STRING welcomeMsg

    NEWLINE


;====================================================
;                  START MENU
;====================================================

START_MENU_AGAIN:

    PRINT_STRING startMsg

    MOV AH,1
    INT 21H

    CMP AL,'1'
    JE REGISTER_CALL

    CMP AL,'2'
    JE LOGIN_CALL

    CMP AL,'3'
    JE EXIT_PROGRAM

    JMP START_MENU_AGAIN


;====================================================
;                  REGISTER CALL
;====================================================

REGISTER_CALL:

    CALL REGISTER

    JMP START_MENU_AGAIN


;====================================================
;                    LOGIN CALL
;====================================================

LOGIN_CALL:

    CALL LOGIN

    CMP currentUser,0FFFFH
    JE START_MENU_AGAIN

    JMP ACCOUNT_MENU_SCREEN


;====================================================
;                  ACCOUNT MENU
;====================================================

ACCOUNT_MENU_SCREEN:

    PRINT_STRING accountMenu

    MOV AH,1
    INT 21H

    CMP AL,'1'
    JE ACCOUNT_INFO_CALL

    CMP AL,'2'
    JE WITHDRAW_CALL

    CMP AL,'3'
    JE DEPOSIT_CALL

    CMP AL,'4'
    JE TRANSFER_CALL

    CMP AL,'5'
    JE CHANGE_PIN_CALL

    CMP AL,'6'
    JE HISTORY_CALL
    CMP AL,'7'
    JE LOAN_CALL
    CMP AL,'8'
    JE LOGOUT_CALL

    JMP ACCOUNT_MENU_SCREEN


;====================================================
;              ACCOUNT INFORMATION
;====================================================

ACCOUNT_INFO_CALL:

    CALL SHOW_ACCOUNT

    JMP ACCOUNT_MENU_SCREEN


;====================================================
;                    WITHDRAW
;====================================================

WITHDRAW_CALL:

    CALL WITHDRAW

    JMP ACCOUNT_MENU_SCREEN


;====================================================
;                    DEPOSIT
;====================================================

DEPOSIT_CALL:

    CALL DEPOSIT

    JMP ACCOUNT_MENU_SCREEN


;====================================================
;                    TRANSFER
;====================================================

TRANSFER_CALL:

    CALL TRANSFER

    JMP ACCOUNT_MENU_SCREEN


;====================================================
;                  CHANGE PIN
;====================================================

CHANGE_PIN_CALL:

    CALL CHANGE_PIN

    JMP ACCOUNT_MENU_SCREEN


;====================================================
;               TRANSACTION HISTORY
;====================================================

HISTORY_CALL:

    CALL TRANSACTION_MENU
    JMP ACCOUNT_MENU_SCREEN

LOAN_CALL:
    CALL LOAN_MENU
    JMP ACCOUNT_MENU_SCREEN


;====================================================
;                     LOGOUT
;====================================================

LOGOUT_CALL:

    MOV currentUser,0FFFFH

    NEWLINE

    PRINT_STRING logoutMsg

    NEWLINE

    JMP START_SCREEN


;====================================================
;                     EXIT
;====================================================

EXIT_PROGRAM:

    MOV AX,4C00H
    INT 21H

MAIN ENDP


;====================================================
;                  REGISTER PROCEDURE
;====================================================

REGISTER PROC

    NEWLINE

    PRINT_STRING registerMsg

    NEWLINE


;====================================================
;              CHECK ACCOUNT LIMIT
;====================================================

    CMP userCount,100
    JGE REGISTER_FULL


;====================================================
;                    INPUT NAME
;====================================================

NAME_AGAIN:

    PRINT_STRING nameMsg


;----------------------------------------------------
; Calculate name-array position
;----------------------------------------------------

    MOV AX,userCount

    MOV BX,11

    MUL BX

    MOV SI,AX

    MOV BX,0


NAME_INPUT:

    MOV AH,1
    INT 21H

    CMP AL,13
    JE NAME_FINISHED

    CMP BX,10
    JGE NAME_INPUT

    MOV names[SI],AL

    INC SI
    INC BX

    JMP NAME_INPUT


NAME_FINISHED:

    CMP BX,0
    JE EMPTY_NAME

    MOV names[SI],'$'


;====================================================
;              GENERATE ACCOUNT ID
;====================================================

    MOV SI,userCount

    ADD SI,SI

    MOV AX,userCount

    ADD AX,1001

    MOV accountIDs[SI],AX


;====================================================
;                    INPUT PIN
;====================================================

INPUT_NEW_PIN:

    NEWLINE

    PRINT_STRING pinMsg

    PUSH SI

    CALL READ_NUMBER

    MOV BX,AX

    POP SI

    CMP inputOverflow,1
    JE INVALID_NEW_PIN

    CMP BX,1000
    JB INVALID_NEW_PIN

    CMP BX,9999
    JA INVALID_NEW_PIN

    MOV pins[SI],BX


;====================================================
;                SECURITY ANSWER
;====================================================

    NEWLINE

    PRINT_STRING securityMsg

    PUSH SI

    CALL READ_NUMBER

    MOV BX,AX

    POP SI

    CMP inputOverflow,1
    JE SECURITY_INPUT_ZERO

    MOV securityAnswers[SI],BX

    JMP SECURITY_DONE


SECURITY_INPUT_ZERO:

    MOV securityAnswers[SI],0


SECURITY_DONE:


;====================================================
;              OPENING BALANCE
;====================================================

    MOV balances[SI],0


;====================================================
;             REGISTRATION SUCCESS
;====================================================

    NEWLINE

    PRINT_STRING regSuccessMsg

    NEWLINE

    PRINT_STRING generatedIDMsg

    MOV AX,accountIDs[SI]

    CALL PRINT_NUMBER

    NEWLINE

    INC userCount

    RET


;====================================================
;                  EMPTY NAME
;====================================================

EMPTY_NAME:

    NEWLINE

    PRINT_STRING nameErrorMsg

    NEWLINE

    JMP NAME_AGAIN


;====================================================
;                  INVALID PIN
;====================================================

INVALID_NEW_PIN:

    NEWLINE

    PRINT_STRING invalidPinMsg

    NEWLINE

    JMP INPUT_NEW_PIN


;====================================================
;                MAXIMUM ACCOUNTS
;====================================================

REGISTER_FULL:

    NEWLINE

    PRINT_STRING fullMsg

    NEWLINE

    RET

REGISTER ENDP


;====================================================
;                    LOGIN
;====================================================

LOGIN PROC

    MOV currentUser,0FFFFH

    NEWLINE

    PRINT_STRING loginMsg

    NEWLINE

    CMP userCount,0
    JE ACCOUNT_NOT_FOUND


;====================================================
;                ENTER ACCOUNT ID
;====================================================

    PRINT_STRING loginIDMsg

    CALL READ_NUMBER

    CMP inputOverflow,1
    JE ACCOUNT_NOT_FOUND

    MOV BX,AX


;====================================================
;               SEARCH ACCOUNT ARRAY
;====================================================

    MOV CX,userCount

    MOV SI,0


LOGIN_SEARCH:

    CMP BX,accountIDs[SI]

    JE ID_FOUND

    ADD SI,2

    LOOP LOGIN_SEARCH


;====================================================
;              ACCOUNT NOT FOUND
;====================================================

ACCOUNT_NOT_FOUND:

    NEWLINE

    PRINT_STRING wrongIDMsg

    NEWLINE

    RET


;====================================================
;                  CHECK PIN
;====================================================

ID_FOUND:

    NEWLINE

    PRINT_STRING loginPinMsg

    PUSH SI

    CALL READ_NUMBER

    MOV BX,AX

    POP SI

    CMP inputOverflow,1
    JE PIN_WRONG

    CMP BX,pins[SI]
    JNE PIN_WRONG


;====================================================
;                LOGIN SUCCESS
;====================================================

    MOV currentUser,SI

    NEWLINE

    PRINT_STRING loginSuccessMsg

    NEWLINE

    RET


;====================================================
;                   WRONG PIN
;====================================================

PIN_WRONG:

    NEWLINE

    PRINT_STRING wrongPinMsg

    NEWLINE

    PRINT_STRING forgotAskMsg

    MOV AH,1
    INT 21H

    CMP AL,'1'
    JE FORGOT_FROM_LOGIN

    RET


FORGOT_FROM_LOGIN:

    CALL FORGOT_PIN

    RET

LOGIN ENDP


;====================================================
;              SHOW ACCOUNT INFORMATION
;====================================================

SHOW_ACCOUNT PROC

    NEWLINE

    PRINT_STRING accountInfoMsg

    NEWLINE


;====================================================
;                       NAME
;====================================================

    PRINT_STRING showNameMsg

    MOV AX,currentUser

    MOV DX,0

    MOV BX,2

    DIV BX

    MOV BX,11

    MUL BX

    LEA DX,names

    ADD DX,AX

    MOV AH,9

    INT 21H


;====================================================
;                    ACCOUNT ID
;====================================================

    NEWLINE

    PRINT_STRING showIDMsg

    MOV SI,currentUser

    MOV AX,accountIDs[SI]

    CALL PRINT_NUMBER


;====================================================
;                     BALANCE
;====================================================

    NEWLINE

    PRINT_STRING showBalMsg

    MOV SI,currentUser

    MOV AX,balances[SI]

    CALL PRINT_NUMBER

    NEWLINE

    RET

SHOW_ACCOUNT ENDP


;====================================================
;                 WITHDRAW PROCEDURE
;====================================================

WITHDRAW PROC

    NEWLINE

    PRINT_STRING withdrawMsg

    NEWLINE

    MOV SI,currentUser


;====================================================
;              DISPLAY CURRENT BALANCE
;====================================================

    PRINT_STRING showBalMsg

    MOV AX,balances[SI]

    CALL PRINT_NUMBER

    NEWLINE


;====================================================
;             INPUT WITHDRAWAL AMOUNT
;====================================================

    PRINT_STRING withdrawPrompt

    PUSH SI

    CALL READ_NUMBER

    MOV BX,AX

    MOV DL,inputOverflow

    POP SI

    CMP DL,1
    JE WITHDRAW_OVERFLOW


;====================================================
;                  ZERO CHECK
;====================================================

    CMP BX,0
    JE INVALID_WITHDRAW


;====================================================
;             CHECK AVAILABLE BALANCE
;====================================================

    MOV AX,balances[SI]

    CMP BX,AX

    JA NOT_ENOUGH


;====================================================
;                    SUBTRACT
;====================================================

    SUB AX,BX

    MOV balances[SI],AX
    MOV DX,BX
    MOV BX,accountIDs[SI]
    MOV CX,0FFFFH
    MOV AX,TX_WITHDRAW
    XOR BP,BP
    CALL PUSH_TRANSACTION


;====================================================
;                    SUCCESS
;====================================================

    NEWLINE

    PRINT_STRING withdrawSuccess

    NEWLINE

    PRINT_STRING remainingMsg

    MOV AX,balances[SI]

    CALL PRINT_NUMBER

    NEWLINE

    RET


;====================================================
;                ZERO WITHDRAWAL
;====================================================

INVALID_WITHDRAW:

    NEWLINE

    PRINT_STRING zeroAmountMsg

    NEWLINE

    RET


;====================================================
;               INSUFFICIENT BALANCE
;====================================================

NOT_ENOUGH:

    NEWLINE

    PRINT_STRING insufficientMsg

    NEWLINE

    RET


;====================================================
;              NUMBER TOO LARGE
;====================================================

WITHDRAW_OVERFLOW:

    NEWLINE

    PRINT_STRING insufficientMsg

    NEWLINE

    RET

WITHDRAW ENDP


;====================================================
;                  DEPOSIT PROCEDURE
;====================================================

DEPOSIT PROC

    NEWLINE

    PRINT_STRING depositMsg

    NEWLINE


;====================================================
;              SELECT ACCOUNT
;====================================================

    PRINT_STRING depositAccountMsg

    CALL READ_NUMBER

    CMP inputOverflow,1
    JE DEPOSIT_INVALID_ACCOUNT


; AX = entered account ID

    CALL FIND_ACCOUNT

    JC DEPOSIT_INVALID_ACCOUNT


; SI = account offset


;====================================================
;              DISPLAY CURRENT BALANCE
;====================================================

    NEWLINE

    PRINT_STRING showBalMsg

    MOV AX,balances[SI]

    CALL PRINT_NUMBER

    NEWLINE


;====================================================
;                ENTER AMOUNT
;====================================================

    PRINT_STRING depositPrompt

    PUSH SI

    CALL READ_NUMBER

    MOV BX,AX

    MOV DL,inputOverflow

    POP SI

    CMP DL,1
    JE DEPOSIT_OVERFLOW


;====================================================
;                   ZERO CHECK
;====================================================

    CMP BX,0

    JE DEPOSIT_ZERO


;====================================================
;              CHECK BALANCE OVERFLOW
;====================================================

    MOV AX,balances[SI]

    ADD AX,BX

    JC DEPOSIT_OVERFLOW


;====================================================
;                UPDATE BALANCE
;====================================================

    MOV balances[SI],AX


;====================================================
;              PUSH TRANSACTION
;====================================================

; Type = 1
; Sender/Account = deposited account
; Receiver = FFFF
; Amount = BX

    MOV DX,BX
    MOV BX,accountIDs[SI]
    MOV CX,0FFFFH
    MOV AX,TX_DEPOSIT
    XOR BP,BP
    CALL PUSH_TRANSACTION


;====================================================
;                 SUCCESS
;====================================================

    NEWLINE

    PRINT_STRING depositSuccess

    NEWLINE

    PRINT_STRING remainingMsg

    MOV AX,balances[SI]

    CALL PRINT_NUMBER

    NEWLINE

    RET


;====================================================
;               INVALID ACCOUNT
;====================================================

DEPOSIT_INVALID_ACCOUNT:

    NEWLINE

    PRINT_STRING wrongIDMsg

    NEWLINE

    RET


;====================================================
;                 ZERO DEPOSIT
;====================================================

DEPOSIT_ZERO:

    NEWLINE

    PRINT_STRING zeroAmountMsg

    NEWLINE

    RET


;====================================================
;                OVERFLOW
;====================================================

DEPOSIT_OVERFLOW:

    NEWLINE

    PRINT_STRING depositOverflowMsg

    NEWLINE

    RET

DEPOSIT ENDP


;====================================================
;               MONEY TRANSFER PROCEDURE
;====================================================

TRANSFER PROC

    NEWLINE

    PRINT_STRING transferMsg

    NEWLINE


;====================================================
;              GET SENDER
;====================================================

    MOV SI,currentUser

    MOV BX,accountIDs[SI]


;====================================================
;             GET RECEIVER ACCOUNT
;====================================================

    PRINT_STRING transferReceiverMsg

; Save sender offset and sender ID

    PUSH SI
    PUSH BX

    CALL READ_NUMBER

    CMP inputOverflow,1
    JE TRANSFER_INVALID_ACCOUNT

; AX still contains receiver account ID
; Find receiver BEFORE NEWLINE changes AX

    CALL FIND_ACCOUNT

    JC TRANSFER_INVALID_ACCOUNT

; SI = receiver offset

    MOV DI,SI

    MOV CX,accountIDs[DI]

; Restore sender information

    POP BX
    POP SI

; Now it is safe to print a newline

    NEWLINE


;====================================================
;             SAME ACCOUNT CHECK
;====================================================

    CMP DI,SI

    JE TRANSFER_SAME_ACCOUNT


;====================================================
;              ENTER TRANSFER AMOUNT
;====================================================

    PRINT_STRING transferAmountMsg

    PUSH SI

    CALL READ_NUMBER

    MOV DX,AX

    POP SI

    CMP inputOverflow,1

    JE TRANSFER_AMOUNT_OVERFLOW


;====================================================
;                   ZERO CHECK
;====================================================

    CMP DX,0

    JE TRANSFER_ZERO


;====================================================
;             CHECK SENDER BALANCE
;====================================================

    MOV AX,balances[SI]

    CMP DX,AX

    JA TRANSFER_NOT_ENOUGH


;====================================================
;          CHECK RECEIVER BALANCE OVERFLOW
;====================================================

    MOV AX,balances[DI]

    ADD AX,DX

    JC TRANSFER_OVERFLOW


;====================================================
;                REMOVE FROM SENDER
;====================================================

    MOV AX,balances[SI]

    SUB AX,DX

    MOV balances[SI],AX


;====================================================
;               ADD TO RECEIVER
;====================================================

    MOV AX,balances[DI]

    ADD AX,DX

    MOV balances[DI],AX


;====================================================
;              PUSH TRANSFER
;====================================================

; Type = 2
; Sender ID = BX
; Receiver ID = CX
; Amount = DX

    MOV AX,TX_TRANSFER
    XOR BP,BP
    CALL PUSH_TRANSACTION


;====================================================
;                  SUCCESS
;====================================================

    NEWLINE

    PRINT_STRING transferSuccess

    NEWLINE

    RET


;====================================================
;              INVALID RECEIVER
;====================================================

TRANSFER_INVALID_ACCOUNT:

    POP BX
    POP SI

    NEWLINE

    PRINT_STRING wrongIDMsg

    NEWLINE

    RET


;====================================================
;               SAME ACCOUNT
;====================================================

TRANSFER_SAME_ACCOUNT:

    NEWLINE

    PRINT_STRING transferSameMsg

    NEWLINE

    RET


;====================================================
;                ZERO TRANSFER
;====================================================

TRANSFER_ZERO:

    NEWLINE

    PRINT_STRING zeroAmountMsg

    NEWLINE

    RET


;====================================================
;             INSUFFICIENT BALANCE
;====================================================

TRANSFER_NOT_ENOUGH:

    NEWLINE

    PRINT_STRING insufficientMsg

    NEWLINE

    RET


;====================================================
;                 OVERFLOW
;====================================================

TRANSFER_OVERFLOW:

    NEWLINE

    PRINT_STRING transferOverflowMsg

    NEWLINE

    RET


;====================================================
;             TRANSFER AMOUNT TOO LARGE
;====================================================

TRANSFER_AMOUNT_OVERFLOW:

    NEWLINE

    PRINT_STRING insufficientMsg

    NEWLINE

    RET

TRANSFER ENDP


;====================================================
;             FIND ACCOUNT PROCEDURE
;
; Input:
;     AX = Account ID
;
; Output:
;     SI = array offset
;     CF = 0 if found
;     CF = 1 if not found
;====================================================

FIND_ACCOUNT PROC

    MOV BX,AX

    MOV CX,userCount

    MOV SI,0


FIND_LOOP:

    CMP BX,accountIDs[SI]

    JE ACCOUNT_FOUND

    ADD SI,2

    LOOP FIND_LOOP


;====================================================
;                  NOT FOUND
;====================================================

    STC

    RET


;====================================================
;                    FOUND
;====================================================

ACCOUNT_FOUND:

    CLC

    RET

FIND_ACCOUNT ENDP


;====================================================
;             PUSH TRANSACTION
;
; Inputs:
;
; AX = transaction type
;      1 = Deposit
;      2 = Transfer
;
; BX = sender/account ID
;
; CX = receiver ID
;
; DX = amount
;====================================================

PUSH_TRANSACTION PROC
 PUSH AX
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH SI
 PUSH DI
 PUSH BP
 MOV SI,transactionTop
 CMP SI,MAX_TRANSACTIONS
 JAE PTFULL
 MOV DI,SI
 SHL DI,1
 MOV SI,DI
 SHL DI,1
 SHL DI,1
 ADD DI,SI
 MOV transactionStack[DI],AX
 MOV transactionStack[DI+2],BX
 MOV transactionStack[DI+4],CX
 MOV transactionStack[DI+6],DX
 MOV transactionStack[DI+8],BP
 INC transactionTop
 CLC
 JMP PTDONE
PTFULL:
 PRINT_STRING txFull
 STC
PTDONE:
 POP BP
 POP DI
 POP SI
 POP DX
 POP CX
 POP BX
 POP AX
 RET
PUSH_TRANSACTION ENDP

LOAN_PUSH_ADAPTER PROC
 PUSH AX
 PUSH BX
 PUSH CX
 PUSH DX
 PUSH BP
 PUSH SI
 MOV SI,BX
 MOV BP,DX
 XOR AH,AH
 MOV BX,currentUser
 MOV BX,accountIDs[BX]
 MOV CX,0FFFFH
 MOV DX,SI
 CALL PUSH_TRANSACTION
 POP SI
 POP BP
 POP DX
 POP CX
 POP BX
 POP AX
 RET
LOAN_PUSH_ADAPTER ENDP

TRANSACTION_MENU PROC
TM0:
 NEWLINE
 PRINT_STRING txMenuText
 MOV AH,1
 INT 21H
 CMP AL,'1'
 JE TM1
 CMP AL,'2'
 JE TM2
 CMP AL,'3'
 JE TM9
 JMP TM0
TM1: CALL DISPLAY_HISTORY
 JMP TM0
TM2: CALL ACCOUNT_SUMMARY
 JMP TM0
TM9: RET
TRANSACTION_MENU ENDP

DISPLAY_HISTORY PROC
 NEWLINE
 PRINT_STRING txTitle
 CMP transactionTop,0
 JE DHNONE
 MOV SI,currentUser
 MOV BP,accountIDs[SI]
 MOV DI,transactionTop
 XOR CX,CX
DHL:
 DEC DI
 MOV SI,DI
 SHL SI,1
 MOV AX,SI
 SHL SI,1
 SHL SI,1
 ADD SI,AX
 MOV AX,transactionStack[SI]
 CMP AX,TX_TRANSFER
 JE DHTR
 CMP transactionStack[SI+2],BP
 JNE DHN
 JMP DHS
DHTR:
 CMP transactionStack[SI+2],BP
 JE DHS
 CMP transactionStack[SI+4],BP
 JNE DHN
DHS:
 CALL DISPLAY_TRANSACTION
 INC CX
DHN:
 CMP DI,0
 JNE DHL
 OR CX,CX
 JNZ DHD
DHNONE:
 PRINT_STRING txNone
DHD: RET
DISPLAY_HISTORY ENDP

DISPLAY_TRANSACTION PROC
 PUSH AX
 PUSH DX
 MOV AX,transactionStack[SI]
 CMP AX,TX_DEPOSIT
 JE DTD
 CMP AX,TX_WITHDRAW
 JE DTW
 CMP AX,TX_TRANSFER
 JE DTT
 CMP AX,TX_LOAN_APPROVED
 JE DTA
 CMP AX,TX_LOAN_REPAY
 JE DTR
 PRINT_STRING txPaid
 JMP DTP
DTD: PRINT_STRING txDeposit
 JMP DTP
DTW: PRINT_STRING txWithdraw
 JMP DTP
DTT: PRINT_STRING txTransfer
 JMP DTP
DTA: PRINT_STRING txApproved
 JMP DTP
DTR: PRINT_STRING txRepay
DTP:
 MOV AX,transactionStack[SI+6]
 MOV DX,transactionStack[SI+8]
 CALL PRINT_DWORD
 POP DX
 POP AX
 RET
DISPLAY_TRANSACTION ENDP

ACCOUNT_SUMMARY PROC
 NEWLINE
 PRINT_STRING sumTitle
 MOV SI,currentUser
 PRINT_STRING sumId
 MOV AX,accountIDs[SI]
 CALL PRINT_NUMBER
 PRINT_STRING sumBal
 MOV AX,balances[SI]
 CALL PRINT_NUMBER
 CALL CALCULATE_STATISTICS
 PRINT_STRING sumDep
 MOV AX,WORD PTR sumDeposit
 MOV DX,WORD PTR sumDeposit+2
 CALL PRINT_DWORD
 PRINT_STRING sumWith
 MOV AX,WORD PTR sumWithdraw
 MOV DX,WORD PTR sumWithdraw+2
 CALL PRINT_DWORD
 PRINT_STRING sumTrans
 MOV AX,WORD PTR sumTransfer
 MOV DX,WORD PTR sumTransfer+2
 CALL PRINT_DWORD
 PRINT_STRING sumN
 MOV AX,sumCount
 CALL PRINT_NUMBER
 CALL VIEW_LOAN
 RET
ACCOUNT_SUMMARY ENDP

CALCULATE_STATISTICS PROC
 MOV WORD PTR sumDeposit,0
 MOV WORD PTR sumDeposit+2,0
 MOV WORD PTR sumWithdraw,0
 MOV WORD PTR sumWithdraw+2,0
 MOV WORD PTR sumTransfer,0
 MOV WORD PTR sumTransfer+2,0
 MOV sumCount,0
 MOV SI,currentUser
 MOV BP,accountIDs[SI]
 MOV CX,transactionTop
 XOR DI,DI
 JCXZ CSD
CSL:
 MOV SI,DI
 SHL SI,1
 MOV AX,SI
 SHL SI,1
 SHL SI,1
 ADD SI,AX
 MOV AX,transactionStack[SI]
 CMP AX,TX_TRANSFER
 JE CSTM
 CMP transactionStack[SI+2],BP
 JNE CSN
 JMP CSC
CSTM:
 CMP transactionStack[SI+2],BP
 JE CSC
 CMP transactionStack[SI+4],BP
 JNE CSN
CSC:
 INC sumCount
 MOV AX,transactionStack[SI]
 CMP AX,TX_DEPOSIT
 JE CSDP
 CMP AX,TX_WITHDRAW
 JE CSWD
 CMP AX,TX_TRANSFER
 JE CSTR
 JMP CSN
CSDP:
 MOV AX,transactionStack[SI+6]
 MOV DX,transactionStack[SI+8]
 ADD WORD PTR sumDeposit,AX
 ADC WORD PTR sumDeposit+2,DX
 JMP CSN
CSWD:
 MOV AX,transactionStack[SI+6]
 MOV DX,transactionStack[SI+8]
 ADD WORD PTR sumWithdraw,AX
 ADC WORD PTR sumWithdraw+2,DX
 JMP CSN
CSTR:
 MOV AX,transactionStack[SI+6]
 MOV DX,transactionStack[SI+8]
 ADD WORD PTR sumTransfer,AX
 ADC WORD PTR sumTransfer+2,DX
CSN:
 INC DI
 LOOP CSL
CSD: RET
CALCULATE_STATISTICS ENDP


;====================================================
;                 CHANGE PIN
;====================================================

CHANGE_PIN PROC

    NEWLINE

    PRINT_STRING changePinMsg

    NEWLINE

    MOV SI,currentUser


;====================================================
;              CURRENT PIN
;====================================================

    PRINT_STRING oldPinMsg

    PUSH SI

    CALL READ_NUMBER

    MOV BX,AX

    POP SI

    CMP inputOverflow,1

    JE CHANGE_PIN_WRONG

    CMP BX,pins[SI]

    JNE CHANGE_PIN_WRONG


;====================================================
;                 NEW PIN
;====================================================

CHANGE_NEW_PIN:

    NEWLINE

    PRINT_STRING newPinMsg

    PUSH SI

    CALL READ_NUMBER

    MOV BX,AX

    POP SI

    CMP inputOverflow,1

    JE CHANGE_INVALID_PIN

    CMP BX,1000

    JB CHANGE_INVALID_PIN

    CMP BX,9999

    JA CHANGE_INVALID_PIN

    MOV pins[SI],BX


;====================================================
;                   SUCCESS
;====================================================

    NEWLINE

    PRINT_STRING pinChangedMsg

    NEWLINE

    RET


;====================================================
;                INVALID PIN
;====================================================

CHANGE_INVALID_PIN:

    NEWLINE

    PRINT_STRING invalidPinMsg

    NEWLINE

    JMP CHANGE_NEW_PIN


;====================================================
;               WRONG CURRENT PIN
;====================================================

CHANGE_PIN_WRONG:

    NEWLINE

    PRINT_STRING wrongPinMsg

    NEWLINE

    RET

CHANGE_PIN ENDP


;====================================================
;                 FORGOT PIN
;====================================================

FORGOT_PIN PROC

    NEWLINE

    PRINT_STRING forgotTitle

    NEWLINE

    PRINT_STRING forgotIDMsg

    CALL READ_NUMBER

    CMP inputOverflow,1

    JE FORGOT_ID_NOT_FOUND

    MOV BX,AX

    MOV CX,userCount

    MOV SI,0


FORGOT_SEARCH:

    CMP BX,accountIDs[SI]

    JE FORGOT_ID_FOUND

    ADD SI,2

    LOOP FORGOT_SEARCH


;====================================================
;               ID NOT FOUND
;====================================================

FORGOT_ID_NOT_FOUND:

    NEWLINE

    PRINT_STRING wrongIDMsg

    NEWLINE

    RET


;====================================================
;                ID FOUND
;====================================================

FORGOT_ID_FOUND:

    NEWLINE

    PRINT_STRING securityMsg

    PUSH SI

    CALL READ_NUMBER

    MOV BX,AX

    POP SI

    CMP inputOverflow,1

    JE WRONG_SECURITY

    CMP BX,securityAnswers[SI]

    JNE WRONG_SECURITY


;====================================================
;                  RESET PIN
;====================================================

RESET_PIN:

    NEWLINE

    PRINT_STRING resetPinMsg

    PUSH SI

    CALL READ_NUMBER

    MOV BX,AX

    POP SI

    CMP inputOverflow,1

    JE INVALID_RESET_PIN

    CMP BX,1000

    JB INVALID_RESET_PIN

    CMP BX,9999

    JA INVALID_RESET_PIN

    MOV pins[SI],BX


;====================================================
;                  SUCCESS
;====================================================

    NEWLINE

    PRINT_STRING resetSuccessMsg

    NEWLINE

    RET


;====================================================
;              WRONG SECURITY
;====================================================

WRONG_SECURITY:

    NEWLINE

    PRINT_STRING wrongSecurityMsg

    NEWLINE

    RET


;====================================================
;              INVALID RESET PIN
;====================================================

INVALID_RESET_PIN:

    NEWLINE

    PRINT_STRING invalidPinMsg

    NEWLINE

    JMP RESET_PIN

FORGOT_PIN ENDP


;====================================================
;                  READ NUMBER
;
; Input:
;     User types decimal number
;
; Output:
;     AX = number if <= 65535
;
;     inputOverflow = 1 if > 65535
;
;====================================================

READ_NUMBER PROC

    MOV BX,0

    MOV inputOverflow,0


READ_DIGIT:

    MOV AH,1

    INT 21H


;====================================================
;                  ENTER CHECK
;====================================================

    CMP AL,13

    JE NUMBER_DONE


;====================================================
;              IGNORE NON-DIGITS
;====================================================

    CMP AL,'0'

    JB READ_DIGIT

    CMP AL,'9'

    JA READ_DIGIT


;====================================================
;              ASCII -> NUMBER
;====================================================

    SUB AL,30H

    MOV AH,0

    PUSH AX


;====================================================
;          CHECK NUMBER * 10 + DIGIT
;
; Maximum unsigned WORD = 65535
;
; Before:
;
;       old * 10 + digit
;
; We check whether old > 6553.
;
; If old = 6553, digit must be <= 5.
;====================================================

    MOV AX,BX

    CMP AX,6553

    JA NUMBER_OVERFLOW

    JNE NUMBER_SAFE_MULTIPLY

; old number = 6553
; only digits 0-5 are allowed

    POP AX

    CMP AX,5

    JA NUMBER_OVERFLOW_AFTER_POP

    PUSH AX


NUMBER_SAFE_MULTIPLY:

    MOV AX,BX

    MOV CX,10

    MUL CX

    MOV BX,AX

    POP AX

    ADD BX,AX

    JMP READ_DIGIT


;====================================================
;                NUMBER OVERFLOW
;====================================================

NUMBER_OVERFLOW:

    POP AX

    MOV inputOverflow,1


; Consume remaining digits until ENTER

OVERFLOW_CONSUME:

    MOV AH,1

    INT 21H

    CMP AL,13

    JNE OVERFLOW_CONSUME

    MOV AX,0FFFFH

    RET


NUMBER_OVERFLOW_AFTER_POP:

    MOV inputOverflow,1


; Consume remaining digits until ENTER

OVERFLOW_CONSUME_2:

    MOV AH,1

    INT 21H

    CMP AL,13

    JNE OVERFLOW_CONSUME_2

    MOV AX,0FFFFH

    RET


;====================================================
;                    DONE
;====================================================

NUMBER_DONE:

    MOV AX,BX

    RET

READ_NUMBER ENDP


;====================================================
;                PRINT NUMBER
;
; Input:
;     AX = unsigned number
;====================================================

PRINT_NUMBER PROC


;====================================================
;                    ZERO
;====================================================

    CMP AX,0

    JNE PRINT_NON_ZERO

    MOV DL,'0'

    MOV AH,2

    INT 21H

    RET


;====================================================
;                NON-ZERO
;====================================================

PRINT_NON_ZERO:

    MOV CX,0

    MOV BX,10


DIVIDE_NUMBER:

    MOV DX,0

    DIV BX

    PUSH DX

    INC CX

    CMP AX,0

    JNE DIVIDE_NUMBER


;====================================================
;                PRINT DIGITS
;====================================================

PRINT_DIGITS:

    POP DX

    ADD DL,30H

    MOV AH,2

    INT 21H

    LOOP PRINT_DIGITS

    RET

PRINT_NUMBER ENDP



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
    ; Deduct the requested amount from balance
    MOV AX, SI
    MOV DX, DI
    CALL DEDUCT_BALANCE

    ; Subtract requested (SI:DI) from remaining loan (loanRemaining[BX])
    MOV AX, WORD PTR loanRemaining[BX]
    MOV DX, WORD PTR loanRemaining[BX+2]

    SUB AX, SI          ; low word subtract, sets CF if it borrowed
    SBB DX, DI          ; high word subtract, minus the borrow from above

    MOV WORD PTR loanRemaining[BX], AX
    MOV WORD PTR loanRemaining[BX+2], DX

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
    MOV BX,currentUser
    MOV AX,balances[BX]
    XOR DX,DX
    POP BX
    RET
GET_BALANCE ENDP

DEDUCT_BALANCE PROC NEAR
    PUSH BX
    MOV BX,currentUser
    SUB balances[BX],AX
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




;====================================================
;                     END
;====================================================

END MAIN
