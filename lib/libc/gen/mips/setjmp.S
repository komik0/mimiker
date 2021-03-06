/*	$NetBSD: setjmp.S,v 1.19 2010/09/03 17:22:51 matt Exp $	*/

/*-
 * Copyright (c) 1991, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * Ralph Campbell.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <sys/syscall.h>
#include <mips/asm.h>

#include "mips/assym.h"

/*
 * C library -- setjmp, longjmp
 *
 * longjmp(a,v) will generate a "return(v)" from the last call to setjmp(a) by
 * restoring registers from the stack, and a struct ucontext, see <signal.h>
 */

#define SETJMP_FRAME_SIZE	(CALLFRAME_SIZ + STACK_SIZ)

NON_LEAF(setjmp, SETJMP_FRAME_SIZE, ra)
	.mask	0x80010000, (CALLFRAME_RA - CALLFRAME_SIZ)
	SETUP_GP
	PTR_SUBU	sp, sp, SETJMP_FRAME_SIZE	# allocate stack frame
	SAVE_GP(CALLFRAME_GP)

	REG_S		ra, CALLFRAME_RA(sp)		# save RA
	REG_S		s0, CALLFRAME_S0(sp)		# save S0
	move		s0, a0				# save sigcontext

	/* Get the signal mask (the value of `how` doesn't matter). */
	PTR_ADDU	a2, a0, UC_MASK         # old mask
	move		a1, zero                # new mask (NULL)
	jal		_C_LABEL(sigprocmask)	# get current signal mask

	/* Get the signal stack. */
	move		a0, zero                        # new stack (NULL)
	PTR_ADDU	a1, sp, CALLFRAME_SIZ		# pointer to stack_t
	jal		_C_LABEL(sigaltstack)

	INT_L		v1, CALLFRAME_SIZ+SS_FLAGS(sp)	# get old ss_onstack
	and		v1, v1, SS_ONSTACK		# extract onstack flag
        beqz            v1, 1f
	
        INT_L		a0, UC_FLAGS(s0)
        or              v1, a0, _UC_STACK
	INT_S		v1, UC_FLAGS(s0)

1:	move		a0, s0			# restore jmpbuf
	REG_L		s0, CALLFRAME_S0(sp)	# restore S0
	REG_L		ra, CALLFRAME_RA(sp)	# restore RA
	blt		v0, zero, 2f		# check for sigaltstack() error

	/* We know we won't need this routine's GP anymore. */
	PTR_ADDU	sp, sp, SETJMP_FRAME_SIZE	# pop stack frame
	j		_C_LABEL(_setjmp)

2:	jal		_C_LABEL(abort)
END(setjmp)
