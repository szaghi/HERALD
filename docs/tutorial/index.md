# Tutorial

Six chapters, each a complete program in `docs/examples/src/` that the documentation build compiles and runs: every
listing and every output on these pages comes from it.

| Chapter | You learn |
|---|---|
| [1. Ranks and messages](/tutorial/01-ranks) | to declare, initialize and finalize the handler, and to print |
| [2. Errors](/tutorial/02-errors) | that an error on one rank stops them all |
| [3. Timers](/tutorial/03-timers) | named timers and their report over the ranks |
| [4. Memory](/tutorial/04-memory) | the memory budget of a rank and how to respect it |
| [5. A communicator of your own](/tutorial/05-communicator) | a handler on a part of the ranks |
| [6. Devices](/tutorial/06-device) | the device of a rank and who shares it |

The examples print only what does not change from a machine to another: logical facts in place of timings and sizes.
Where a real output matters (a timing table, a GPU), the page shows one captured by hand and says so.
