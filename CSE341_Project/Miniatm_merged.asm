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

transactionTop   DW 0

TX_DEPOSIT EQU 1
TX_TRANSFER EQU 2
TX_WITHDRAWAL EQU 3
TX_LOAN_APPROVED EQU 31
TX_LOAN_REPAY EQU 32
TX_LOAN_PAID EQU 33
LOAN_NONE EQU 0
LOAN_ACTIVE EQU 1
LOAN_PAID EQU 2

loanMax DD 50000,30000,100000,500000
loanRate DW 8,5,6,7
loanType DW 100 DUP(0)
loanAmount DD 200 DUP(0)
loanInterest DW 100 DUP(0)
loanTotal DD 200 DUP(0)
loanRemaining DD 200 DUP(0)
loanStatus DW 100 DUP(0)
loanSel DW 0
loanReq DD 0
loanInt DD 0
loanActual DW 0
loanExcess DW 0

sumDeposit DD 0
sumWithdraw DD 0
sumTransfer DD 0
sumCount DW 0

loanMenuMsg DB 13,10,'LOAN MANAGEMENT',13,10,'1. Apply for Loan',13,10,'2. View Current Loan',13,10,'3. Repay Loan',13,10,'4. Back',13,10,'Choose: $'
loanTypeMsg DB 13,10,'1.Personal 50000 8%',13,10,'2.Emergency 30000 5%',13,10,'3.Education 100000 6%',13,10,'4.Home 500000 7%',13,10,'Type: $'
loanAmtMsg DB 13,10,'Loan amount: $'
repayAmtMsg DB 13,10,'Repayment amount: $'
badMsg DB 13,10,'Invalid selection.$'
zeroMsg DB 13,10,'Amount must be greater than zero.$'
lowBalMsg DB 13,10,'Minimum balance is 10000.$'
activeLoanMsg DB 13,10,'An active loan already exists.$'
maxLoanMsg DB 13,10,'Amount exceeds loan maximum.$'
approvedMsg DB 13,10,'Loan approved.$'
noLoanMsg DB 13,10,'No loan exists.$'
noActiveMsg DB 13,10,'No active loan.$'
loanFundsMsg DB 13,10,'Insufficient balance.$'
repaidMsg DB 13,10,'Loan repayment recorded.$'
paidMsg DB 13,10,'Loan fully paid.$'
excessMsg DB 13,10,'Excess retained: $'
ltMsg DB 13,10,'Loan type: $'
loMsg DB 13,10,'Original amount: $'
lrMsg DB 13,10,'Interest rate: $'
liMsg DB 13,10,'Interest: $'
ltoMsg DB 13,10,'Total repayment: $'
lremMsg DB 13,10,'Remaining loan: $'
lsMsg DB 13,10,'Status: $'
pName DB 'Personal Loan$'
eName DB 'Emergency Loan$'
edName DB 'Education Loan$'
hName DB 'Home Loan$'
activeName DB 'ACTIVE$'
paidName DB 'PAID$'
pct DB '%$'

txMenuMsg DB 13,10,'TRANSACTION MENU',13,10,'1.Transaction History',13,10,'2.Account Summary',13,10,'3.Back',13,10,'Choose: $'
txTitle DB 13,10,'TRANSACTION HISTORY (newest first)$'
summaryTitle DB 13,10,'ACCOUNT SUMMARY$'
txNone DB 13,10,'No transactions available.$'
txFull DB 13,10,'Transaction history full.$'
depositTxMsg DB 13,10,'Deposit: $'
withdrawTxMsg DB 13,10,'Withdrawal: $'
transferTxMsg DB 13,10,'Transfer: $'
approvedTxMsg DB 13,10,'Loan Approved: $'
repayTxMsg DB 13,10,'Loan Repayment: $'
paidTxMsg DB 13,10,'Loan Paid: $'
idSumMsg DB 13,10,'Account ID: $'
balSumMsg DB 13,10,'Current balance: $'
depSumMsg DB 13,10,'Total deposits: $'
withSumMsg DB 13,10,'Total withdrawals: $'
transSumMsg DB 13,10,'Total transfers: $'
countSumMsg DB 13,10,'Total transactions: $'



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
    JE LOAN_MENU_CALL

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

LOAN_MENU_CALL:

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
    MOV AX,TX_WITHDRAWAL
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


