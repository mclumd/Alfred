isa(dcommand, 'fly').

structure('fly',
	[verb, dirobj, indirobjprep, indirobj],
	[verb, plane, end, city],
	[verb, dirobj, indirobj]).

isa(dcommand, 'load').

structure('load',
	[verb, dirobj, indirobjprep, indirobj],
	[verb, pkg, end, plane],
	[verb, dirobj, indirobj]).

isa(dcommand, 'unload').

structure('unload',
	[verb, dirobj, indirobjprep, indirobj],
	[verb, pkg, start, plane],
	[verb, dirobj, indirobj]).

structure('unload',
	[verb, dirobj],
	[verb, pkg],
	[verb, dirobj]).

isa(dcommand, 'find').

structure('find',
	  [verb, dirobj],
	  [verb, plane],
	  [verb, dirobj]).

structure('find',
	  [verb, dirobj],
	  [verb, pkg],
	  [verb, dirobj]).

isa(observation, 'planelocation').

syntax('planelocation', [v0, plane, city]).

result(find, planelocation).
