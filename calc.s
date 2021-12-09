MAX_STACK equ 5 ;fixed size becase we could not make dynamic size
MAX_INP_BUF equ 80


section	.rodata			; we define (global) read-only variables in .rodata section
	pr_string: db "%o", 0
    pr_counter: db "%o" ,10 ,0
	line: db 10, 0
	calc: db "calc: ",0

	;MAX_STACK: dd 5
	;g_stack: dd 0 ;for heap allocation


	err_ov: db "Error: Operand Stack Overflow",10,0
	err_un: db "Error: Insufficient Number of Arguments on Stack",10,0
	push_stack_str: db "DEBUG push stack: ",0
	pop_stack_str: db "DEBUG pop stack: ",0
	read_user_str: db "DEBUG read user: ",0


section .bss			; we define (global) uninitialized variables in .bss section
	g_stack_ptr: resd 1            ;The size
	g_stack: resd (MAX_STACK)    ;The array we put inside the linked-list
	inp_buf: resb (MAX_INP_BUF+1)  ;The input buffer
	;MaxStackSize: resd 1
	g_dbg_flag: resd 1             ;debug flag

%macro  FN_ENTER 1                  ;in every start of a function, the argument is the number of "local" vars
	push ebp                        
	mov ebp, esp
	sub esp, %1*4
	push ebx
	push ecx	
	push edx
%endmacro	

%macro  FN_EXIT 0                   ;in every end of a function
	pop edx
	pop ecx
	pop ebx
	mov esp, ebp	
	pop ebp
	ret
%endmacro	


section .text
	global main
	extern printf
  	extern fprintf 
  	extern fflush
 	 extern malloc 
 	 extern calloc 
 	 extern free 
 	 extern gets 
 	 extern getchar 
 	 extern fgets 
	  extern stdout
	  extern stdin
	  extern stderr

    global push_stack           
	global pop_stack
	global invert_number
	global print_number
	global add_char
	global free_number
	global build_number
	global add_numbers
	global dup_numbers
	global myCalc

;;;;;;;;;;;;;;;;;;;;;;;; print_dbg_num	
%define str dword [ebp+8]           ;A way to give the arguments names for more readable code
%define p_num dword [ebp+12]
print_dbg_num:
	FN_ENTER 0

	cmp dword [g_dbg_flag], 0          ;if debug mode on, jump to print_dbg_num
	je exit_print_dbg_num              ;if not:
	push str                           ;push read_user_str - the first argument of the function
	push dword [stderr]                ;print to stderr
	call fprintf
	add esp, 4                         ;clean the stack
	push p_num                         ;push p_number1- the second argument of the function
	push dword [stderr]                ;print to stderr
	call print_number
	add esp, 4
exit_print_dbg_num:
	FN_EXIT


;;;;;;;;;;;;;;;;;;;;;;;; main	
%define argc dword [ebp+8]          ;A way to give the arguments names for more readable code
%define argv dword [ebp+12]
%define envp dword [ebp+16]
%define cnt dword [ebp-4]
%define eaxStore dword [ebp-8]
%define firstDigit dword [ebp-12]
%define edxStore dword [ebp-16]



main:
	FN_ENTER 4

	mov eaxStore,0
	mov edxStore,0
	mov firstDigit,0




	mov dword [g_dbg_flag], 0  ;initialize the bebug mode
	mov ecx,0
	mov eax, argv              ;get the second argument
