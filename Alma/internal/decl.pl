/*
File: internal/decl.pl
By: kpurang
What: does declarations that alma needs

Todo: implement the thing
      move things from other places to this directory

*/
%
% declarations
%

declare(functional(P, N)):-
    assert(functionalist(P, N, null, null)).



