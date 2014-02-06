println('********************************************').
println('***Demo for simple contradiction handling***').
println('********************************************').
handle_args([alfile, 'tweet.pl', load, 'tweet_help.pl']).
println('The files containing the alma senetences and the prolog helper').
println('programs have been loaded.').
println('').
println('The sentences of greatest interest are:').
println('Tweety is a penguin:').
println('penguin(tweety)').
println('Penguins are birds:').
println('if(penguin(X), bird(X))').
println('Usually birds fly:').
println('named(fif(bird(X), conclusion(fly(X))), birdsfly)').
println('Usually penguins dont fly:').
println('named(fif(penguin(X), conclusion(not(fly(X)))), penguinsdontfly)').
println('Note that the two defaults have names. This allows us to state').
println('that we prefer the second default to the first:').
println('prefer(penguinsdontfly, birdsfly)').
println('We also have some sentences that determine how contradictions are').
println('to be handled').
println(' ').
yesorno('We step a couple of times', yes, true, halt).
command(sr).
command(sr).
println('This is the database:').
command(sdb).
println('Note that we have derived that Tweety does not fly and that it').
println('is a bird. At the next step, we will derive that it flies since').
println('it is a bird.').
yesorno('Step', yes, true, halt).
command(sr).
command(sdb).
println('Notice that we have both that Tweety both flies and that it does').
println('not fly in the database. However, these cannot be used for further').
println('inference. This can be seen by querying the database.').
yesorno('Query the database', yes, true, halt).
command(query(fly(tweety))).
command(query(not(fly(tweety)))).
println('Neither query returns an answer, so the system has no knowledge').
println('about Tweety flying').
yesorno('Step once more', yes, true, halt).
command(sr).
command(sdb).
println('Note here that the fact that there is a contradiction has been').
println('asserted, together with the fact that the contradictands have').
println('been distrusted. The assertion of the contra predicate starts the').
println('contradiction resolution process.').
yesorno('Query whether Tweety flies', yes, true, halt).
command(query(fly(tweety))).
yesorno('Step', yes, true, halt).
command(sr).
command(sdb).
println('Note that the system tries to find the parents of the contradictands.').
yesorno('Step', yes, true, halt).
command(sr).
command(sdb).
println('Once the parents have been found, the preference can be used to').
println('resolve the contradiction').
yesorno('Verify that we still know nothing about Tweety flying', yes, true, halt).
command(query(fly(tweety))).
yesorno('Verify that we know that Tweety is a bird', yes, true, halt).
command(query(bird(tweety))).
yesorno('Step', yes, true, halt).
command(sr).
command(sdb).
println('At this point, the contradiction has been resolved. And a new').
println('instance of not(fly(tweety)) has been added.').
yesorno('Verify whether Tweety flies', yes, true, halt).
command(query(fly(tweety))).
println('Thats it').
halt.

