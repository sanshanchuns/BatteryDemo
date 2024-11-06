.text
.text
.align 4
.globl _freqTest

_freqTest:

freqTest_LOOP:

// loop 1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1

// loop 2
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1

// loop 3
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1

// loop 4
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1

// loop 5
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1

// loop 6
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1

// loop 7
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1

// loop 8
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1

// loop 9
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1

// loop 10
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1
add     x1, x1, x1

subs    x0, x0, #1
bne     freqTest_LOOP

RET
