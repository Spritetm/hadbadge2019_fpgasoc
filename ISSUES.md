# Known External Issues

This document is a running collection of issues that:
1. Were experienced during development, and
2. Are not problems in badge code. (If so open a Github issue instead.)

If you've figured out such problems, jot it down here to save others time.
Don't worry about making it precise or pretty, we just want to capture the
the knowledge immediately and worry about distilling it all later.

---

Symptom: tinyprog fails with SyntaxError in more_itertools module

file more.py declaration def _collate(*iterables, key=lambda a: a, reverse=False):

Explanation: tinyprog is a Python 2 program, but more_itertools has dropped support for Python 2 so running latest version raises SyntaxError.

Solution: Install more_itertools version 5, the final version to support Python 2. ([source](https://pypi.org/project/more-itertools/))

Note: Will become moot if the switch to DFU-based bootloader is successful.

---

Symptom: nextpnr-ecp5 fails with file not found for libpython3.7m.so.1.0

Solution: Install Python 3 development libraries. On Debian (& derivatives) this can be done by running: sudo apt-get install libpython3.7-dev
