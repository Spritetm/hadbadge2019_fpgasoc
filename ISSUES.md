# Known Issues

Do not use this file for problems that should be fixed before Supercon, create a Github issue instead.

This document is only for tracking items out of our control to fix, such as problems in external dependencies.

---

Symptom: tinyprog fails to launch with SyntaxError in more_itertools module

file more.py declaration def _collate(*iterables, key=lambda a: a, reverse=False):

Explanation: tinyprog is a Python 2 program, but more_itertools has dropped support for Python 2 so running latest version raises SyntaxError.

Solution: Make sure tinyprog runs with more_itertools version 5, the final version to support Python 2. ([source](https://pypi.org/project/more-itertools/))

Note: Will become moot if the switch to DFU-based bootloader is successful.

---

Symptom: nextpnr-ecp5 fails to launch with file not found error for libpython3.7m.so.1.0

Solution: Install Python 3 development libraries. On Debian (& derivatives) this can be done by running: sudo apt-get install libpython3.7-dev

---
