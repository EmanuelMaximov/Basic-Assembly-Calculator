# Basic Assembly Calculator

## Description

Basic calculator, for unlimited-precision unsigned integers (supported by dynamic memory allocation), that is written entirely in 32-bit x86 Assembly language.

## Input

The input is in "Reverse Polish notation" or "RPN" (every operator follows all its operands - for example "3 + 4" would be presented as "3 4 +").
For simplicity, each operator appears on a separate line of input.
Input operands are in *octal* representation.

### Example

The program prompts ‘calc: ‘ and waits for input.


Each number or operator is entered in a separate line.

To do the calculation “0q172 + 0q11” a user should type:

```
calc: 172
calc: 11
calc: +
```

## Output
The output result of the calculation is in *octal* representation.

## Supported Operations

- ‘q’ – quit
- ‘+’ – unsigned addition -> pops two operands from operand stack, and pushes the result, their sum
- ‘p’ – pop-and-print -> pops one operand from the operand stack, and prints its value to stdout
- ‘d’ – duplicate -> pushes a copy of the top of the operand stack onto the top of the operand stack
- ‘&’ - bitwise AND -> pops two operands from the operand stack, and pushes the result
- ‘n’ – number of bytes the number is taking -> pops one operand from the operand stack, and pushes one result


## Run Example
```
 ./calc         ; runs ELF file
calc: 11        ; user enters a number
calc: 1         ; user enters a number
calc: +         ; user enters “addition” operator
                ; Oq11+0q1 = 0q12
                ; Oq11 and 0q1 are popped, 0q12 is pushed
calc: d         ; user enters “duplicate” operator, 0q12 is duplicated
calc: p         ; user enters pop-and-print-operator, 0q12 is popped and printed
12
calc: +         ; user enters “addition” operator, but there is not enough numbers in stack
Error: Insufficient Number of Arguments on Stack
calc: 564       ; user inputs a number
calc: n         ; user enters "number of bytes” operator
                ; Oq564 is popped and is used as an argument
                ; Oq564 (=0x174) has 2 bytes, so the number 2 is pushed
calc: d         ; user enters “duplicate” operator, Oq2 is duplicated
calc: p         ; user enters pop-and-print-operator, Oq2 is popped and printed
2
calc: &         ; user enters "X bitwise AND Y" operation
                ; X=0q2, Y=0q12, X&Y=0q2
                ; 0q2 and Oq12 are popped, 0q2 is pushed
calc: p         ; user enters pop-and-print-operator, Oq2 is popped and printed
2
calc: q         ; quit calculator
```

## Notes

- I implemented a separate operand stack of size 5 by default (I did not use the 80X86 machine stack (with the ESP stack pointer) as an operand stack)
- In order to support unlimited precision numbers, each operand in the operand stack is stored as a linked list of bytes


