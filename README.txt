ALFRED

Features: 
Internal Pause Time Reasoning
Universal Domain: Can connect to multiple domains at once
In the process of integrating new concept space.


Current Software
----------------
Most recent version can be found on github @ github.com/mclumd/Alfred

Older versions:
ALFRED on CS Servers:
@erewhon /group/work/alf_alone
@erewhon /group/work/alf_mcl

Quintus Prolog on CS Servers:
@erewhon /anhan/quintus_prolog


ALFRED
-------
You need to download Alfred as well as the quintus prolog compiler from the locations mentioned above. There is an install script for the quintus_prolog. This is needed to compile Alfred. We are currently in the process of converting from quintus prolog to SWI prolog. But for now you must use quintus prolog.
 
Change makefile in Alma/ to point to your qpc directory and then build ALMA.

Do the same for Carne/

And BerkeleyParser/

Change paths in bin/alfred, bin/ra, bin/rc, bin/rd.trains, bin/rp, domain/trains/rd.trains scripts.

Now, run ALFRED in bin directory with ./alfred trains rd

This should open 4 windows, one black, one yellow, one blue, and one green. The green window is the BerkeleyParser where you type your commands. The yellow window tells you which options you have for commands. The black window is the Alma. And the blue window is Carne.

If you don't get 4 windows, run each script separately. Start with ra, then rc, then rp, then rd.trains. If something doesn't work it is likely that you need to rebuild Alma, or Carne or you need to change a path in one of those files.

./alfred trains rd will run the trains domain. You can enter commands such as "send Metroliner to Baltimore"

./alfred planes rd will run the planes domain. Similar format for commands. You can also load packages onto planes.

./alfred universal rd will run the universal domain. When it opens you can say "run planes" or "run trains" and it will run those domains for you. You can enter commands for each domain.



