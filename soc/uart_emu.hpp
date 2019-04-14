
#pragma once

using namespace std;

class Uart_emu {
	public:
	Uart_emu(int divisor);
	int eval(int clk, int rx, int *tx);

	private:
	virtual void char_to_host(char c);
	virtual int char_from_host(); //-1 is no char
	
	int m_oldclk;
	int m_divisor;
	int m_rxctr;
	int m_rxbit;
	int m_rxdata;

	int m_txdata;
	int m_txbit;
	int m_txctr;
	int m_curr_tx;
};
