isa(acommand, 'is').


structure('is',
	[[v0, v4, 'X'], [v0,v1, 'W'], [v1, v2, 'S'], [v2, v3, 'O']],
	[[v0, lw], [v1,qnword], [v2, verb], [v4,qnmark]],
	[what, v3]).

structure('is',
	[[v0,v1,'S'], [v1,v2,'O']],
	[[v1,verb]],
	[equil, v0, v2]).

structure('is',
	[[v0,v1,'S'], [v1,v3,'O'], [v2,v3,'s^'], [v3, v4, 's^']],
	[[v1,verb], [v3, conjunct]],
	[compose, v0, v2, v4]).


isa(qnword, 'what').

isa(qnmark, '?').

isa(lw, 'LEFT-WALL').

isa(acommand, 'no').

isa(conjunct, 'and').

structure('no',
        [],
        [],
        [undo]).

