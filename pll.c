#include <stdint.h>
#include <stdio.h>

int pll(int fin, int idiv, int odiv, int fbdiv) {
	int fvco=(fin/idiv)*odiv*fbdiv;
	if (fvco<400000000 || fvco>800000000) return -1;
	int fout=fvco/odiv;
	return fout;
}


int main(int argc, char **argv) {
	int fin=atoi(argv[1]);
	int fout=atoi(argv[2]);
	for (int idiv=1; idiv<16; idiv++) {
		for (int odiv=1; odiv<32; odiv++) {
			for (int fbdiv=1; fbdiv<32; fbdiv++) {
				int cfout=pll(fin, idiv, odiv, fbdiv);
				if (abs(cfout-fout)<10000) {
					printf("idiv %d odiv %d fbdiv %d fout %d\n", idiv, odiv, fbdiv, cfout);
				}
			}
		}
	}
}