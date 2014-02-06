read_data(File) :-
    open(File, read, Fd),
    read(Fd, First),
    read_data(First, Fd),
    close(Fd).

read_data(end_of_file, _) :- !.
read_data(Term, Fd) :-
    af(Term),
    read(Fd, Next),
    read_data(Next, Fd).
