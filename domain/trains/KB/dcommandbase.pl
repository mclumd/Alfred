isa(dcommand, 'send').

structure('send', 
	[[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']], 
	[[v0,verb], [v1, train], [v2, end], [v3, city]],
	[v0,v1,v3]).

structure('send', 
	[[v0,v2,'O'], [v1,v2,'A']], 
	[[v0,verb], [v1, train], [v2, city]],
	[v0,v1,v2]).

structure('send', 
	[[v0,v4,'0'], [v0,v4,'MV'], [v1,v3,'D'], [v2,v3,'AN'], [v4,v5,'J']],
	[[v0,verb], [v2,v3,train], [v4, end], [v5, city]],
	[v0,v2,v3,v5]).

isa(dcommand, 'find').

structure('find',
	  [[v0,v1,'O']],
	  [[v0,verb], [v1, train]],
	  [v0,v1]).

isa(observation, 'location').

syntax('location', [v0, city]).

result(find, location).