;====================================================
;             CHECK STACK LIMIT
;====================================================

    CMP transactionTop,MAX_TRANSACTIONS

    JGE TRANSACTION_STACK_FULL


;====================================================
;         TEMPORARILY PUSH VALUES ON CPU STACK
;====================================================

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX


;====================================================
;        CALCULATE TRANSACTION STACK OFFSET
;====================================================

    MOV AX,transactionTop

    MOV BX,8

    MUL BX

    MOV SI,AX


;====================================================
;                RESTORE VALUES
;====================================================

    POP DX
    POP CX
    POP BX
    POP AX


;====================================================
;                STORE RECORD
;====================================================

    MOV transactionStack[SI],AX

    MOV transactionStack[SI+2],BX

    MOV transactionStack[SI+4],CX

    MOV transactionStack[SI+6],DX


;====================================================
;              INCREMENT STACK TOP
;====================================================

    INC transactionTop

    CLC

    RET


;====================================================
;                 STACK FULL
;====================================================

TRANSACTION_STACK_FULL:

    NEWLINE

    PRINT_STRING historyFullMsg

    NEWLINE

    STC

    RET

PUSH_TRANSACTION ENDP


;====================================================
;             SHOW TRANSACTION HISTORY
;====================================================

SHOW_HISTORY PROC

    NEWLINE

    PRINT_STRING historyMsg

    NEWLINE


;====================================================
;              CHECK EMPTY STACK
;====================================================

    CMP transactionTop,0

    JE NO_HISTORY


;====================================================
;        GET CURRENT USER ACCOUNT ID
;====================================================

    MOV SI,currentUser

    MOV AX,accountIDs[SI]

    MOV BP,AX

    MOV historyFound,0


;====================================================
;          START FROM TOP OF STACK
;====================================================

    MOV DI,transactionTop

    DEC DI


;====================================================
;              HISTORY LOOP
;====================================================

HISTORY_LOOP:

    MOV AX,DI

    MOV BX,8

    MUL BX

    MOV SI,AX


;====================================================
;                CHECK TYPE
;====================================================

    MOV AX,transactionStack[SI]

    CMP AX,1

    JE HISTORY_DEPOSIT

    CMP AX,2

    JE HISTORY_TRANSFER

    JMP HISTORY_NEXT


;====================================================
;                DEPOSIT RECORD
;====================================================

HISTORY_DEPOSIT:

    MOV AX,transactionStack[SI+2]

    CMP AX,BP

    JNE HISTORY_NEXT

    MOV historyFound,1

    NEWLINE

    PRINT_STRING depositHistoryMsg

    MOV AX,transactionStack[SI+2]

    CALL PRINT_NUMBER

    PRINT_STRING amountHistoryMsg

    MOV AX,transactionStack[SI+6]

    CALL PRINT_NUMBER

    JMP HISTORY_NEXT


;====================================================
;                TRANSFER RECORD
;====================================================

HISTORY_TRANSFER:

; Check sender

    MOV AX,transactionStack[SI+2]

    CMP AX,BP

    JE TRANSFER_HISTORY_MATCH


; Check receiver

    MOV AX,transactionStack[SI+4]

    CMP AX,BP

    JNE HISTORY_NEXT


TRANSFER_HISTORY_MATCH:

    MOV historyFound,1

    NEWLINE

    PRINT_STRING transferHistoryMsg

    MOV AX,transactionStack[SI+2]

    CALL PRINT_NUMBER

    PRINT_STRING transferToMsg

    MOV AX,transactionStack[SI+4]

    CALL PRINT_NUMBER

    PRINT_STRING amountHistoryMsg

    MOV AX,transactionStack[SI+6]

    CALL PRINT_NUMBER


;====================================================
;                NEXT TRANSACTION
;====================================================

HISTORY_NEXT:

    CMP DI,0

    JE HISTORY_FINISHED

    DEC DI

    JMP HISTORY_LOOP


;====================================================
;               HISTORY FINISHED
;====================================================

HISTORY_FINISHED:

    CMP historyFound,0

    JNE HISTORY_DONE

    NEWLINE

    PRINT_STRING noHistoryMsg


HISTORY_DONE:

    NEWLINE

    RET


;====================================================
;                  EMPTY HISTORY
;====================================================

NO_HISTORY:

    PRINT_STRING noHistoryMsg

    NEWLINE

    RET

SHOW_HISTORY ENDP


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


;====================================================
;                     END
;====================================================

END MAIN