loopmain:
	cmp ecx, argc
	je exit_loopmain
	mov edx, [eax+4*ecx]            
	cmp byte [edx], '-'  


	;cmp ecx,1
	;jne resumeDebugModeCheck
	;mov eaxStore,eax
	;mov edxStore,edx
	;mov ebx,0
	;mov bl,byte [edx]
	;sub ebx,'0'     ;val-'0' 
	;mov eax,ebx
	;mov bl,10
	;mul bl
	;mov ebx,0
	;mov bl,byte [edx+1]
	;sub ebx,'0'     ;val-'0' 
	;add eax,ebx
	
	;mov edx,0
	;mov ebx,0
	;mov ebx,8
	;div ebx  ;result in eax (eax/8)
	;mov firstDigit,edx
	;div ebx	;eax/ebx->eax
	;mov eax,firstDigit
	;mov ebx,0
	;mov bl,10
	;mul bl
	;add eax,edx

	;mov dword [MAX_STACK],eax
	;push 1
	;push eax
	;call calloc
	;add esp, 8
	;mov dword [g_stack],eax
	;mov edx,edxStore
	;mov eax,eaxStore
	;resumeDebugModeCheck:


	jne contmain_loop
	cmp byte [edx+1], 'd'      
	jne contmain_loop
	cmp byte [edx+2], 0
	jne contmain_loop
	mov dword [g_dbg_flag], 1        ;changing the flag to 1 if debug
contmain_loop:
	inc ecx
	jmp loopmain
exit_loopmain:	
	call myCalc                    ;call to the function where the calculate is done 
	mov cnt, eax                   ;move the return value of mycalc - number of actions to cnt

	push cnt                       ;push number of actions
	push pr_counter                ;push the print format
	call printf                    ;print 
	add esp, 8                     ;clean the stack

exitmain:
	mov eax, 0
	FN_EXIT

;;;;;;;;;;;;;;;;;;;;;;;; myCalc	
%define p_number1 dword [ebp-4]
%define p_number2 dword [ebp-8]
%define p_number3 dword [ebp-12]
%define count dword [ebp-16]
myCalc:
	FN_ENTER 3

	mov dword [g_stack_ptr], MAX_STACK         ; save max stack size in pointer 
	mov count, 0                               ;counter of action initilaized by 0

loopmyCalc:
	push calc                                  ;to print "calc: "
	call printf
	add esp, 4

	push inp_buf                               ;save keyboard input in inp_buff
	call gets 
	add esp,4

	mov eax, inp_buf                           
	cmp byte [eax+0], 'q'                      ;compare input with q
	jne c1myCalc                               ;if not- jump to c1myCalc
	jmp exitmyCalc                             ;else - jump to exit

c1myCalc:	
	cmp byte [eax+0], 'p'                      ;compare input to  p
	jne c2myCalc                               ;if not- jump to c2myCalc
	inc count                                  ;increment counter of actions 
	mov eax, [g_stack_ptr]                   ;to check if there is at least 1 argument in stack
	add eax, 1
	cmp eax, MAX_STACK
	jg c1myCalc_err                           ;if don't - print error
	call pop_stack                            ;pop the number from the stack (pop_stack is auxillary func)
	mov p_number1, eax                        ;move the number to number1
	push p_number1                            ;push number1
	push dword [stdout]                       ;to stdout
	call print_number                         ;print
	add esp, 4                                ;clean the stack
	push p_number1                            ;push number1
	call free_number                          ;free the number
	add esp, 4                                ;clean the stack
	jmp loopmyCalc                            ;go back to loopmyCalc for another number
	
c1myCalc_err:
	push err_un                               ;push error
	call printf                               ;print  
	add esp,4                                 ;clean the stack
	jmp loopmyCalc                            ;go back to loopmyCalc for another number

c2myCalc:
	cmp byte [eax+0], '+'                     ;compare input with +
	jne c3myCalc                              ;if not- jump to c3myCalc
	inc count                                 ;increment counter of actions 
	mov eax, [g_stack_ptr]                   ;to check if there is at least 2 argument in stack (3 free cells)
	add eax, 2
	cmp eax, MAX_STACK
	jg c2myCalc_err                           ;if not- jump to print error
	call pop_stack                            ;pop the first number from the stack
	mov p_number1, eax                        ;move the number to number1 
	call pop_stack                            ;pop the second number from the stack
	mov p_number2, eax                        ;move the number to number2
	push p_number2 
	push p_number1
	call add_numbers                          
	add esp, 8                                 ;clean the stack
	mov p_number3, eax                         ;save the result in number3
	push p_number3                             ;push number3
	call push_stack                            ;call the function push_stack
	add esp, 4                                 ;clean the stack
	push p_number1                             ;to free number1
	call free_number   
	add esp, 4
	push p_number2                             ;to free number2
	call free_number
	add esp, 4
	jmp loopmyCalc                             ;go back to loopmyCalc for another number
