# Mac Toolchain Instructions

The recommended approach is to download Sean Cross' toolchain v1.6.1 (latest at the time of writing) which gives both the FPGA toolchain as well as the RISC-V one.

https://github.com/xobs/ecp5-toolchain/releases

Add the toolchain to the front of your PATH variable.


### macOS Catalina

Catalina machines are extra suspicious of files downloaded from the internet, and by default won't allow binaries from the toolchain to run. To exempt our binaries from
suspicion, you can remove the `com.apple.quarantine` attribute from each of the files. In your terminal, run:

```sh
$ xattr -r -d com.apple.quarantine <toolchain_path>
```

Replace `<toolchain_path>` with the path to your toolchain folder. For example, if you downloaded v1.6.2, you might run:

```sh
$ xattr -r -d com.apple.quarantine ~/Downloads/ecp5-toolchain-macos-v1.6.2
```

You can also manually allow each binary (and library) to run from the "Security and Privacy" preferences pane, but this is incredibly tedious.
