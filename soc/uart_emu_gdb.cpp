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
#include <sys/types.h>
#include <unistd.h>
#include "uart_emu_gdb.hpp"
#include <stdlib.h>

Uart_emu_gdb::Uart_emu_gdb(int divisor): Uart_emu(divisor) {
	m_gdb_fd=getpt();
	grantpt(m_gdb_fd);
	unlockpt(m_gdb_fd);
	char cmdline[1024];
//	sprintf(cmdline, "/home/jeroen/hackaday2019/riscv-toolchain/bin/riscv32-unknown-elf-gdb -ex \"target remote %s\" app/app.elf", ptsname(m_gdb_fd));
	sprintf(cmdline, "/home/jeroen/hackaday2019/riscv-toolchain/bin/riscv32-unknown-elf-gdb -ex \"set debug remote 1\" -ex \"target remote %s\" app/app.elf", ptsname(m_gdb_fd));
	pid_t r=fork();
	if (r==0) {
		//child; execute gdb
		execl("/bin/sh", "sh", "-c", cmdline, (char *) 0);
	}
}

void Uart_emu_gdb::char_to_host(char c) {
	write(m_gdb_fd, &c, 1);
//	write(2, &c, 1);
}

int Uart_emu_gdb::char_from_host() {
	fd_set rfd;
	FD_ZERO(&rfd);
	FD_SET(m_gdb_fd, &rfd);
	struct timeval to={0};
	int r=select(m_gdb_fd+1, &rfd, NULL, NULL, &to);
	if (!r) return -1;
	char c;
	read(m_gdb_fd, &c, 1);
	return c;
}
