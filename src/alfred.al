/* Scott Fults */



/*If there is a new utterance and there are no current utterances,
make it current and not new.*/

fif(and(isa(Utt,new_utterance),
    eval_bound(\+ pos_int(isa(Utt, current_utterance)), [Utt])),
conclusion(isa(Utt,current_utterance))).

fif(isa(Utt,current_utterance),
  conclusion(eval_bound(df(isa(Utt, new_utterance)), [Utt]))).

/*Tokenize all current utterances into words and letters.*/

/*
fif(and(isa(Utt, current_utterance),
	has(Utt, ascii_string, Sp)),
  conclusion(call(ac_token_utt(Utt, Sp), [Utt,Sp]))).
*/

fif(and(isa(Utt, current_utterance),
	has(Utt, ascii_string, [116, 117, 114, 110, 32, 114, 105, 103, 104, 116, 32, 57, 48, 32, 100, 101, 103, 114, 101, 101, 115])),
 conclusion(make_command_string(Utt, 1))).

fif(and(isa(Utt, current_utterance),
	has(Utt, ascii_string, [115, 116, 111, 112, 32, 116, 117, 114, 110, 105, 110, 103])),
 conclusion(make_command_string(Utt, 2))).

fif(and(isa(Utt, current_utterance),
	has(Utt, ascii_string, [97, 118, 111, 105, 100, 32, 111, 98, 115, 116, 97, 99, 108, 101, 115])),
 conclusion(make_command_string(Utt, 3))).

fif(and(isa(Utt, current_utterance),
	has(Utt, ascii_string, [115, 116, 111, 112, 32, 97, 118, 111, 105, 100, 105, 110, 103, 32, 111, 98, 115, 116, 97, 99, 108, 101, 115])),
 conclusion(make_command_string(Utt, 4))).

fif(and(isa(Utt, current_utterance),
	has(Utt, ascii_string, [109, 111, 118, 101, 32, 102, 111, 114, 119, 97, 114, 100, 32, 49, 32, 109, 101, 116, 101, 114])),
 conclusion(make_command_string(Utt, 5))).

fif(and(isa(Utt, current_utterance),
	has(Utt, ascii_string, [114, 101, 99, 104, 97, 114, 103, 101, 32, 97, 116, 32, 115, 105, 120])),
 conclusion(make_command_string(Utt, 6))).


fif(make_command_string(Utt, 1),
  conclusion(command_string_ready(Utt, 'send marvin start turnTarg(90)'))).

fif(make_command_string(Utt, 2),
  conclusion(command_string_ready(Utt, 'send marvin stop turnTarg()'))).

fif(make_command_string(Utt, 3),
  conclusion(command_string_ready(Utt, 'send marvin start obsAvoid()'))).

fif(make_command_string(Utt, 4),
  conclusion(command_string_ready(Utt, 'send marvin stop obsAvoid()'))).

fif(make_command_string(Utt, 5),
  conclusion(command_string_ready(Utt, 'send marvin action move(100)'))).

fif(make_command_string(Utt, 6),
  conclusion(command_string_ready(Utt, 'send rover1 goal charge() loc 6'))).

fif(and(command_string_ready(Utt, Command_string),
	eval_bound(domain_tag(MySocket),[])),
  conclusion(send_to_domain(Utt, MySocket, Command_string))).

fif(and(send_to_domain(Utt, MySocket, Command_string),
	eval_bound(sending_to_domain(MySocket, Command_string), [MySocket, Command_string])),
  conclusion(sent_command_string(Utt))).

fif(sent_command_string(Utt),
  conclusion(isa(Utt, done_utterance))).

fif(sent_command_string(Utt),
  conclusion(eval_bound(df(isa(Utt, current_utterance)), [Utt]))).