c2myCalc_err:
	push err_un                                ;to print error
	call printf
	add esp,4
	jmp loopmyCalc                             ;go back to loopmyCalc for another number

c3myCalc:
	cmp byte [eax+0], '&'                     ;compare input with &
	jne c4myCalc                              ;if not- jump to c4myCalc
	inc count                                 ;increment counter of actions 
	mov eax, [g_stack_ptr]                   ;to check if there is at least 2 argument in stack
	add eax, 2
	cmp eax, MAX_STACK
	jg c3myCalc_err                           ;if not- jump to print error
	call pop_stack                            ;pop the first number from the stack
	mov p_number1, eax                        ;move the number to number1 
	call pop_stack                            ;pop the second number from the stack
	mov p_number2, eax                        ;move the number to number2
	push p_number2 
	push p_number1
	call bitANDsecondVersion                          
	add esp, 8                                 ;clean the stack
	mov p_number3, eax                         ;save the result in number3
	push p_number3                             ;push number3
	call push_stack                            ;call the function push_stack
	add esp, 4                                 ;clean the stack
	push p_number1                             ;to free number1
	call free_number   
	add esp, 4
	push p_number2                             ;to free number2
	call free_number
	add esp, 4
	jmp loopmyCalc                             ;go back to loopmyCalc for another number
c3myCalc_err:
	push err_un                                ;to print error
	call printf
	add esp,4
	jmp loopmyCalc     


c4myCalc:											
	cmp byte [eax+0], 'n'                      ;compare input to  n
	jne c5myCalc                               ;if not- jump to c5myCalc
	inc count                                  ;increment counter of actions 
	mov eax, [g_stack_ptr]                   ;to check if there is at least 1 argument in stack
	add eax, 1
	cmp eax, MAX_STACK
	jg c4myCalc_err                           ;if don't - print error
	call pop_stack                            ;pop the number from the stack (pop_stack is auxillary func)
	mov p_number1, eax                        ;move the number to number1
	push p_number1                          ;push number1
	call number_of_bytes
	add esp, 4                                 ;clean stack
	mov p_number2, eax 
	push p_number2                             
	call push_stack
	add esp, 4
	jmp loopmyCalc   
c4myCalc_err:
	push err_un                               ;push error
	call printf                               ;print  
	add esp,4                                 ;clean the stack
	jmp loopmyCalc                            ;go back to loopmyCalc for another number

    
c5myCalc:
	cmp byte [eax+0], 'd'                      ;compare input with d
	jne c7myCalc                               ;if not- jump to c7myCalc
	inc count                                  ;increment counter of actions
	mov eax, [g_stack_ptr]              ;to check if there is at least 1 argument in stack 
	add eax, 1
	cmp eax, MAX_STACK
	jg c5myCalc_err
	call pop_stack
	mov p_number1, eax                         ;take number from the top of the array
	push p_number1
	call dup_numbers                           ;duplicate the number
	add esp, 4                                 ;clean stack
	mov p_number2, eax 
	push p_number1
	call push_stack                            ;push the duplicated number into the stack
	add esp, 4                                 ;clean stack
	push p_number2                             
	call push_stack
	add esp, 4
	jmp loopmyCalc                             ;go back to loopmyCalc for another number
c5myCalc_err:
	push err_un                                ;print error
	call printf
	add esp,4
	jmp loopmyCalc	

c7myCalc:
	push inp_buf                        ;call to build number in order to build the linked list
	call build_number					;makes linked list for the number of the input with calloc
	add esp, 4	
	mov p_number1, eax                  ;move result to number1
	push p_number1
	push read_user_str
	call print_dbg_num					;for debug mode
	add esp, 8	
	push p_number1                     ;push the number(list) into the array
	call push_stack
	add esp, 4


	jmp loopmyCalc                     ;go back to loopmyCalc for another number

