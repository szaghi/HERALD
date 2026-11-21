---
icon: report
---

# A CSV for a scaling study

`timer%report_csv_string()` returns the table of the report for a program to read. It is collective, as the report
is: every rank calls it, and every rank gets the same string.

<<< @/examples/snippets/cookbook_timers-csv.F90{fortran}

`timer%report(unit=unit, csv=.true.)` does the same on an open unit, writing on rank 0.

## The columns

| Column | Meaning |
|---|---|
| `timer` | the name, quoted |
| `calls` | calls of all the ranks |
| `min_s`, `mean_s`, `max_s` | minimum, mean and maximum over the ranks of the timer's total seconds |
| `max_over_mean` | load imbalance |
| `per_call_s` | seconds of all the ranks over their calls |
| `cpu_over_wall` | CPU seconds of all the ranks over their wall seconds |
| `misuses` | [misuses](/cookbook/misuse) of all the ranks |

The first line is `# consistent,true` or `# consistent,false`: false when the ranks did not create the same timers
in the same order, and then the values are those of the rank that wrote the file. The last line, `(unknown stops)`,
carries under `misuses` the stops of names never started.

Three of the columns, from the program above:

<<< @/examples/output/cookbook-timers.txt{text}

For strong scaling, run at each number of ranks and compare `mean_s` of a region: the speedup is their ratio.
