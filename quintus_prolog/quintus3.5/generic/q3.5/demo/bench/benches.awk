
# @(#)benches.awk	24.2 04/14/88

# benches.awk : Produce a table showing two sets of test data and the
#		ratio between them. Assumes that the input is the
#		concatenation of two lots of output from benches.pl with
#		each line containing a test name and a time. There should
#		be no other formatting lines in the input.
#
BEGIN	{ x = 0;		    # State variable for code below
	  if (na == "") na = "A";   # Can be overridden on command line
	  if (nb == "") nb = "B";   # Can be overridden on command line
	}
x == 0  { x = 1; marker = $1; markcount = 1; n = 1; }	# mark first entry
x == 1	{						# entry in file 1
	  if ($1 == marker && markcount++ > 1) x = 2;
	   else {
		    key[n] = $1;
		    a[$1] = $2;
		    n += 1;
	  }
	}
x == 2	{						# entry in file 2
	  b[$1] = $2;
	  if ($2 == 0) c[$1] = 0;  else c[$1] = a[$1] / $2;
	}
END	{
	    printf("  %-24s%16s%16s%18s\n\n", \
		      "TEST", na, nb, "RATIO");
	  for(i = 1; i < n; i++) {
	    k = key[i];
	    printf("  %-24s%16.2f%16.2f%18.2f\n", k, a[k], b[k], c[k]);
	    avg += c[k];
	  }
	  avg /= (n-1);
	    printf("\n  %-24s%32s%18.2f\n", \
		    "Average:", "", avg);
	}