exitmyCalc:
	mov eax, count                     ;move the counter to eax- the result of function
	FN_EXIT

;;;;;;;;;;;;;;;;;;;;;;;; dup_numbers	
%define inp1 dword [ebp+8] 
dup_numbers:
	FN_ENTER 0        
	push 0
	push inp1
	call add_numbers ;add 0 with our number
	add esp,8
	FN_EXIT



;;;;;;;;;;;;;;;;;;;;;;;; bitANDsecondVersion	
%define inp1 dword [ebp+8]   ;input arguments 
%define inp2 dword [ebp+12]  ;input arguments 
%define p_root dword [ebp-4]
%define p_curr dword [ebp-8]
%define v1 byte [ebp-12]
%define v2 byte [ebp-16]
%define v3 dword [ebp-20]
bitANDsecondVersion:
	FN_ENTER 5             ;5 is the number of local variables

	mov p_root,0           ;initialize p_root to 0 
	mov p_curr,0           ;initialize p_curr to 0 

loopadd_numbersB:	
	cmp inp1,0             
	jne cont_loopadd_numbersB  ;while inp1 not 0 - jump to cont_loopadd_numbers
	cmp inp2,0
	jne cont_loopadd_numbersB  ;while inp2 not 0 - jump to cont_loopadd_numbers
	jmp exitadd_numbersB
cont_loopadd_numbersB:
	mov v1,0               ;initialize v1 to 0 
	mov v2,0               ;initialize v2 to 0 

	cmp inp1,0	           ;compare inp1 with 0
	je ex_inp1B             ;if inp1 0 - jump to ex_inp1
	mov eax, inp1          ;move inp1 to eax 
	movzx edx, byte [eax]  ;move eax with 0 extend to edx 
	mov v1, dl            ;move edx to v1
	mov eax, [eax+1]       ;move 
	mov inp1, eax
ex_inp1B:	

	cmp inp2,0	
	je ex_inp2B
	mov eax, inp2
	movzx edx, byte [eax]
	mov v2, dl
	mov eax, [eax+1]
	mov inp2, eax
ex_inp2B:
	
	mov bl,v1
	mov al,v2
	and al,bl

	;movzx edx,al
	;push edx
	;push pr_string
	;call printf
	;add esp, 8
	
	mov v3, eax
	push 1
	push 5
	call calloc
	add esp, 8
	mov edx, v3
	mov byte [eax], dl
	mov ebx, p_root
	cmp ebx, 0
	jne p_root_neB
	mov p_root,eax
	jmp p_root_contB
p_root_neB:	
	mov edx, p_curr
	mov [edx+1], eax
p_root_contB:
	mov p_curr, eax
	jmp loopadd_numbersB


exitadd_numbersB:	
	mov eax, p_root
	FN_EXIT

;;;;;;;;;;;;;;;;;;;;;;;; number_of_bytes	
%define inp1 dword [ebp+8]   ;input arguments 
%define bytesCounter dword [ebp-4]
%define NOB_flag dword [ebp-8]
%define MSB dword [ebp-12]
number_of_bytes:
	FN_ENTER 3
	mov MSB,0
	
	 ;runs over the linked list and counts the number of links (each link for octal digit)
	mov bytesCounter,1
	mov NOB_flag, 0
	mov	eax, inp1
number_of_bytes_Loop:
	cmp eax,0
	je exit_number_of_bytes
	mov MSB,eax
	mov eax, [eax+1]
	cmp NOB_flag,0
	je line696
	inc bytesCounter
line696:
	mov NOB_flag,1
	jmp number_of_bytes_Loop

