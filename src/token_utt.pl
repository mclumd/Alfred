
token_utt(Utt, Sp) :- 
   concat_atom([Utt, w, 0], WNumInID),
   af(isa(Utt, leftwall, WNumInID)),
   af(has(Utt, leftwall, Utt, WNumInID)),
   assertWordsLetters(Utt, Sp, 0, 0, 32).



assertWordsLetters(_, [], _, _, _) :-
/*af(test31(Prev)),

   (Prev \== 32 ->
        (
af(test32(Prev))
	 )
	;true).*/
true.



assertWordsLetters(Utt, [First|Rem], WNumIn, LNumIn, Prev) :-


   ((Prev \== 32, First \== 32) ->
        (
/*af(test11(Prev)),*/
         LNum is LNumIn+1, 
         concat_atom([Utt, w, WNumIn], WNumInID),
/*af(test12(Prev)),*/
   	 concat_atom([WNumInID, ltr, LNum], LNumID),
/*af(test13(Prev)),*/
         concat_atom([WNumInID, ltr, LNumIn], LNumInID),
/*af(test14(Prev)),*/
	 concat_atom([Utt, sp, WNumIn], SpID),
/*af(test15(Prev)),*/
	 af(isa(Utt, letter, LNumID)),
	 af(has(Utt, letter, SpID, LNumID)),
         af(has(Utt, successor, LNumInID, LNumID)),
	 af(has(Utt, ascii_code, LNumID, First))
	 );true),

   (Prev == 32 ->	
	(
/*af(test21(Prev)),*/
         WNum is WNumIn+1,
   	 concat_atom([Utt, w, WNum], WNumID),
/*af(test22(Prev)),*/
   	 concat_atom([Utt, w, WNumIn], WNumInID),
/*af(test23(Prev)),*/
 	 af(isa(Utt, word, WNumID)),
	 af(has(Utt, word, Utt, WNumID)),
	 af(has(Utt, successor, WNumInID, WNumID)),

/*af(test24(Prev)),*/

         concat_atom([Utt, sp, WNum], SpID),
         af(has(Utt, spelling, WNumID, SpID)),
	 af(isa(Utt, spelling, SpID)),

/*af(test25(Prev)),*/
	 LNumIn is 0,
         LNum is LNumIn+1,
   	 concat_atom([WNumID, ltr, LNum], LNumID),
/*af(test26(Prev)),*/
         concat_atom([WNumID, ltr, 0], LNumInID),
/*af(test27(Prev)),*/
	 af(isa(Utt, leftwall, LNumInID)),
	 af(has(Utt, leftwall, SpID, LNumInID)),
	 af(isa(Utt, letter, LNumID)),
	 af(has(Utt, letter, SpID, LNumID)),
         af(has(Utt, successor, LNumInID, LNumID)),
	 af(has(Utt, ascii_code, LNumID, First)),
         assertWordsLetters(Utt, Rem, WNum, LNum, First)
	 );

	 assertWordsLetters(Utt, Rem, WNumIn, LNum, First) 

   ).

