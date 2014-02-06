:-ensure_loaded(library(socket)).
:-ensure_loaded(library(quintus)).
:-ensure_loaded(library(readutil)).

main :-
    unix(argv(L)),
    handle_args(L).
   
handle_args([]):- !.
handle_args([pcfile, F|X]):-
    start_connect(F),
    handle_args(X).

start_connect(F):-
    %  gethost_n_port(F, Host, Port),
    read_data(F).
start_connect(_).
    
read_data(File) :-
    open(File, read, Fd),
    read(Fd, First),
    read_data(First, Fd),
    close(Fd).

read_data(end_of_file, _) :- print('eof'), nl,!.
read_data(Term, Fd) :-
    print(Term),        %extract_atom(Term),
    read(Fd, Next),
    read_data(Next, Fd).


gethost_n_port(F, Host, Port) :-
    open(F, read, Fd),
    read_line_to_codes(Fd, Term),
    read_line_to_codes(Fd, Sec),
    string_to_list(Atom, Term),
    string_to_list(Atom2, Sec),
    format('atom is ~p', [Atom]), nl,
    format('atom is ~p', [Atom2]), nl,
    %append(Atom, port, Port),
    %append(Atom2, host, Host),
    extract_atom([Atom], Host, Port),
    format('port is ~p', [Port]), nl,
    format('host is ~p', [Host]), nl.
    %extract domain and port
gethost_n_port(end_of_file,_,_):- !.




extract_atom(T) :-
    print('in extract atom/1, T: '), print(T), nl , !.


extract_atom([port, P|X]):-
    print('in extract, port'),nl,
    extract_atom(X).
extract_atom([host, H|X], Host, Port):-
    print('in extract, host'),nl,
    extract_atom(X, Host, Port).
extract_atom(end_of_file,_,_):- format('third==',[]),nl,!.
extract_atom(X,_,_):- format('WTF: ~p', [X]), nl, !.    


create_client(Host, Port) :-
    tcp_socket(Socket),
    tcp_connect(Socket, Host:Port),
    tcp_open_socket(Socket, ReadFd, WriteFd),
    read(ReadFd, Term),
    print(Term), nl,
    write(WriteFd, 'writing to stream writefd'),
    close(ReadFd),
    close(WriteFd).
