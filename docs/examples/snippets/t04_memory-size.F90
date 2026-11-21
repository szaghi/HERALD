cells = (8*budget/10)/BYTES_PER_CELL ! 80% of the budget, the rest for everything else
call mpih%check_memory(bytes_needed=cells*BYTES_PER_CELL, what='the cells')
