
token_utt(Utt, Sp) :- 
   af(isa(Utt, leftwall, w0)),
   assertWordsLetters(Utt, Sp, 0, 0, [],32).

assertWordsLetters(Utt, [], WNumIn, _, CurList,Prev):-
   WNum is WNumIn+1,
   (Prev \== 32 -> 
       	(
   	 createIDFromLetNum(119, WNum, WNumID),
   	 createIDFromLetNum(119, WNumIn, WNumInID),
	 af(has(Utt, succ, WNumInID, WNumID)),
	 af(isa(Utt, word, WNumID)),
         atom_chars(Word, CurList), 
         af(has(Utt, spelling, WNumID, Word)));true).

assertWordsLetters(Utt, [First|Rem], WNumIn, LNumIn, CurList, Prev) :-
   WNum is WNumIn+1,
   LNum is LNumIn+1, 

   createIDFromLetNum(108, LNum, LNumID),
   createIDFromLetNum(108, LNumIn, LNumInID),
   af(has(Utt, lsucc, LNumInID, LNumID)),                            
   af(has(Utt, ascii, LNumID, First)),
   af(isa(Utt, letter, LNumID)),

   ((Prev \== 32, First == 32) ->	
	(
   	 createIDFromLetNum(119, WNum, WNumID),
   	 createIDFromLetNum(119, WNumIn, WNumInID),

	 af(has(Utt, succ, WNumInID, WNumID)),
	 atom_chars(Word, CurList),
         af(has(Utt, spelling, WNumID, Word)),
	 af(isa(Utt, word, WNumID)), 
	 assertWordsLetters(Utt, Rem, WNum,LNum, [],First)
	);
	
	(
	 (First \== 32 -> 
          append(CurList, [First], NewList);
	 true),		
   	 assertWordsLetters(Utt, Rem, WNumIn, LNum, NewList,First))
	).


      

