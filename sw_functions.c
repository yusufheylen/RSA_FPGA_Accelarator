/*
 * sw_functions.c
 *
 *  Created on: Nov 20, 2024
 *      Author: r0752973
 */

#include "sw_functions.h"
#include <stdint.h>

// Register file shared with FPGA
  volatile uint32_t* HWreg = (volatile uint32_t*)0x40400000;

  // Input registers
  #define COMMAND    0
  #define RX_REG1_ADDR   1  // Message Address register				 || X, B
  #define RX_REG2_ADDR   2  // Modulus Address register				 || N, P, Q
  #define RX_REG3_ADDR   3  // Exponent (e and d) Address register	 || dP, dQ, e
  #define RX_REG4_ADDR  4  // RN Address register					 || RN, RP, RQ, A
  #define RX_REG5_ADDR 5  // R2N Address register					 || R2N, R2P, R2Q
  #define TXADDR     6  // Write back address						 || &RETURN_ADDRESS (VARIES)
  #define EXP_LEN    7  // Exponant length register					 || EXP_LEN_N, EXP_LEN_P, EXP_LEN_Q


  // Output registers
  #define STATUS  0


void calculate_RN_R2N(uint32_t *RN_new, uint32_t *RN_old, uint32_t *R2N_new, uint32_t *R2N_old, uint32_t *N) {
	/*
	 * N is 1024b ==> 32w
	 * -N is 1025b ==> 32w + 1w(sign)
	 * RN_new ==> 32w
	 *
	 *
	 * I/O: always 32w, but intermediates are 33w
	 */

//	uint32_t carry_N = 1;
//	uint32_t sum_N = 0;
//	for (uint32_t i=0; i<32; i++) {
//		sum_N = N[i] + carry_N
//	}

	/* PSEUDOCODE
	 *
	 * allocate space (33w) for N_neg
	 *
	 * N_carry = 0
	 * for (i=0 -> 31) do
	 * 		N_carry, N_neg[i] = ~N[i] + carry_N
	 *
	 */

}


void RSA_HW_encrypt() {
	// CALL EXPONENTIATION (...)
}


void EXP_HW(uint32_t *X, uint32_t *E, uint32_t e_len, uint32_t *N, uint32_t *R2N, uint32_t *RN, uint32_t *odata) {
	/*
	 * X: message
	 * E: exponent
	 * N: modulus
	 * RN: R%N
	 * R2N: (R*R)%N
	 *
	 */
	// STORE GIVEN ADDRESSES INTO HW REGISTERS
	  HWreg[RX_REG1_ADDR]    = (uint32_t)&X; 	 	// store address X in reg1
	  HWreg[RX_REG2_ADDR]    = (uint32_t)&N; 	 	// store address N in reg2
	  HWreg[RX_REG3_ADDR]    = (uint32_t)&E; 	 	// store address exponent (N, P, Q) in reg3
	  HWreg[RX_REG4_ADDR]    = (uint32_t)&RN;   	// store address R_N in reg4
	  HWreg[RX_REG5_ADDR]    = (uint32_t)&R2N;  	// store address idata in reg5

	  xil_printf("%p", &odata);


	  HWreg[TXADDR] 		 = (uint32_t)&odata;	// store address odata in reg 6
	  HWreg[EXP_LEN]  		 = (uint32_t)e_len;     // store the exp length in reg 7


	  // START EXPONENTIATION
	  HWreg[COMMAND] = 0x01;						// COMMAND: 0x00: CLEAN: 0x01: EXP, 0x02: MUL
	  // Wait until FPGA is done
	  while((HWreg[STATUS] & 0x01) == 0);			// STATUS: 0x01 indicates FPGA is done

	  //Say stop to HW
	  HWreg[COMMAND] = 0x00;						// STOP THE FPGA
}


void MUL_HW(uint32_t *A, uint32_t *B, uint32_t *N, uint32_t *R2N, uint32_t *odata) {
	/*
	 * A: message
	 * B: exponent
	 * N: modulus
	 * R2N: (R*R)%N
	 *
	 * Return A*B mod N
	 */
	  HWreg[RX_REG4_ADDR]    = (uint32_t)&A; 	 	// store address A in reg4
	  HWreg[RX_REG1_ADDR]    = (uint32_t)&B; 	 	// store address B in reg1
	  HWreg[RX_REG2_ADDR]   = (uint32_t)&N;   	// store address 	 N in reg2
	  HWreg[RX_REG5_ADDR]   = (uint32_t)&R2N;   	// store address   R2N in reg5

	  HWreg[TXADDR] 	 = (uint32_t)&odata;	// store address odata in reg 6

	  // START COMMAND=0x02 (MUL)
	  HWreg[COMMAND] = 0x02;
	  // Wait until FPGA is done
	  while((HWreg[STATUS] & 0x01) == 0);

	  //Say stop to HW
	  HWreg[COMMAND] = 0x00;
}

void SUB_SW() {}

void ADD_SW() {}

void ADD_COND_SW() {}

void SUB_COND_SW() {}


void RSA_HW_decrypt() {
	/* MAKE SURE THAT P > Q				--> enforce from Python
	 *
	 * M1 <- EXP_HW(X, dP, R2P, RP, P)
	 * SAVE M1
	 * M2 <- EXP_HW(X, dQ, R2Q, RQ, P)
	 * SAVE M2
	 *
	 * M3 <- M1-M2					// SUB_SW
	 * If (M3 < 0): M3 <- M3+P		// ADD_COND_SW
	 *
	 * M4 <- MUL_HW(qINV, M3, P, R2P)
	 * SAVE M4
	 *
	 * M5 <- MUL_HW(h, Q, M, R2N)
	 * SAVE M5
	 *
	 * RES <- M2+M5						// ADD_SW
	 * If (RES > N): RES <- RES - N		// SUB_COND_SW
	 */
}
