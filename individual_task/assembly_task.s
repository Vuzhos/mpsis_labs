# var 7
data:
	li x10, 6
	li x11, 3
	li x12, 33

loop_start:
	beq x12, x0, loop_end
	addi x12, x12, -1
	add x10, x10, x11
	jal x0, loop_start

loop_end:
