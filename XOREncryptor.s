	.data
	.set	keymax, 128
	.set	keymin, 0
p1:	.asciz 	"Encrypt (e) or Decrypt (d)?\n"
	.align	2
e1:	.asciz	"You did not enter e or d\n"
	.align
p2:	.asciz	"Enter input file name: \n"
	.align	2
p3:	.asciz	"Enter output file name: \n"
	.align	2
e2:	.asciz	"Error: input file does not exist in directory\n"
	.align	2
p4:	.asciz	"Enter encryption key (range 1 - 127):\n" 
	.align	2
e3:	.asciz	"Error: key out of range\n"
	.align	2
e4:	.asciz	"Error: output file does not exist in directory\n"
	.align	2
d1:	.asciz	"Encryption complete: "
	.align	2
d2:	.asciz	"Decryption complete: "
	.align	2
newln:	.asciz	"\n"
	.align	2
n:	.byte	0
key:	.byte	0
	.align	2
m:	.word	0
scans:	.asciz	"%s"
	.align	2
scand:	.asciz	"%d"
	.align	2

	.text
	.global main
main:	stmfd	sp!, {r4-r10,lr}
	ldr	r1, =p1		@ p1 is prompt for e or d
	mov 	r0, #1		@ 1 = stdout
	mov	r2, #29		@ length of p1
	mov	r7, #4		@ 4 = write
	svc	0		@ System call to print p1
	mov	r0, #0		@ stdin
	ldr	r1, =n		@ where to read to
	mov	r2, #1		@ number of characters to read
	mov	r7, #3		@ 3 = read
	svc	0		@ system call to read one character to n

	ldr	r0, =n
	ldrb	r0, [r0]	@ r0 has the entered character
	mov	r4, r0		@ also hold in r4
	cmp	r0, #'e'	@ is it e?
	cmpne	r0, #'d'	@ if not, is it d?
	ldrne	r0, =scans
	ldrne	r1, =e1
	blne	printf		@ if not, print error
	cmp	r4, #'e'
	cmpne	r4, #'d'
	bne	end		@ and end

	mov	r0, #256
	bl	malloc		@ allocate 256 bytes of memory
	mov	r8, r0		@ permanently store pointer in r8

	b	encrypt

done:
	ldr	r0, =n
	ldrb	r0, [r0]	@ load a byte from =n
	cmp	r0, #'e'	@ did they input e?
	beq	donee

	b	doned		@ otherwise d

end:	ldmfd	sp!, {r4-r10,lr}
	mov	pc, lr

encrypt:
	bl	filename
	mov	r0, r9		@ input filename
	mov	r1, #0
	bl	open		@ open input file in read-only mode

	cmp	r0, #0
	ldrle	r0, =scans
	ldrle	r1, =e2
	blle	printf
	ble	encrypt		@ if the file descriptor is nonpositive,
				@ the file doesn't exist. Thus, it branches
				@ back to the start of the encrypt
				@ segment so that they can enter the file
				@ names again

	mov	r4, r0		@ store file descriptor in r4
	mov	r1, r8		@ heap
	mov	r2, #256
	bl	read		@ read 256 bytes to heap
	mov	r5, r0		@ r5 has number of bytes read?

	mov	r0, r4		@ prep file descriptor
	bl	close		@ close file

	mov	r0, r10
	mov	r1, #1		@ open output file in write-only mode
	bl	open

	cmp	r0, #0
	ldrle	r0, =scans
	ldrle	r1, =e4
	blle	printf
	ble	encrypt		@ same file existence check as above

	mov	r4, r0		@ store file descriptor in r4

	mov	r0, r8		@ r0 points to heap
	ldr	r1, =key
	ldrb	r1, [r1]	@ r1 has key
	add	r2, r8, r5	@ r2 has the address at the end of the text

eloop:
	ldrb	r3, [r0]

	eor	r3, r3, r1

	strb	r3, [r0], #1
				@ xor the first word of r0, then add 4 to r0
	cmp	r0, r2		@ is r0 at the end?
	blt	eloop

	mov	r0, r4		@ file descriptor
	mov	r1, r8		@ heap
	mov	r2, r5		@ write however many bytes were read initially
	bl	write

	mov	r0, r4
	bl	close

	b	done

donee:	ldr	r0, =scans
	ldr	r1, =d1
	bl	printf
	ldr	r0, =scans
	mov	r1, r8
	bl	printf
	ldr	r0, =scans
	ldr	r1, =newln
	bl	printf
	b	freespace

doned:	ldr	r0, =scans
	ldr	r1, =d2
	bl	printf
	ldr	r0, =scans
	mov	r1, r8
	bl	printf
	ldr	r0, =scans
	ldr	r1, =newln
	bl	printf
	b	freespace

freespace:
	mov	r0, r8
	bl	free
	mov	r0, r9
	bl	free
	mov	r0, r10
	bl	free
	b	end

filename:
	stmfd	sp!, {lr}	@ preserve lr
	mov	r0, #32
	bl	malloc		@ 32 bytes for input file name
	mov	r9, r0		@ permanently store file name pointer in r9
	ldr	r0, =scans
	ldr	r1, =p2
	bl	printf		@ ask for input file

@	mov	r0, #0
@	mov	r1, r9
@	mov	r2, #32
@	mov	r7, #3
@	svc	0
@@ I don't know why this system call doesn't work

	ldr	r0, =scans
	mov	r1, r9
	bl	scanf		@ get output file

	mov	r0, #32
	bl	malloc
	mov	r10, r0		@ perma pointer to output name in r10
	ldr	r0, =scans
	ldr	r1, =p3
	bl	printf		@ ask for output file

	ldr	r0, =scans
	mov	r1, r10
	bl	scanf		@ get output file

keyget:	ldr	r0, =scans
	ldr	r1, =p4
	bl	printf		@ ask for key

	ldr	r0, =scand
	ldr	r1, =key
	bl	scanf		@ get the key

	ldr	r2, =key
	ldr	r2, [r2]
	cmp	r2, #keymax	@ compare key to keymax
	ldrge	r0, =scans
	ldrge	r1, =e3
	blge	printf		@ print error message if entered number
				@ is greater than 127
	ldr	r2, =key
	ldr	r2, [r2]
	cmp	r2, #keymax	@ ask again
	bge	keyget

	ldr	r2, =key
	ldr	r2, [r2]
	cmp	r2, #keymin	@ compare key to min
	ldrle	r0, =scans
	ldrle	r1, =e3
	blle	printf		@ print error message if entered number
				@ is less than 1
	ldr	r2, =key
	ldr	r2, [r2]
	cmp	r2, #keymin	@ ask again
	ble	keyget

	ldmfd	sp!, {lr}
	mov	pc, lr		@ return

	.end

