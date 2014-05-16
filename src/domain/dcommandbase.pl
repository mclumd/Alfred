isa(dcommand, 'send').

structure('send',
	[verb, dirobj, indirobjprep, indirobj],
	[dcommand, train, end, city],
	[verb, dirobj, indirobj]).

isa(dcommand, 'find').

structure('find',
	  [verb, dirobj],
	  [verb, train],
	  [verb, dirobj]).

isa(observation, 'location').

syntax('location', [v0, train, city]).

result(find, location).

d_isa(c_d_command, c_d_send).
d_isa(c_d_command, c_d_find).

d_isa(c_d_send, l_d_send).
d_isa(c_d_find, l_d_find).

d_isa(l_d_send, 'send').
d_isa(l_d_find, 'find').