exit_number_of_bytes:
	
	push 1
	push 5
	call calloc
	add esp, 8

	mov inp1,eax

	before_exiting:

	mov eax,bytesCounter
	mov ebx,3
	mul ebx  ;result in eax

	mov ebx,MSB
	cmp byte [ebx],3
	je threeOrTwo_LeadingZeros
	cmp byte [ebx],2
	je threeOrTwo_LeadingZeros
	cmp byte [ebx],1
	jne no_leadingZeros
	sub eax,1

	threeOrTwo_LeadingZeros:
	sub eax,1

	no_leadingZeros:
	mov ebx,0
	mov ebx, 8
	div ebx	;eax/ebx->eax
	mov bytesCounter,eax
	cmp edx,0
	je noINC
	inc bytesCounter
	
	
	noINC:
	mov edx, bytesCounter
	mov eax,inp1
	mov byte [eax], dl
	mov dword [eax+1],0
	FN_EXIT
	

;;;;;;;;;;;;;;;;;;;;;;;; add_numbers	
%define inp1 dword [ebp+8]   ;input arguments 
%define inp2 dword [ebp+12]  ;input arguments 
%define p_root dword [ebp-4]
%define p_curr dword [ebp-8]
%define v1 dword [ebp-12]
%define v2 dword [ebp-16]
%define v3 dword [ebp-20]
%define carry dword [ebp-24]
add_numbers:
	FN_ENTER 6             ;6 is the number of local variables

	mov p_root,0           ;initialize p_root to 0 
	mov p_curr,0           ;initialize p_curr to 0 
	mov carry,0            ;initialize carry to 0 

loopadd_numbers:	
	cmp inp1,0             
	jne cont_loopadd_numbers  ;while inp1 not 0 - jump to cont_loopadd_numbers
	cmp inp2,0
	jne cont_loopadd_numbers  ;while inp2 not 0 - jump to cont_loopadd_numbers
	jmp exitadd_numbers
cont_loopadd_numbers:
	mov v1,0               ;initialize v1 to 0 
	mov v2,0               ;initialize v2 to 0 

	cmp inp1,0	           ;compare inp1 with 0
	je ex_inp1             ;if inp1 0 - jump to ex_inp1
	mov eax, inp1          ;move inp1 to eax 
	movzx edx, byte [eax]  ;move eax with 0 extend to edx 
	mov v1, edx            ;move edx to v1
	mov eax, [eax+1]       ;move 
	mov inp1, eax
ex_inp1:	

	cmp inp2,0	
	je ex_inp2
	mov eax, inp2
	movzx edx, byte [eax]
	mov v2, edx
	mov eax, [eax+1]
	mov inp2, eax
ex_inp2:
	mov eax, carry
	add eax, v1
	add eax, v2
	mov carry, 0

	cmp eax, 8
	jl	cont_ch1 
	sub eax, 8
	mov carry, 1	
cont_ch1:
	mov v3, eax
	push 1
	push 5
	call calloc
	add esp, 8
	mov edx, v3
	mov byte [eax], dl
	mov ebx, p_root
	cmp ebx, 0
	jne p_root_ne
	mov p_root,eax
	jmp p_root_cont
p_root_ne:	
	mov edx, p_curr
	mov [edx+1], eax
p_root_cont:
	mov p_curr, eax
	jmp loopadd_numbers


exitadd_numbers:	

	cmp carry,0
	je exitadd_numbers_ret
	push 1
	push 5
	call calloc
	add esp, 8
	mov edx, carry
	mov byte [eax], dl
	mov edx, p_curr
	mov [edx+1], eax

exitadd_numbers_ret:
	mov eax, p_root
	FN_EXIT


;;;;;;;;;;;;;;;;;;;;;;;; build_num	
%define inp dword [ebp+8]    ;the number we recieve from input
%define root dword [ebp-4]   ;local variable1 - char *root 
%define c_elem dword [ebp-8] ;local variable2 - char *c_elem
build_number:
	FN_ENTER 2             ;2 is the number of local variables
	mov root, 0            ;initialize root to 0 

loop_1:	
	mov eax, inp           ;inp is the number we want to build
	cmp byte [eax],'0'     ;as long we have 0, increase the pointer
	jne exit_loop_1        
    	inc inp                ;increment the poiner 
    	jmp loop_1             ;conrinue the loop
exit_loop_1:	
    
