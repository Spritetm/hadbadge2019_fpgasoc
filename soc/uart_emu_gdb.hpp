#include "uart_emu.hpp"
#pragma once

using namespace std;

class Uart_emu_gdb: public Uart_emu {
	public:
	Uart_emu_gdb(int divisor);

	private:
	virtual void char_to_host(char c);
	virtual int char_from_host();
	int m_gdb_fd;
};
