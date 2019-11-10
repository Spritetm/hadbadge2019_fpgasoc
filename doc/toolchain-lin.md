
ToDo: document this

If you want to compile your own RiscV toolchain, see https://github.com/riscv/riscv-gnu-toolchain .
Specifically, you want a multilib Newlib toolchain, something that is not in the list. Just
invoke these two commands after having fulfilled all prerequisites and you should be good:

```
./configure --prefix=/opt/riscv --enable-multilib
make
```

