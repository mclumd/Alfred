
println('*** Demo for backward search ***').
println('********************************').
println('We add the following to the database:').
println('bif(p(X), q(X)), bif(q(X), r(X)), if(p(X), s(X)), p(a), p(b)').
println('Notice that the first two are bif. These will only be used for').
println('backward chaining, whereas the third can be used for forward').
println('chaining too.').
println(' ').
command(af(bif(p(X), q(X)))).
command(af(bif(q(X), r(X)))).
command(af(if(p(X), s(X)))).
command(af(p(a))).
command(af(p(b))).
sr.
yesorno('View the database now:', yes, true, halt).
command(sdb).
println('No inferences made yet.').
yesorno('Step a couple of times', yes, true, halt).
command(sr).
command(sr).
println('Here is the database:').
command(sdb).
println('Notice that s(a) and s(b) have been derived but not q(a) or q(b).').
println('Now we try to do a backward search for r(a).').
yesorno('Add bs(r(a))', yes, true, halt).
command(af(bs(r(a)))).
yesorno('Step once and see the databsse', yes, true, halt).
command(sr).
command(sdb).
println('The bs has just been added to the database but not processed').
yesorno('Step once and see the databsse', yes, true, halt).
command(sr).
command(sdb).
println('Now we start the backward search:').
println('        assuming not(r(a)), we get not(r(a))').
println('We also assert that we are doing the backward search: doing_bs.').
yesorno('Step once and see the databsse', yes, true, halt).
sr.
sdb.
println('Now we see that assuming not(r(a)) entails not(q(a))').
yesorno('Step once and see the databsse', yes, true, halt).
sr.
sdb.
println('And that entails not(p(a)). But we do know p(a).').
yesorno('Step once and see the databsse', yes, true, halt).
sr.
sdb.
println('r(a) has been proven and is now in the database.').
println('And the fact that we are doing a backward search is withdrawn.').
yesorno('Step once more', yes, true, halt).
sr.
sdb.
println('Now the fact that we have done the backward search, is added').
println('Thats all.').
halt.

