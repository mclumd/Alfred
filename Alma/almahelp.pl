/*
File: almahelp.pl
By: kpurang

What:
Provides some help about the alma commancd

Todo:
Add more help.

*/

alma_help:-
    print('Online help:'), nl, nl,
    print('For help on keywords, alma_help(keywords).'), nl,
    print('For help on commands, alma_help(commands).'), nl,
    print('For help on parameters, alma_help(parameters).'), nl,
    print('For help on predicates, alma_help(predicates).'), nl.

alma_help(keywords):- !,
    print('Keywords:'),nl,
    print('  bs/1'),nl,
    print('  call/1'),nl.

alma_help(commands):- !,
    print('Commands:'),nl,
    print('  initialize/0'),nl,
    print('  af/1'),nl,
    print('  df/1'),nl,
    print('  lf/1'),nl,
    print('  s/0'),nl,
    print('  s/1'),nl,
    print('  sdb/0'),nl,
    print('  delete_bs_tree/1'),nl,
    print('  quit'),nl,
    print('  load_files'), nl.

alma_help(parameters):- !,
    print('Parameters:'),nl,
    print('  yesshowstep/0'),nl,
    print('  noshowstep/0'),nl,
    print('  yesstatistics/0'),nl,
    print('  nostatistics/0'),nl,
    print('  set_agenda_number/1'),nl,
    print('  yesdeletetrees/0'),nl,
    print('  nodeletetrees/0'),nl.

alma_help(predicates):- !,
    print('Predicates:'), nl,
    print('  now/1'), nl.

alma_help(_):-
    alma_help.
