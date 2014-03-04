/*
File: ctime2.pl
By: kpurang

What:
Used so that the executable alma knows when it has been compiled.
*/

:- use_module(library(date)).

write_comp_date:-
    open('compdate.pl', 'write', S),
    get_time(Z),
    stamp_date_time(Z, T, 'UTC'),
    format_time(atom(CT), '%A %B %d %Y %H:%M', T),
    %ctime(CT),
    name(CT, Date),
    name('print(''Compiled on ', F), 
    append(F, Date, IG),
    append(IG, [39, 41], G),
    name(GG, G),
    write(S, :-(print_compiled, (GG, nl, nl))),
    write(S, '.'),
    close(S).

:- write_comp_date.

