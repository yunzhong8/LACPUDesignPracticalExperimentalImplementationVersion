	.file	"test.c"
	.text
	.section	.rodata
	.align	2
.LC0:
	.ascii	"finush\000"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
.LFB0 = .
	addi.w	$r3,$r3,-2032
.LCFI0 = .
	st.w	$r1,$r3,2028
	st.w	$r22,$r3,2024
.LCFI1 = .
	addi.w	$r22,$r3,2032
.LCFI2 = .
	lu12i.w	$r13,-69632>>12			# 0xfffffffffffef000
	ori	$r13,$r13,4032
	add.w	$r3,$r3,$r13
	addi.w	$r12,$r0,128			# 0x80
	st.w	$r12,$r22,-28
	st.w	$r0,$r22,-20
	st.w	$r0,$r22,-20
	b	.L2
.L5:
	st.w	$r0,$r22,-24
	b	.L3
.L4:
	ld.w	$r13,$r22,-20
	ld.w	$r12,$r22,-24
	mul.w	$r13,$r13,$r12
	lu12i.w	$r12,-69632>>12			# 0xfffffffffffef000
	addi.w	$r14,$r22,-16
	add.w	$r15,$r14,$r12
	ld.w	$r14,$r22,-20
	addi.w	$r12,$r0,130			# 0x82
	mul.w	$r14,$r14,$r12
	ld.w	$r12,$r22,-24
	add.w	$r12,$r14,$r12
	slli.w	$r12,$r12,2
	add.w	$r12,$r15,$r12
	st.w	$r13,$r12,2020
	ld.w	$r12,$r22,-24
	addi.w	$r12,$r12,1
	st.w	$r12,$r22,-24
.L3:
	ld.w	$r13,$r22,-24
	ld.w	$r12,$r22,-28
	blt	$r13,$r12,.L4
	ld.w	$r12,$r22,-20
	addi.w	$r12,$r12,1
	st.w	$r12,$r22,-20
.L2:
	ld.w	$r13,$r22,-20
	ld.w	$r12,$r22,-28
	blt	$r13,$r12,.L5
	la.local	$r4,.LC0
	bl	%plt(printf)
	or	$r12,$r0,$r0
	or	$r4,$r12,$r0
	lu12i.w	$r13,65536>>12			# 0x10000
	ori	$r13,$r13,64
	add.w	$r3,$r3,$r13
.LCFI3 = .
	ld.w	$r1,$r3,2028
.LCFI4 = .
	ld.w	$r22,$r3,2024
.LCFI5 = .
	addi.w	$r3,$r3,2032
.LCFI6 = .
	jr	$r1
.LFE0:
	.size	main, .-main
	.section	.eh_frame,"aw",@progbits
.Lframe1:
	.4byte	.LECIE1-.LSCIE1
.LSCIE1:
	.4byte	0
	.byte	0x3
	.ascii	"\000"
	.byte	0x1
	.byte	0x7c
	.byte	0x1
	.byte	0xc
	.byte	0x3
	.byte	0
	.align	2
.LECIE1:
.LSFDE1:
	.4byte	.LEFDE1-.LASFDE1
.LASFDE1:
	.4byte	.LASFDE1-.Lframe1
	.4byte	.LFB0
	.4byte	.LFE0-.LFB0
	.byte	0x4
	.4byte	.LCFI0-.LFB0
	.byte	0xe
	.byte	0xf0,0xf
	.byte	0x4
	.4byte	.LCFI1-.LCFI0
	.byte	0x81
	.byte	0x1
	.byte	0x96
	.byte	0x2
	.byte	0x4
	.4byte	.LCFI2-.LCFI1
	.byte	0xc
	.byte	0x16
	.byte	0
	.byte	0x4
	.4byte	.LCFI3-.LCFI2
	.byte	0xc
	.byte	0x3
	.byte	0xf0,0xf
	.byte	0x4
	.4byte	.LCFI4-.LCFI3
	.byte	0xc1
	.byte	0x4
	.4byte	.LCFI5-.LCFI4
	.byte	0xd6
	.byte	0x4
	.4byte	.LCFI6-.LCFI5
	.byte	0xe
	.byte	0
	.align	2
.LEFDE1:
	.ident	"GCC: (GNU) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
