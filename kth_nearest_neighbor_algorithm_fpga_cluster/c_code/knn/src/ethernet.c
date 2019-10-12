/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

#include "ethernet.h"

extern volatile int TcpFastTmrFlag;
extern volatile int TcpSlowTmrFlag;

void ethernet_accept(){
	xil_printf("\n--- Waiting for connection ---\n");

	ACCEPTED_CONNECTION=0;
	/* wait for socket.connect() from python script */
	while (!ACCEPTED_CONNECTION) {
		if (TcpFastTmrFlag) {
			tcp_fasttmr();
			TcpFastTmrFlag = 0;
		}
		if (TcpSlowTmrFlag) {
			tcp_slowtmr();
			TcpSlowTmrFlag = 0;
		}
		xemacif_input(echo_netif);
	}
	xil_printf("TCP connection accepted\n");
}

void ethernet_send(int * kth_nearest, int k){
	xil_printf("\n--- Sending Ethernet packet ---\n");

	int i;
	struct pbuf *p;
	for(i=0; i<k; i++)
	{
		p->payload=malloc(sizeof(kth_nearest[i]));
		*(int *)p->payload=kth_nearest[i];
		p->len=sizeof(kth_nearest[i]);
		err_t err = tcp_write(TCP_PCB, p->payload, p->len, 1);
		//xil_printf("write err: %d\n", err);
		pbuf_free(p);
	}
	tcp_output(TCP_PCB); //send packet
	xil_printf("Done sending TCP packet\n");
}

void ethernet_receive(){
	ETH_PACKETS_RECEIVED=0;
		xil_printf("\nReceiving Ethernet Packets...\n");
		/* receive and process packets */
		while (NUM_ETH_PACKETS!=ETH_PACKETS_RECEIVED) {
			if (TcpFastTmrFlag) {
				tcp_fasttmr();
				TcpFastTmrFlag = 0;
			}
			if (TcpSlowTmrFlag) {
				tcp_slowtmr();
				TcpSlowTmrFlag = 0;
			}
			xemacif_input(echo_netif);
		}
		xil_printf("Done Receiving Ethernet Packets\n\n");
}

err_t recv_callback(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err)
{

	/* indicate that the packet has been received */
	tcp_recved(tpcb, p->len);
	/* copy payload into char buff */
	memcpy(VECTORS+BUF_OFFSET,p->payload, p->len);
	BUF_OFFSET=BUF_OFFSET+p->len;
	ETH_PACKETS_RECEIVED++;
	pbuf_free(p);
	return ERR_OK;
}

err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err)
{
	static int connection = 1;

	/* set the receive callback for this connection */
	tcp_recv(newpcb, recv_callback);
	/* just use an integer number indicating the connection id as the
	   callback argument */
	tcp_arg(newpcb, (void*)(UINTPTR)connection);
	/* increment for subsequent accepted connections */
	connection++;
	TCP_PCB=newpcb;
	ACCEPTED_CONNECTION=1;
	return ERR_OK;
}


int start_application()
{
	err_t err;
	//.11 5 02, .12 11 03, .13 13 04

	struct tcp_pcb *pcb;
	/* create new TCP PCB structure */
	pcb = tcp_new();
	if (!pcb) {
		xil_printf("Error creating PCB. Out of Memory\n\r");
		return -1;
	}

	err = tcp_bind(pcb, IP_ADDR_ANY, port);
	if (err != ERR_OK) {
		xil_printf("Unable to bind to port %d: err = %d\n\r", port, err);
		return -2;
	}

	/* we do not need any arguments to callback functions */
	tcp_arg(pcb, NULL);

	/* listen for connections */
	pcb = tcp_listen(pcb);
	if (!pcb) {
		xil_printf("Out of memory while tcp_listen\n\r");
		return -3;
	}

	/* specify callback to use for incoming connections */
	tcp_accept(pcb, accept_callback);

	return 0;
}