loop_2:	
    mov eax, inp                ;save the number without 0 in eax
	movzx ebx, byte [eax]   ;move to a string the number
    push ebx                ;push first letter into the stack in order to call add_char      
    call add_char
	add esp,4               ;clean the stack
    cmp eax, 0              ;compare answer with 0,checks if it is null byte
    jz exit_loop_2          ;if equal - exit 
	mov ebx, root           ;we want to update the returned link into the list
							;building the link list of the number digits 
	mov [eax+1],ebx         ;increase the pointer eax+1
	mov root,eax            ;move eax to next letter
    inc inp                 ;increment inp by 1
	jmp loop_2
exit_loop_2:   

	mov eax, root          ;move into root the number
	cmp eax, 0             ;compare number with 0
	jne exit_build_num     ;if not equal exit
	push '0'               ;push 0
	call add_char          ;call  function add_char to add 0
	add esp,4              ;clean the stack

exit_build_num:	
	FN_EXIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;build_num	


;;;;;;;;;;;;;;;;;;;;;;;; free_number
;every time we remove another link and save the pointer to the rest of the list	

%define ptr dword [ebp+8]      ;the number we want to free
%define n_ptr dword [ebp-4]    ;local variable
free_number:
	FN_ENTER 1            ;1 means we have 1 local variable

loopfree:
	cmp ptr, 0             ;compare the number with 0  
	je exitfree            ;if equal- exit
	mov eax, ptr           ;move the number to eax
	mov edx, [eax+1]       ;move eax+1 to edx(not to lose the list)
	mov n_ptr, edx         ;move edx to n_ptr
	push ptr               
	call free              ;free the link
	add esp,4              ;clean the stack
	mov eax, n_ptr         ;move n_ptr to eax
	mov ptr,eax            ;move eax to ptr
	jmp loopfree

exitfree:		
	FN_EXIT

;;;;;;;;;;;;;;;;;;;;add_char
%define val dword [ebp+8]   ;the value we want to put in the link 
add_char:
	FN_ENTER 0
	
    push 5                  ; (5 bytes in this case: 4 bytes for the pointer, one byte for the data)
    push 1
    call calloc         ;assign place in memory
    add esp, 8          ;clean the stack
     

    mov ebx, val	    ;pointer to the letter
    
    cmp  ebx, '0'       ;check  the letter - lower than 0
    jl no_0_7           ;not good letter
    cmp  ebx, '7'       ;check the letter - bigger than 9
	jg no_0_7       ;alse not good letter
case_0_7:
	sub ebx,'0'     ;val-'0' 
	mov byte [eax], bl   ;save the link we want to return to build_num
	jmp exitadd_char
no_0_7:
	push eax
    call free   ;free the link in case of error
    add esp,4
	mov eax, 0

exitadd_char:			
	FN_EXIT

;;;;;;;;;;;;;;;;;;;;print_number
%define io dword [ebp+8]  
%define inp dword [ebp+12]
%define n_ptr dword [ebp-4]  ;local variable1
%define orig_n_ptr dword [ebp-8]  ;local variable2
print_number:
	FN_ENTER 2

    push inp                   ;push what we want to print          
    call invert_number         ;it reverse the number
    add esp, 4

	mov n_ptr, eax             ;move the result to n_ptr
	mov orig_n_ptr, eax        ;move the result to orig_n_ptr (to be able to free)

	; skip leading zeros
	mov eax, n_ptr             ;move n_ptr to eax
loop_0_print:	
	cmp eax, 0                 ;compare eax with 0
	je loop_0_print_exit       ;if equl jump to loop_0_print_exit
	movzx edx, byte [eax]      ;move byte from eax and extend 0 to edx 
	cmp edx, 0                 ;compare eax with 0
	jne loop_0_print_exit      ;if not equl jump to loop_0_print_exit
	mov eax, [eax+1]           ;move eax+1 to eax
	jmp loop_0_print
