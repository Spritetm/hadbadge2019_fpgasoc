# Known Issues

Do not use this file for problems that should be fixed before Supercon, create a Github issue instead.

This document is only for tracking items out of our control to fix, such as problems in external dependencies.

---

Symptom: nextpnr-ecp5 fails to launch with file not found error for libpython3.7m.so.1.0

Solution: Install Python 3 development libraries. On Debian (& derivatives) this can be done by running: sudo apt-get install libpython3.7-dev

---
