/*==========================================================
 * Copyright 2020 QuickLogic Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *==========================================================*/

/*==========================================================
 *
 *    File   : main.c
 *    Purpose: main for advancedfpga example using ledctlr.v
 *
 *=========================================================*/

#include "Fw_global_config.h"
#include "Bootconfig.h"

#include <stdio.h>
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"
#include "timers.h"
#include "RtosTask.h"

/*    Include the generic headers required for sensorHub */
#include "eoss3_hal_gpio.h"
#include "eoss3_hal_rtc.h"
#include "eoss3_hal_fpga_usbserial.h"
#include "ql_time.h"
#include "s3x_clock_hal.h"
#include "s3x_clock.h"
#include "s3x_pi.h"
#include "dbg_uart.h"
#include "eoss3_hal_spi.h"
#include "cli.h"

extern const struct cli_cmd_entry my_main_menu[];

#include "fpga_loader.h"        // API for loading FPGA
#include "top_bit.h"   // FPGA bitstream to load into FPGA


const char *SOFTWARE_VERSION_STR;


/*
 * Global variable definition
 */


extern void qf_hardwareSetup();
static void nvic_init(void);

struct fpga_ctrl_regs {
    uint32_t    device_id;			// 0x00
    uint32_t    device_id2;			// 0x00
} __attribute__((packed,aligned(4)));

static volatile struct fpga_ctrl_regs * const fpga_regs = (void*)(FPGA_PERIPH_BASE);
static volatile uint32_t * const ep_ram_dbg = (void*)(FPGA_PERIPH_BASE + 0x0000);
static volatile uint32_t * const ep_ram = (void*)(FPGA_PERIPH_BASE + 0x6000);

void fpga_init(void)
{
	// Setup FPGA clocks
	S3x_Clk_Set_Rate(S3X_FB_16_CLK, 12000*1000);
	S3x_Clk_Set_Rate(S3X_FB_21_CLK, 12000*1000);
	S3x_Clk_Enable(S3X_FB_16_CLK);
	S3x_Clk_Enable(S3X_FB_21_CLK);

	// Confirm expected IP is loaded
#if 0
	for (int i=0; i<16; i++) {
		const uint32_t cw[4] = { 0xcafebabe, 0xb16b00b5, 0xdeadbeef, 0xbaadc0de };
		ep_ram[i] = cw[i&3];
		printf("%08x - %02x%02x%02x%02x\n",
			cw[i&3],
			ep_ram_dbg[(i<<2) | 3],
			ep_ram_dbg[(i<<2) | 2],
			ep_ram_dbg[(i<<2) | 1],
			ep_ram_dbg[(i<<2) | 0]
		);
	}

	printf("----\n");

	for (int i=0; i<16; i++) {
		const uint32_t cw[4] = { 0xcafebabe, 0xb16b00b5, 0xdeadbeef, 0xbaadc0de };
		ep_ram_dbg[(i<<2) | 3] = (cw[i&3] >> 24) & 0xff;
		ep_ram_dbg[(i<<2) | 2] = (cw[i&3] >> 16) & 0xff;
		ep_ram_dbg[(i<<2) | 1] = (cw[i&3] >>  8) & 0xff;
		ep_ram_dbg[(i<<2) | 0] = (cw[i&3] >>  0) & 0xff;
		printf("%08x - %08x\n", cw[i&3], ep_ram[i]);
	}
#else
	//const uint32_t cw[4] = { 0xcafebabe, 0xb16b00b5, 0xdeadbeef, 0xbaadc0de };
	const uint32_t cw[4] = { 0x00010203, 0x04050607, 0x08090a0b, 0x0c0d0e0f };

	for (int i=0; i<16; i++) {
		ep_ram[i] = cw[i&3];
	}

	for (int i=0; i<1024; i++)
		fpga_regs->device_id = 0;

	for (int i=0; i<16; i++) {
		printf("%08x - %08x\n", cw[i&3], ep_ram[i]);
	}
#endif

	/* Hang there */
	while (1);
}




int main(void)
{

    SOFTWARE_VERSION_STR = "qorc-sdk/qf_apps/qf_advancedfpga";

    qf_hardwareSetup();                                     // Note: pincfg_table.c has been updated to give FPGA control of LEDs
    nvic_init();
    S3x_Clk_Disable(S3X_FB_21_CLK);
    S3x_Clk_Disable(S3X_FB_16_CLK);
    S3x_Clk_Enable(S3X_A1_CLK);
    S3x_Clk_Enable(S3X_CFG_DMA_A1_CLK);
    load_fpga(sizeof(axFPGABitStream),axFPGABitStream);     // Load bitstrem into FPGA
    fpga_init();

    dbg_str("\n\n");
    dbg_str( "##########################\n");
    dbg_str( "Quicklogic QuickFeather Advanced FPGA Example XXX\n");
    dbg_str( "SW Version: ");
    dbg_str( SOFTWARE_VERSION_STR );
    dbg_str( "\n" );
    dbg_str( __DATE__ " " __TIME__ "\n" );
    dbg_str( "##########################\n\n");


    CLI_start_task( my_main_menu );

    /* Start the tasks and timer running. */
    vTaskStartScheduler();
    dbg_str("\n");

    while(1);

}

static void nvic_init(void)
 {
    // To initialize system, this interrupt should be triggered at main.
    // So, we will set its priority just before calling vTaskStartScheduler(), not the time of enabling each irq.
    NVIC_SetPriority(Ffe0_IRQn, configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY);
    NVIC_SetPriority(SpiMs_IRQn, configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY);
    NVIC_SetPriority(CfgDma_IRQn, configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY);
    NVIC_SetPriority(Uart_IRQn, configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY);
    NVIC_SetPriority(FbMsg_IRQn, configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY);
 }

//needed for startup_EOSS3b.s asm file
void SystemInit(void)
{

}