loop_0_print_exit:
	mov n_ptr, eax             ;move eax to n_ptr
	cmp eax, 0                 ;compare eax with 0
	jne loop_print             ;if not equal jump to loop_print
	push 0                     ;push 0
	push pr_counter               ;push the print format
	push io                    ;push where we want to print to
	call fprintf           
	add esp, 8
	jmp print_exit	
    
loop_print:
    cmp eax, 0                 ;compare eax with 0  
    je go_out_of_loop          ;if equal jump to go_out_of_loop
    
	movzx edx, byte [eax]      ;move byte from eax and extend 0 to edx
	push edx                   ;push what we want to print
	push pr_string             ;push the format print
	push io                    ;push where we want to print to 
	call fprintf
	add esp, 8
	mov eax, n_ptr             ;move n_ptr to eax
	mov eax, dword [eax+1]     ;move eax+1 to eax
	mov n_ptr,eax              ;move eax to n_ptr
	jmp loop_print
	
go_out_of_loop:
    push line                 ;push what we want to print
	push io                   ;push where we want to print to 
	call fprintf
    add esp, 4

print_exit:
	push orig_n_ptr           ;to free orig_n_ptr
    call free_number
    add esp,4
        
	FN_EXIT
	
;;;;;;;;;;;;;;;;;;;; invert_number
%define inp dword [ebp+8]   ;the number we want to reverse
%define p_curr dword [ebp-4]
%define p_root dword [ebp-8]
invert_number:
	FN_ENTER 2

	mov p_root, 0              ;initialize p_root by 0
	mov ebx, inp	           ;move the number to ebx
	mov p_curr, ebx            ;move ebx to p_curr

loopinvert_number:	
	cmp p_curr ,0              ;compare curr pointer with 0 
	je exit_loopinvert_number  ;if equal jump to exit_loopinvert_number
	push 5                     
	push 1
	call calloc                ;to assign place in memory
	
	mov ebx, p_curr            ;move p_curr to ebx
	mov dl, byte [ebx]         ;move to dl the first letter(p_curr[0])
	mov byte [eax],dl          ;move the first letter to eax 
	mov edx, p_root            ;move p_root to edx (the pointer we save before)
	mov [eax+1], edx           ;move edx to eax+1
	mov p_root, eax            ;move eax to p_root

	mov edx,[ebx+1]            ;move ebx+1 to edx
	mov p_curr, edx            ;move edx to the current pointer
	jmp loopinvert_number      

exit_loopinvert_number:        
	mov eax,  p_root
	FN_EXIT
	
;;;;;;;;;;;;;;;;;;;; pop_stack
pop_stack:
	FN_ENTER 0 ;0 local variables

	cmp dword [g_stack_ptr], MAX_STACK     ;check if we used the max of stack
	je ret_0pop_stack

	mov eax, [g_stack_ptr]                 ;move the top of the stack to eax
	mov eax, [g_stack+4*eax]               
	inc dword [g_stack_ptr]               ;increase the poiner by 1 
	push eax ; save
	push eax
	push pop_stack_str   ;to print
	call print_dbg_num
	add esp, 8
	pop eax
	jmp exitpop_stack

ret_0pop_stack:
	mov eax, 0

exitpop_stack:	
	FN_EXIT


;;;;;;;;;;;;;;;;;;;; push_stack
%define ptr dword [ebp+8]  ;the number we want to push into the stack
push_stack:
	FN_ENTER 0  ;0 local variables

	cmp dword [g_stack_ptr], 0  ;check if we reached the end of the stack
	je ret_m_1

	dec dword [g_stack_ptr] ;if not, decrease the size 
	mov eax, [g_stack_ptr]
	mov ecx, ptr	    ; get function argument ptr
	mov [g_stack+4*eax],ecx  ;push to the stack

	push ptr
	push push_stack_str
	call print_dbg_num ;print message
	add esp, 8
 
	mov eax, 0
	jmp exitpush_stack

ret_m_1:
	push err_ov  ;print error message
	call printf
	add esp, 4
	push ptr
    call free_number ;free the pointer
    add esp,4

	mov eax, -1

exitpush_stack:	
	FN_EXIT

