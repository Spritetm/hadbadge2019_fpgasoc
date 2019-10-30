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
 * along with the software.  If not, see <https://www.gnu.org/licenses/>.
 */

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