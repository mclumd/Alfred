/* Scott

English Lexicon

Each word is built using forward if rules when the rules are 
added to the KB and fire. Because only one predicate is 
allowed on the RHS of rules, a first rule generates all
of the ID #'s to be used for the lexeme, stores them in 
a predicate, and then that predicate is used to for each
rule that generates a property of each lexeme.
*/

/* Verbs*/
/* recharge*/
    /*generate the ID#'s used for this lexeme.*/

fif(eval_bound(unique_id(ID1, ID2, ID3, ID4, ID5),
conclusion(lexeme(1, ID1, ID2, ID3, ID4, ID5))).

    /*The first ID is the name of the lexeme. Properties are
    predicated of this ID.*/

fif(lexeme1(ID1, ID2, ID3, ID4, ID5),
conclusion(isa(null, lexeme, ID1))).

fif(lexeme1(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, lexeme, english, ID1))).

fif(lexeme1(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, part_of_speech, ID1, verb))).

    /*The second and third ID#'s are for forms that the lexeme
    takes, in this case the non-finite and finite forms.*/

fif(lexeme1(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, form, ID1, ID2))).

fif(lexeme1(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, form, ID1, ID3))).

    /*The fourth and fifth ID#'s are used for the spellings
    of each form.*/

fif(lexeme1(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, spelling, ID2, ID4))).

    /*More ID#'s are used for each letter in the spelling
    of each form. They are generated and stored in a new
    predicate.*/

fif(and(lexeme1(ID1, ID2, ID3, ID4, ID5),
       and(and(and(and(and(and(and(eval_bound(unique_id(ID6),[]),
				   eval_bound(unique_id(ID13),[])),
			       eval_bound(unique_id(ID12),[])),
			   eval_bound(unique_id(ID11),[])),
		       eval_bound(unique_id(ID10),[])),
		   eval_bound(unique_id(ID9),[])),
	       eval_bound(unique_id(ID8),[])),
	   eval_bound(unique_id(ID7),[]))),
conclusion(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13)).

    /*Each spelling has letters, and each letter has properties
    that are predicated of the ID# used for that letter.*/

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(isa(null, spelling, ID4))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, letter, ID4, ID6))).

    /*The first letter of each spelling is stated to be first.*/

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(isa(null, first, ID6))).

    /*The ascii value of each letter is stored as a property
    of that letter.*/

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, ascii_value, ID6, 114))).

    /*Finally, the first letter is given a letter that comes
    after it (in linear order).*/

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, successor, ID6, ID7))).

    /*And the next letter gets the same treatment, except that
    it is not given an ordinal property (i.e., first, second).
    This information can be retrieved from the successor 
    relation.*/


fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, letter, ID4, ID7))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, ascii_value, ID7, 101))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, successor, ID7, ID8))).



fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, letter, ID4, ID8))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, ascii_value, ID8, 99))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, successor, ID8, ID9))).



fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, letter, ID4, ID9))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, ascii_value, ID9, 104))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, successor, ID9, ID10))).



fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, letter, ID4, ID10))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, ascii_value, ID10, 97))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, successor, ID10, ID11))).



fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, letter, ID4, ID11))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, ascii_value, ID11, 114))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, successor, ID11, ID12))).



fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, letter, ID4, ID12))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, ascii_value, ID12, 103))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, successor, ID12, ID13))).


fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, letter, ID13, ID13))).

fif(spelling1(ID4, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13),
conclusion(has(null, ascii_value, ID12, 101))).

    /*The second form of 'recharge' ('recharged') is spelled 
    out.*/

fif(lexeme1(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, spelling, ID3, ID5))).

fif(and(lexeme1(ID1, ID2, ID3, ID4, ID5),
       and(and(and(and(and(and(and(and(eval_bound(unique_id(ID6),[]),
				   eval_bound(unique_id(ID13),[])),
			       eval_bound(unique_id(ID12),[])),
			   eval_bound(unique_id(ID11),[])),
		       eval_bound(unique_id(ID10),[])),
		   eval_bound(unique_id(ID9),[])),
	       eval_bound(unique_id(ID8),[])),
	   eval_bound(unique_id(ID7),[])),
	eval_bound(unique_id(ID14),[]))),
conclusion(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID4)).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(isa(null, spelling, ID5))).


fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, letter, ID5, ID6))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(isa(null, first, ID6))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, ascii_value, ID6, 114))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, successor, ID6, ID7))).


fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, letter, ID5, ID7))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, ascii_value, ID7, 101))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, successor, ID7, ID8))).


fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, letter, ID5, ID8))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, ascii_value, ID8, 99))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, successor, ID8, ID9))).


fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, letter, ID5, ID9))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, ascii_value, ID9, 104))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, successor, ID9, ID10))).


fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, letter, ID5, ID10))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, ascii_value, ID10, 97))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, successor, ID10, ID11))).


fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, letter, ID5, ID11))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, ascii_value, ID11, 114))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, successor, ID11, ID12))).


fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, letter, ID5, ID12))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, ascii_value, ID12, 103))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, successor, ID12, ID13))).


fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, letter, ID5, ID13))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, ascii_value, ID13, 101))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, successor, ID13, ID14))).


fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, letter, ID5, ID14))).

fif(spelling2(ID5, ID6, ID7, ID8, ID9, ID10, ID11, ID12, ID13, ID14),
conclusion(has(null, ascii_value, ID14, 100))).


/*Other properties are predicated of the forms.*/

fif(lexeme1(ID1, ID2, ID3, ID4, ID5),
conclusion(isa(null, nonfinite, ID2))).

