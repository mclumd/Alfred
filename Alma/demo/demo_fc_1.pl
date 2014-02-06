
println('***Demo for simple inference***').
println('*******************************').
println('We add to the database:').
println('  if(p(X), q(X)) and p(a)').
af(if(p(X), q(X))).
af(p(a)).
yesorno('Do you want to step once', yes, true, halt).
sr.
println('This is the database now:').
sdb.
print('The inference has not yet been made. We need one more step').
yesorno('One more step', yes, true, halt).
sr.
println('Now we can view the database.').
sdb.
println('Thats all').
halt.
