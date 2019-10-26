/*
 * Copyright 2019 Jeroen Domburg <jeroen@spritesmods.com>
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software.  If not, see <https://www.gnu.org/licenses/>.
 */
#include <stdint.h>
#include <stdio.h>
#include <sys/select.h>
#include "uart_emu.hpp"

Uart_emu::Uart_emu(int divisor) {
	m_divisor=divisor;
	if (divisor!=0) {
		printf("UART: Fixed divisor %d\n", divisor);
	}
	m_rxctr=0;
	m_rxbit=0;
	m_oldclk=1;
	m_txbit=0;
	m_curr_tx=1;
}

void Uart_emu::char_to_host(char c) {
	fprintf(stderr, "%c", c);
}

int Uart_emu::char_from_host() {
	fd_set rfd;
	FD_ZERO(&rfd);
	FD_SET(0, &rfd);
	struct timeval to={0};
	int r=select(1, &rfd, NULL, NULL, &to);
	if (!r) return -1;
	return fgetc(stdin);
}

int Uart_emu::eval(int clk, int rx, int *tx) {
	if (clk && (clk!=m_oldclk)) {
		if (m_txbit==0) {
			m_txdata=this->char_from_host();
			if (m_txdata!=-1) {
				m_txbit=1;
				m_txctr=0;
				m_curr_tx=0;
			}
		} else {
			m_txctr++;
			if (m_txctr==m_divisor) {
				m_txctr=0;
				m_txbit++;
				if (m_txbit>=2 && m_txbit<10) {
					m_curr_tx=m_txdata&(1<<(m_txbit-2));
				} else if (m_txbit==10) {
					m_curr_tx=1;
				} else if (m_txbit==11) {
					m_txbit=0;
				}
			}
		}
		
		if (m_rxbit==0 && rx==0) {
			m_rxctr=m_divisor/2; //sample on half cycle
			m_rxbit=1;
			m_rxdata=0;
		} else if (m_rxctr==m_divisor) {
			if (m_rxbit==1) {
				if (rx==1) {
					m_rxbit=0;
				} else {
					m_rxbit=2;
				}
			} else if (m_rxbit<=9) {
				m_rxdata>>=1;
				if (rx) m_rxdata|=0x80;
				m_rxbit++;
			} else if (m_rxbit==10) {
				if (!rx) {
					printf("Uart: Error! Stop bit high!\n");
				} else {
					this->char_to_host(m_rxdata);
					m_rxbit=0;
				}
			}
			m_rxctr=0;
		} else if (m_rxbit!=0) {
			m_rxctr++;
		}
	}
	m_oldclk=clk;
	*tx=m_curr_tx?1:0;
	return 0;
}