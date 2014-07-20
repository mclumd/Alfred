failed(ac_main_verb(1),1).

fif(failed(ac_main_verb(Utt),Utt),
conclusion(call(print_something(Utt), Utt))).

fif(failed(ac_main_verb(Utt),Utt),
conclusion(worked(Utt))).

p(a).
