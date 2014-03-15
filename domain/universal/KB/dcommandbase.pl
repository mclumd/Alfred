%universal domain ****************************************************

isa(dcommand, 'run').
structure('run',
          [[v0,v1,'O']],
          [[v0,verb], [v1, domain]],
          [v0,v1]).

isa(dcommand, 'show').
structure('show',
        [],
        [[v0,verb]],
        [v0]).

isa(dcommand, 'hide').
structure('hide',
          [],
          [[v0,verb]],
          [v0]).

isa(dcommand, 'quit').
structure('quit',
          [[v0,v1,'O']],
          [[v0,verb], [v1,domain]],
          [v0,v1]).

structure('quit',
        [],
        [[v0,verb]],
        [v0]).


%restaurant domain ****************************************************

isa(dcommand, 'display').
structure('display',
        [[v0,v2,'O'], [v1,v2,'D']],
        [[v0,verb],[v1,all],[v2,display_type]],
        [restaurant,[v0,v2,v1]]).

structure('display',
        [[v0,v2,'O'], [v1,v2,'D']],
        [[v0,verb],[v1,cuisine],[v2,display_type]],
        [restaurant,[v0,v2,v1]]).


structure('display',
        [[v0,v2,'O'], [v1,v2,'D']],
        [[v0,verb],[v1,food_type],[v2,display_type]],
        [restaurant,[v0,v2,v1]]).

%chess domain ****************************************************

isa(dcommand, 'move').
structure('move',
        [[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']],
        [[v0,verb], [v1, position], [v2, end], [v3, position]],
        [chess,[v1,v3]]).

%draughts domain ****************************************************

structure('move',
        [[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']],
        [[v0,verb], [v1, position], [v2, end], [v3, position]],
        [draughts,[v0, v1,v3]]).

%email domain ****************************************************

isa(dcommand, 'check').
structure('check',
        [[v0,v1,'O']],
        [[v0,verb], [v1,mail]],
        [popkorn,[v0,v1]]).


%house domain ****************************************************

isa(dcommand, 'light').
structure('light',
        [[v1,v2,'MV'], [v2,v4,'J'], [v3,v4,'AN']],
        [[v1,verb], [v2, status], [v3, room], [v4, direction]],
        [house,[v1,v2, v3, v4]]).

%movies domain ****************************************************

isa(dcommand, 'play').
structure('play',
        [[v0,v1,'O']],
        [[v0,verb], [v1,movie]],
        [movies,[v0,v1]]).

structure('play',
        [[v0,v1,'O'],[v0,v3,'O']],
        [[v0,verb], [v1,movie], [v2, conjunct], [v3, movie]],
        [movies,[v0,v1,v3]]).

isa(dcommand, 'fullscreen').
structure('fullscreen',
        [],
        [[v0,verb]],
        [movies,[v0]]).

isa(dcommand, 'stop').
structure('stop',
        [],
        [[v0,verb]],
        [movies,[v0]]).

isa(dcommand, 'set').
structure('set',
        [[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']],
        [[v0,verb], [v1, parameter], [v2, end], [v3, number]],
        [movies,[v0,v1,v3]]).

isa(dcommand, 'list').
structure('list',
          [],
          [[v0,verb]],
          [movies,[v0]]).

structure('list',
          [[v0,v1,'O']],
          [[v0,verb]],
          [movies,[v0]]).

isa(dcommand, 'mute').
structure('mute',
          [],
          [[v0,verb]],
          [movies,[v0]]).

%trains domain ****************************************************

isa(dcommand, 'send').

structure('send',
        [[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']],
        [[v0,verb], [v1, train], [v2, end], [v3, city]],
        [trains,[v0,v1,v3]]).

structure('send',
        [[v0,v2,'O'], [v1,v2,'A']],
        [[v0,verb], [v1, train], [v2, city]],
        [trains,[v0,v1,v2]]).

isa(dcommand, 'find').

structure('find',
          [[v0,v1,'O']],
          [[v0,verb], [v1, train]],
          [trains,[v0,v1]]).

isa(observation, 'location').

syntax('location', [v0, train, city]).

result(find, location).

%planes domain *****************************************************
isa(dcommand, 'fly').

structure('fly', 
	[[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']], 
	[[v0,verb], [v1, plane], [v2, end], [v3, city]],
	[planes,[v0,v1,v3]]).

%structure('fly', 
%	[[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J'], [v0,v4,'MV'], [v4,v5,'J']], 
%	[[v0,verb], [v1, plane], [v2, start], [v3, city], [v4, end], [v5, city]],
%	[v0,v1,v5]).

%structure('fly', 
%	[[v0,v2,'O'], [v1,v2,'A']], 
%	[[v0,verb], [v1, plane], [v2, city]],
%	[v0,v1,v2]).


%just copying 'send' format from trains domain.	
%isa(dcommand, 'load').

%structure('load', 
%	[[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']], 
%	[[v0,verb], [v1, pkg], [v2, end], [v3, plane]],
%	[v0,v1,v3]).

%just copying 'send' format from trains domain.	
%isa(dcommand, 'unload').

%structure('unload', 
%	[[v0,v1,'O'], [v0,v2,'MV'], [v2,v3,'J']], 
%	[[v0,verb], [v1, pkg], [v2, start], [v3, plane]],
%	[v0,v1]).
	
%structure('unload', 
%	[[v0,v1,'O']], 
%	[[v0,verb], [v1, pkg]],
%	[v0,v1]).

%find command is not yet implemented
%	[[v0,verb], [v1, parcel], [v2, end], [v3, plane]],
%	[v0,v1,v3]).


%isa(dcommand, 'find').

%structure('find',
%	  [[v0,v1,'O']],
%	  [[v0,verb], [v1, plane]],
%	  [v0,v1]).

%structure('find',
%	  [[v0,v1,'O']],
%	  [[v0,verb], [v1, pkg]],
%	  [v0,v1]).

%isa(observation, 'location').

%syntax('location', [v0, plane, city]).
%syntax('location', [v0, pkg, city]).
%isa(observation, 'location').

%syntax('location', [v0, plane, city]).

%result(find, location).







