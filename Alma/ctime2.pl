/*
File: ctime2.pl
By: kpurang

What:
Used so that the executable alma knows when it has been compiled.


*/


:- ensure_loaded(library(date)).
:- use_module(library(tcp)).


:- dynamic ctime/1.

cdtime(timeval(Seconds, MicroSeconds)):-
    tcp_date_timeval(Date,timeval(Seconds, MicroSeconds)),
    time_stamp(Date,'%W %M %02d %y %02c:%02i', Stamp),
    assert(ctime(Stamp)).


:- tcp:tcp_now(Z), cdtime(Z).


write_comp_date:-
    open('compdate.pl', 'write', S),
    ctime(CT),
    name(CT, Date),
    name('print(''Compiled on ', F), 
    append(F, Date, IG),
    append(IG, [39, 41], G),
    name(GG, G),
    write(S, :-(print_compiled, (GG, nl, nl))),
    write(S, '.'),
    close(S).

:- write_comp_date.