fif(lexeme1(ID1, ID2, ID3, ID4, ID5),
conclusion(isa(null, finite, ID3))).



/* Nouns */
/* little pro: the silent pronoun in subject of commands.*/

fif(and(eval_bound(unique_id(ID1), []),
	and(eval_bound(unique_id(ID2), []),
	    eval_bound(unique_id(ID3), []))),
conclusion(lexeme2(ID1, ID2, ID3))).

fif(lexeme2(ID1, ID2, ID3),
conclusion(isa(null, lexeme, ID2))).
	
fif(lexeme2(ID1, ID2, ID3),
conclusion(has(null, lexeme, english, ID1))).
	
fif(lexeme2(ID1, ID2, ID3),
conclusion(has(null, part_of_speech, ID1, noun))).

fif(lexeme2(ID1, ID2, ID3),
conclusion(isa(null, pronoun, ID1))).

fif(lexeme2(ID1, ID2, ID3),
conclusion(isa(null, little_pro, ID1))).

fif(lexeme2(ID1, ID2, ID3),
conclusion(has(null, form, ID1, ID2))).

fif(lexeme2(ID1, ID2, ID3),
conclusion(has(null, spelling, ID2, ID3))).

fif(lexeme2(ID1, ID2, ID3),
conclusion(isa(null, silent, ID2))).


fif(and(eval_bound(unique_id(ID1), []),
	and(eval_bound(unique_id(ID2), []),
	    and(eval_bound(unique_id(ID3), []),
                eval_bound(unique_id(ID4), []))),
                    eval_bound(unique_id(ID5), []))),
conclusion(lexeme3(ID1, ID2, ID3, ID4, ID5))).

fif(lexeme3(ID1, ID2, ID3, ID4, ID5),
conclusion(isa(null, silent, ID2))).

fif(lexeme3(ID1, ID2, ID3, ID4, ID5),
conclusion(isa(null, lexeme, ID1))).

fif(lexeme3(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, lexeme, english, ID1))).

fif(lexeme3(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, part_of_speech, ID1, noun))).

fif(lexeme3(ID1, ID2, ID3, ID4, ID5),
conclusion(isa(null, name, ID1))).

fif(lexeme3(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, form, ID1, ID2))).

fif(lexeme3(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, spelling, ID2, ID4))).

fif(lexeme3(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, form, ID1, ID3))).

fif(lexeme3(ID1, ID2, ID3, ID4, ID5),
conclusion(has(null, spelling, ID3, ID6))).


fif(and(eval_bound(unique_id(ID1), []),
	and(eval_bound(unique_id(ID2), []),
	    eval_bound(unique_id(ID3), []))),
conclusion(lexeme4(ID1, ID2, ID3))).

fif(lexeme4(ID1, ID2, ID3),
conclusion(isa(null, lexeme, ID1))).

fif(lexeme4(ID1, ID2, ID3),
conclusion(has(null, lexeme, english, ID1))).

fif(lexeme4(ID1, ID2, ID3),
conclusion(has(null, part_of_speech, ID1, preposition))).

fif(lexeme4(ID1, ID2, ID3),
conclusion(has(null, form, ID1, ID2))).

fif(lexeme4(ID1, ID2, ID3),
conclusion(has(null, spelling, ID2, ID3))).

fif(lexeme4(ID1, ID2, ID3),
conclusion(has(null, theta_assignment, ID1, loc))).


fif(and(eval_bound(unique_id(ID1), []),
	and(eval_bound(unique_id(ID2), []),
	    eval_bound(unique_id(ID3), []))),
conclusion(lexeme5(ID1, ID2, ID3))).

fif(lexeme5(ID1, ID2, ID3),
conclusion(isa(null, lexeme, ID1))).

fif(lexeme5(ID1, ID2, ID3),
conclusion(has(null, lexeme, english, ID1))).

fif(lexeme5(ID1, ID2, ID3),
conclusion(has(null, part_of_speech, ID1, preposition))).

fif(lexeme5(ID1, ID2, ID3),
conclusion(has(null, theta_assignment, ID1, dest))).

fif(lexeme5(ID1, ID2, ID3),
conclusion(has(null, form, ID1, ID2))).

fif(lexeme5(ID1, ID2, ID3),
conclusion(has(null, spelling, ID2, ID3))).


fif(eval_bound(unique_id(ID1), []),
conclusion(lexeme6(ID1))).

fif(lexeme6(ID1),
conclusion(has(null, lexeme, english, ID1))).

fif(lexeme6(ID1),
conclusion(isa(null, theta_role, ID1))).

fif(lexeme6(ID1),
conclusion(isa(null, agent, ID1))).


fif(eval_bound(unique_id(ID1), []),
conclusion(lexeme7(ID1))).

fif(lexeme7(ID1),
conclusion(has(null, lexeme, english, ID1))).

fif(lexeme7(ID1),
conclusion(isa(null, theta_role, ID1))).

fif(lexeme7(ID1),
conclusion(isa(null, theme, ID1))).


fif(eval_bound(unique_id(ID1), []),
conclusion(lexeme8(ID1))).

fif(lexeme8(ID1),
conclusion(has(null, lexeme, english, ID1))).

fif(lexeme8(ID1),
conclusion(isa(null, theta_role, ID1))).

fif(lexeme8(ID1),
conclusion(isa(null, location, ID1))).


fif(eval_bound(unique_id(ID1), []),
conclusion(lexeme9(ID1))).

fif(lexeme9(ID1),
conclusion(has(null, lexeme, english, ID1))).

fif(lexeme9(ID1),
conclusion(isa(null, theta_role, ID1))).

fif(lexeme9(ID1),
conclusion(isa(null, destination, ID1))).




