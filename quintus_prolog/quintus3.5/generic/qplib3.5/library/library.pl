%   File   : library.pl
%   Author : Dave Bowen
%   SCCS   : @(#)94/01/19 library.pl	71.1
%   Purpose: compile the library .pl files to .qof format.

/*  

    If you want to use library files when static linking, either to
    build an extended development system or to build a runtime system,
    you will want to have the library files already compiled.  This is
    now done at Quintus before shipping, but this file is included in
    case you need to do it again for some reason.  Use

	qpc -c library.pl 

    to compile the whole library into .qof format.

    It is unlikely that you would want to include the entire library in
    an application.  Indeed, some of the library files are intended to
    be alternatives and cannot usefully be loaded together because they
    each export the same predicate(s).  In order to avoid name clash
    warning messages when compiling the library, use_module(File, [])
    commands have been used instead of use_module(File) commands in
    these cases.  
*/

%:- use_module(library(QU_messages)).
:- ensure_loaded(library(activeread)).
:- use_module(library(addportray)).
:- use_module(library(aggregate)).
:- use_module(library(antiunify)).
:- use_module(library(arg)).
:- use_module(library(arity)).
% aritystrings.pl exports read_line/1, concat/3, nth_char/3, string_length/2,
% string_search/3
:- use_module(library(aritystrings), []).
:- use_module(library(aropen)).
:- use_module(library(arrays)).
:- use_module(library(ask)).
:- use_module(library(avl)).
:- use_module(library(assoc)).

%% [PM] 3.5 Added empty import list since basics.pl exports memberchk
%% and member which conflicts with bags.pl (and expansion?)
:- use_module(library(bags), []).
:- use_module(library(basics),[]).
% benchmark.pl exports time
:- use_module(library(benchmark), []).
:- use_module(library(between)).
:- use_module(library(big_text)).
:- use_module(library(bitsets)).
:- use_module(library(break)).
:- use_module(library(call)).
:- use_module(library(caseconv)).
:- use_module(library(cassert)).
:- use_module(library(changearg)).
:- use_module(library(charsio)).
:- use_module(library(clump)).
% Obsolete
%:- use_module(library(contains)).
:- use_module(library(continued)).
:- use_module(library(count)).
:- use_module(library(counter)).
:- use_module(library(critical)).
:- use_module(library(crypt)).
:- use_module(library(ctr)).
:- use_module(library(ctypes)).
:- use_module(library(date)).
:- use_module(library(decons)).
:- use_module(library(directory)).
% The next one is irrelevant to most people, and it can't be qpc-ed here
% because it defines the same module (ctypes) as ctypes.pl.
%:- use_module(library(ebctypes)).
:- use_module(library(environ)).
:- use_module(library(environment)).
:- use_module(library(errno)).
:- use_module(library(exit)).
:- use_module(library(expansion)).
%% [PD] 3.5 Add fastrw, fast term I/O used by prologbeans
:- use_module(library(fastrw)).
:- use_module(library(fft)).
:- use_module(library(filename), []).
   % Avoids clash on open_file/3 with library(files)
% [MC] 3.5
:- use_module(library(fastrw)).
:- use_module(library(files)).
:- use_module(library(findall)).
:- use_module(library(flatten)).
:- use_module(library(foreach)).
:- use_module(library(freevars)).
:- use_module(library(fromonto)).
:- use_module(library(fortransup)).
:- use_module(library(fuzzy)).
:- use_module(library(gauss)).
:- use_module(library(getfile)).
:- use_module(library(graphs)).
:- use_module(library(heaps)).
:- use_module(library(indexer)).
:- use_module(library(kee)).
:- use_module(library(knuth_b_1)).
:- use_module(library(length)).
:- use_module(library(level)).
:- use_module(library(lineio)).
:- use_module(library(listparts)).
:- use_module(library(lists)).
:- use_module(library(load)).
:- use_module(library(logarr), []).
   % avoids clash on array_to_list/2 with library(arrays)
:- use_module(library(long), []).
   % avoids clash on rational/1 with library(types)
:- use_module(library(lpa), []).
   % avoids several clashes: lpa.pl imports from several libraries
   % and re-exports some of those predicates.
:- use_module(library(mapand)).
:- use_module(library(maplist)).
:- use_module(library(mapqueue)).
:- use_module(library(maps)).
:- use_module(library(math)).
:- use_module(library(menu)).		% only runs under Emacs
:- use_module(library(morelists)).
:- use_module(library(moremaps)).
:- ensure_loaded(library(mst)).
:- use_module(library(multil)).
% Both queues.pl and newqueues.pl define the same module 'queues'.
:- use_module(library(newqueues)).
:- use_module(library(nlist)).
:- use_module(library(not)).
:- use_module(library(note)).
:- use_module(library(occurs)).
:- use_module(library(openfiles)).
:- use_module(library(order)).
:- use_module(library(ordered)).
:- use_module(library(ordprefix)).
:- use_module(library(ordsets)).
:- use_module(library(pairup)).
:- use_module(library(pipe)).
:- use_module(library(plot)).
:- ensure_loaded(library(portraydate)).
:- use_module(library(pptree)).
:- use_module(library(printchars)).
:- use_module(library(printlength)).
% Obsolete
%:- use_module(library(project)).
:- use_module(library(prompt)).
:- use_module(library(putfile)).
:- use_module(library(qsort)).
:- use_module(library(queues)).
:- use_module(library(random)).
:- use_module(library(ranstk)).
:- use_module(library(read)).
:- use_module(library(readconst)).
:- use_module(library(readin)).
:- ensure_loaded(library(readints)).
:- use_module(library(readsent)).
:- use_module(library(rem)).
:- use_module(library(retract)).
:- use_module(library(samefunctor)).
:- use_module(library(samsort)).
:- use_module(library(setof)).
:- use_module(library(sets)).
:- use_module(library(show)).
:- use_module(library(showmodule)).
:- use_module(library(statistics)).
:- use_module(library(stchk)).
% Obsolete
%:- use_module(library(streampos)).
:- use_module(library(streamproperty)).
:- use_module(library(strings)).
:- use_module(library(subsumes)).
:- use_module(library(termdepth)).
:- use_module(library(terms)).
% Obsolete
%:- use_module(library(time_date)).
:- use_module(library(trees)).
:- use_module(library(tokens)).
:- use_module(library(true)).
:- use_module(library(twild)).
:- use_module(library(types)).
:- use_module(library(unify)).
:- use_module(library(unix)).
:- use_module(library(update)).
:- use_module(library(varnumbers)).
:- use_module(library(vectors)).
:- use_module(library(vsets)).
:- use_module(library(writetokens)).
% [MC] 3.5
:- use_module(library(xml)).
