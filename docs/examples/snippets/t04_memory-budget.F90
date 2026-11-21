budget = mpih%memory%per_rank() ! bytes; -1 where /proc is missing
if (mpih%is_root()) then
   print '(A,L1)', 'the budget is known:                  ', budget > 0
   print '(A,L1)', 'it is the limit over the node ranks:  ', budget == mpih%memory%limit/mpih%node_procs_number
   print '(A,L1)', 'the limit is the node or the cgroup:  ', mpih%memory%limit_source == 'node' .or. &
                                                             mpih%memory%limit_source == 'cgroup'
endif
