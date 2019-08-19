#include <stdint.h>

using namespace std;
class Psram_emu {
	public:
	Psram_emu(int memsize);
	int load_file(const char *file, int offset, bool is_ro);
	int eval(int clk, int ncs, int sin, int oe, int *sout);
	const uint8_t *get_mem();
	void force_qpi();

	private:
	int m_size;
	uint8_t *m_mem;
	uint8_t *m_roflag;

	int m_nib;
	uint8_t m_cmd;
	uint32_t m_addr;
	bool m_qpi_mode;
	int m_sout_next, m_sout_cur;
	bool m_oldclk;
	uint8_t m_writebyte;
};

