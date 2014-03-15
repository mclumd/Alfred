isa(dcommand, 'fly').

structure('fly', 
	[[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']], 
	[[v0,verb], [v1, plane], [v2, end], [v3, city]],
	[v0,v1,v3]).

structure('fly', 
	[[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J'], [v0,v4,'MV'], [v4,v5,'J']], 
	[[v0,verb], [v1, plane], [v2, start], [v3, city], [v4, end], [v5, city]],
	[v0,v1,v5]).

structure('fly', 
	[[v0,v2,'O'], [v1,v2,'A']], 
	[[v0,verb], [v1, plane], [v2, city]],
	[v0,v1,v2]).


%just copying 'send' format from trains domain.	
isa(dcommand, 'load').

structure('load', 
	[[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']], 
	[[v0,verb], [v1, pkg], [v2, end], [v3, plane]],
	[v0,v1,v3]).

%just copying 'send' format from trains domain.	
isa(dcommand, 'unload').

structure('unload', 
	[[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']], 
	[[v0,verb], [v1, pkg], [v2, start], [v3, plane]],
	[v0,v1]).
	
structure('unload', 
	[[v0,v1,'O']], 
	[[v0,verb], [v1, pkg]],
	[v0,v1]).

%find command is not yet implemented
%	[[v0,verb], [v1, parcel], [v2, end], [v3, plane]],
%	[v0,v1,v3]).


isa(dcommand, 'find').

structure('find',
	  [[v0,v1,'O']],
	  [[v0,verb], [v1, plane]],
	  [v0,v1]).

structure('find',
	  [[v0,v1,'O']],
	  [[v0,verb], [v1, pkg]],
	  [v0,v1]).

isa(observation, 'location').

syntax('location', [v0, plane, city]).
syntax('location', [v0, pkg, city]).
isa(observation, 'location').

syntax('location', [v0, plane, city]).

result(find, location).
