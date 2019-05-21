	.data

prmptf1: .asciz	"Enter input file name: "
prmptf2: .asciz	"Enter output file name (note: file must be empty to ensure proper function): "
prmptsd: .asciz	"Enter hash seed: "
prmptop: .asciz	"Get checksum (c) or check integrity (i)? "
	.align	2
seed:	.word	0
testoutput: .word 0
op:	.byte	0
	.align	2
signature: .word 0
ferror: .asciz	"File does not exist. "
oerror:	.asciz	"You did not enter 'c' or 'i'.\n"
eerror:	.asciz	"The file is empty. \n"
	.align	2
getcheck: .word	1
s:	.asciz	"%s"
d:	.asciz	"%d"
c:	.asciz	"%c"
verified: .asciz "The file is safe. \n"
unverified: .asciz "The file has been modified and may be unsafe. \n"
	.align	2

	.text
	.globl	main
main:	stmfd	sp!, {r4-r11, lr}

getin:	ldr	r0, =prmptf1
	bl	printf

	mov	r0, #32
	bl	malloc
	mov	r4, r0			@ store pointer to filename in r4

	ldr	r0, =s
	mov	r1, r4			@ scan to filename
	bl	scanf

	mov	r0, r4			@ open this file
	mov	r1, #0
	bl	open			@ attempt to open file in read-only mode

	cmp	r0, #0			@ if file descriptor is less or equal to 0, ask again
	ble	error1
	b	nextthing
error1:
	ldr	r0, =ferror
	bl	printf
	b	getin

error2:
	ldr	r0, =ferror
	bl	printf
	b	getout

nextthing:
	mov	r5, r0			@ store file descriptor in r5 permanently

getseed:
	ldr	r0, =prmptsd
	bl	printf

	ldr	r0, =d
	ldr	r1, =seed
	bl	scanf			@ get hash seed

getop:
	ldr	r0, = prmptop		@ ask checksum or verify?
	bl	printf

	ldr	r0, =c
	ldr	r1, =op
	bl	scanf			@ checksum or verify integrity?

	ldr	r0, =c
	ldr	r1, =op
	bl	scanf			@ doing it twice to move cursor

	ldr	r0, =op
	ldr	r0, [r0]		@ get value of op

	cmp	r0, #'i'
	beq	verify

	cmp	r0, #'c'
	beq	checksum

	ldr	r0, =oerror
	bl	printf
	b	getop

getout:	ldr	r0, =prmptf2
	bl	printf

	mov	r0, #32
	bl	malloc
	mov	r10, r0			@ store pointer to output filename in r10

	ldr	r0, =s
	mov	r1, r10			@ scan to output filename
	bl	scanf

	mov	r0, r10
	mov	r1, #1			@ 1 =  write only
	bl	open

	cmp	r0, #0
	ble	error2			@ if the file descriptor is negative, display error
					@ and ask again

	mov	r1, r6			@ r0 has file descriptor, r6 has the contents
	mov	r2, r7
	add	r2, r2, #4		@ number of bytes to write
	bl	write
	b	end

verify:
	mov 	r0, #256		@ allocate memory for the file contents
	bl	malloc

	mov	r6, r0			@ permanent pointer to file in r6

	mov	r0, r5			@ file descriptor
	mov	r1, r6			@ read to r6
	mov	r2, #256		@ read 256 bytes
	bl	read
	mov	r7, r0			@ r7 stores number of bytes read

	cmp	r7, #0
	beq	fileempty		@ if the file is empty, display message and end

	mov	r0, r5			@ file descriptor
	bl	close			@ close the input file

	ldr	r0, =getcheck
	ldr	r0, [r0]
	cmp	r0, #1
	bleq	gethashfromfile		@ if getcheck is true, gethashfromfile

	mov	r0, #0			@ r0 will be adding up hash
	mov	r1, #0			@ r1 will hold offset
	mov	r3, r7
	sub	r3, r3, #1
readfile:
	ldrh	r2, [r6, r1]		@ get the halfword
	add	r0, r0, r2
	add	r1, r1, #2		@ add 2 to r1 to get to next halfword
	cmp	r1, r3			@ is r1 bigger than r7 yet?
	bgt	endread
	beq	special
	b	readfile
special:				@ special case of odd number of characters
	ldrb	r2, [r6, r1]
	add	r0, r0, r2		@ just add single character
endread:
@@@@@@@ now you have the hash in r0, and if checking, the signature in r9
@@@@ figure out what to do with the hash
	ldr	r1, =getcheck
	ldr	r1, [r1]
	cmp	r1, #0
	beq	appendhash		@ if getting hash, append it
					@ otherwise, check if it is equal to signature
	add	r0, r0, r9		@ add hash
	ldr	r1, =seed
	ldr	r1, [r1]
	add	r0, r0, r1		@ add seed for final hash
	cmp	r0, #0
	bne	modified		@ if it doesn't add up to 0, file is modified
	ldr	r0, =verified
	bl	printf
	b	end

appendhash:
	mov	r1, #0
	sub	r0, r1, r0		@ r0 now holds the negative of the hash
	ldr	r1, =seed
	ldr	r1, [r1]		@ r1 has the seed
	sub	r0, r0, r1		@ subtracting seed from hash to get final hash
	mov	r1, r6			@ start of file in r1
	add	r1, r1, r7		@ get to end of file
	str	r0, [r1]		@ add the hash

	b	getout

modified:
	ldr	r0, =unverified
	bl	printf
	b	end

checksum:
	ldr	r0, =getcheck
	mov	r1, #0
	str	r1, [r0]		@ getcheck = false
	b	verify

gethashfromfile:
	sub	r7, r7, #4		@ move r7 1 word back before the hash
	ldr	r9, [r6, r7]		@ load the hash into r9
	mov	pc, lr

fileempty:
	ldr	r0, =eerror		@ load empty error message
	bl	printf			@ print and continue to end

end:	mov	r0, r4
	bl	free
	mov	r0, r6
	bl	free
	ldr	r0, =getcheck
	ldr	r0, [r0]
	cmp	r0, #1
	movne	r0, r10
	blne	free
realend:
	ldmfd	sp!, {r4-r11, lr}
	mov	pc, lr

.end
