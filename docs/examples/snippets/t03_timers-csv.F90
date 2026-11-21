csv = mpih%timer%report_csv_string()
if (mpih%is_root()) print '(A)', csv(1:index(csv, new_line('a'))-1), 'misuses on this rank: '//merge('none', 'some', &
                                 mpih%timer%misuses() == 0)
