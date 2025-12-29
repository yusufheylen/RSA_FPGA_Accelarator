#include "common.h"
#include <stdalign.h>
#include "sw_functions.h"
#include  <stdint.h>

// These variables are defined in the testvector.c
// that is created by the testvector generator python script
extern uint32_t N[32],    // modulus
                e[32],    // encryption exponent
                e_len,    // encryption exponent length
                d[32],    // decryption exponent
                d_len,    // decryption exponent length
                M[32],    // message
                R_N[32],  // 2^1024 mod N
                R2_N[32],// (2^1024)^2 mod N
				res[32];

#define ISFLAGSET(REG,BIT) ( (REG & (1<<BIT)) ? 1 : 0 )

void print_array_contents(uint32_t* src) {
  int i;
  for (i=32-4; i>=0; i-=4)
    xil_printf("%08x %08x %08x %08x\n\r",
      src[i+3], src[i+2], src[i+1], src[i]);
}

void print_array_err(uint32_t* src, uint32_t* ref) {
  int i;
  xil_printf("Error vs reference \n\r");
  for (i=32-4; i>=0; i-=4)
    xil_printf("%08x %08x %08x %08x\n\r",
    		ref[i+3]-src[i+3], ref[i+2]-src[i+2], ref[i+1]-src[i+1], ref[i]-src[i]);
}

int main() {

  init_platform();
  init_performance_counters(0);

  xil_printf("Begin\n\r");

  // Register file shared with FPGA
//  volatile uint32_t* HWreg = (volatile uint32_t*)0x40400000;
//
//  // Input registers
//  #define COMMAND    0
//  #define RX_MADDR   1  // Message Address register
//  #define RX_NADDR   2  // Modulus Address register
//  #define RX_EADDR   3  // Exponent (e and d) Address register
//  #define RX_RNADDR  4  // RN Address register
//  #define RX_R2NADDR 5  // R2N Address register
//  #define TXADDR     6  // Write back address
//  #define EXP_LEN    7  // Exponant length register
//
//  // Output registers
//  #define STATUS  0
//
//  // Aligned input and output memory shared with FPGA
alignas(128) uint32_t odata[32]; //NB CHANGE FOR EACH FIMCTOIPM CLALKJ
//
//  // Initialize odata to all zero's
memset(odata,0,128);
//
//  // CSR (input):
//  HWreg[RX_MADDR]    = (uint32_t)&M; 	 // store address M in reg1
//  HWreg[RX_NADDR]    = (uint32_t)&N; 	 // store address N in reg2
//  HWreg[RX_EADDR]    = (uint32_t)&e; 	 // store address exponent in reg3
//  HWreg[RX_RNADDR]   = (uint32_t)&R_N;   // store address R_N in reg4
//  HWreg[RX_R2NADDR]  = (uint32_t)&R2_N;  // store address idata in reg5
//
//  HWreg[TXADDR] 	 = (uint32_t)&odata; // store address odata in reg 6
//
//  HWreg[EXP_LEN]  = (uint32_t)e_len;     // store the exp length in reg 7

//
//  printf("STATUS %08X\r\n", 	(unsigned int)HWreg[STATUS]    );
//  printf("RX_MADDR %08X\r\n", 	(unsigned int)HWreg[RX_MADDR]  );
//  printf("RX_NADDR %08X\r\n", 	(unsigned int)HWreg[RX_NADDR]  );
//  printf("RX_EADDR %08X\r\n", 	(unsigned int)HWreg[RX_EADDR]  );
//  printf("RX_RNADDR %08X\r\n",  (unsigned int)HWreg[RX_RNADDR] );
//  printf("RX_R2NADDR %08X\r\n", (unsigned int)HWreg[RX_R2NADDR]);
//  printf("TXADDR %08X\r\n",     (unsigned int)HWreg[TXADDR]	   );
//  printf("EXP_LEN %08X\r\n",    (unsigned int)HWreg[EXP_LEN]   );

// Call HW
START_TIMING
//  HWreg[COMMAND] = 0x01;
//  // Wait until FPGA is done
//  while((HWreg[STATUS] & 0x01) == 0);
    EXP_HW(M, e, e_len, N, R_N, R2_N, odata);

xil_printf("%p", &odata);
STOP_TIMING
//  HWreg[COMMAND] = 0x00;

//  printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));
//  printf("STATUS 1 %08X\r\n", (unsigned int)HWreg[1]);
//  printf("STATUS 2 %08X\r\n", (unsigned int)HWreg[2]);
//  printf("STATUS 3 %08X\r\n", (unsigned int)HWreg[3]);
//  printf("STATUS 4 %08X\r\n", (unsigned int)HWreg[4]);
//  printf("STATUS 5 %08X\r\n", (unsigned int)HWreg[5]);
//  printf("STATUS 6 %08X\r\n", (unsigned int)HWreg[6]);
//  printf("STATUS 7 %08X\r\n", (unsigned int)HWreg[7]);

  printf("\r\nExp_Data:\r\n"); print_array_contents(odata);

  print_array_err(odata, res);

  cleanup_platform();

  return 0;
}



/*
 * REGISTER ALLOCATION
 *
 * R0:
 * R1:
 * R2:
 * R3:	&e
 * R4:	e_len
 * R5:	&d
 * R6:	d_len
 * R7:	&M
 * R8:	&R_N
 * R9:	R2_N
 * R10:
 * R11:
 * R12:
 * R13:
 * R14:
 * R15:
 * R16:
 * R17:
 * R18:
 * R19:
 * R20:
 * R21:
 * R22:
 */



//void move_inputs_to_hw_reg(uint32_t *N,							// modulus
//						   uint32_t *e, uint32_t e_len,			// encryption exponent, encryption exponent length
//						   uint32_t *d, uint32_t d_len,			// decryption exponent, decryption exponent length
//						   uint32_t *M,							// message
//						   uint32_t *R_N,						// 2^1024 mod N
//						   uint32_t *R2_N,						// (2^1024)^2 mod N
//						   uint32_t *
//						  ) {
//}
