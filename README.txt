ALFRED

Internal Pause Time Reasoning
Last Updated 11.20.13

Currently Implemented
---------------------
Alfred is able to accept English sentences as input. It parses the input using the Berkeley Parser, and asserts the information into its knowledge base (KB), but doesn't do any reasoning with the information. This implementation of Alfred was tested with the trains domain, so it accepts english commands such as "send Metroliner to Baltimore" or "send Bullet to Richmond."

The reasoning implemented in this version of Alfred deals with user pause time. Alfred starts up and has an expectation that the user will enter a command within a certain "reasonable" amount of time. If the expected pause time is exceeded, Alfred prompts the user with "Please tell me what to do now." If the user never responds, Alfred continues to prompt. If the user consistently responds more slowly than Alfred expects, Alfred adjusts its expectations.


Currently not Implemented
-------------------------
Alfred does not do anything with the commands that a user gives it. We are currently transitioning from Link Parser to Berkeley Parser. We are working on fully integrating Alfred with the Berkeley Parser.


Current Software
----------------
Current Version of ALFRED:
@erewhon /group/work/alf_alone

Quintus Prolog:
@erewhon /anhan/quintus_prolog


ALFRED
-------
You need to download Alfred as well as the quintus prolog compiler from the locations mentioned above. There is an install script for the quintus_prolog. This is needed to compile Alfred.
 
Change makefile in Alma/ to point to your qpc directory and then build ALMA.

Do the same for Carne/

And BerkeleyParser/

Change paths in bin/alfred, bin/ra, bin/rc, bin/rd.trains, bin/rp, domain/trains/rd.trains scripts.

Now, run ALFRED in bin directory with ./alfred trains rd

This should open 4 windows, one black, one yellow, one blue, and one green. The green window is the BerkeleyParser where you type your commands. The yellow window tells you which options you have for commands. The black window is the Alma. And the blue window is Carne.

If you don't get 4 windows, run each script separately. Start with ra, then rc, then rp, then rd.trains. If something doesn't work it is likely that you need to rebuild Alma, or Carne or you need to change a path in one of those files.



