;;; SCCS: @(#)qpfindpred.el	76.1 10/28/98
;;;		    Quintus Prolog - GNU Emacs Interface
;;;                         Support Functions
;;;
;;;	            Consolidated by Sitaram Muralidhar
;;;
;;;		           sitaram@quintus.com
;;;		      Quintus Computer Systems, Inc.
;;;			      2 May 1989	   
;;;
;;; This file defines functions that support the Quintus Prolog - GNU Emacs
;;; interface.
;;;
;;;			       Acknowledgements
;;;
;;;
;;; This interface was made possible by contributions from Fernando
;;; Pereira and various customers of Quintus Computer Systems, Inc.,
;;; based on code for Quintus's Unipress Emacs interface.
;;; 

(provide 'qpfindpred)			; to calm the compiler (BT)

(defmacro error-occurred (&rest body)
  (list 'condition-case nil (cons 'progn (append body '(nil))) '(error t)))

; Used to leave point and mark around the predicate. Now it returns
; a cons cell of where the point and mark would have been set.
; The mark is not set!
(defun find-pred ()
  (interactive)				; should it be really? (BT)
  (let 
      (target-functor
       target-arity 
       backward-predicate-beginning
       backward-predicate-end
       clinfo
       prevpoint
       (continue t)
       (saw-first-clause (find-potential-clause)))

    (setq backward-predicate-beginning (point))
    (setq clinfo (get-clause-info))
    (setq target-functor (car clinfo))
    (setq target-arity (cdr clinfo))
    (setq backward-predicate-end (point))
    (goto-char backward-predicate-beginning)

    (forward-line -1)			; was (previous-line 1) (BT)
    (while (and continue
                (not saw-first-clause)
                (not (error-occurred
                      (setq saw-first-clause (find-potential-clause))
		      (setq prevpoint (point))
                      (setq clinfo (get-clause-info))))
                )
      (if (and (string-equal (car clinfo) target-functor) 
               (= (cdr clinfo) target-arity))
          (progn 
            (setq backward-predicate-beginning prevpoint)
	    (goto-char prevpoint)
            (forward-line -1))		; was (previous-line 1) (BT)
        (setq continue nil)
        )
      )
    
    (goto-char backward-predicate-end)
    (setq continue t)
    (while (and continue
                (not (error-occurred (setq clinfo (get-clause-info)))))
      (if (and (string-equal (car clinfo) target-functor)
               (= (cdr clinfo) target-arity))
	  (setq backward-predicate-end (point))
        (setq continue nil))
      )
    (cons backward-predicate-beginning backward-predicate-end)
    )
  )

(defun forward-to-clause-end  (term-start)
  (let ((continue t)
        (token-type (next-token)))
    (while continue
      (cond 
       ((string-equal token-type "eof")
        (goto-char term-start)
        (BadFind "Can't find the end of this term"))
       ((string-equal token-type "stop")
        (setq continue nil))
       (t (setq token-type (next-token)))))))

(defun arity-overhead-for-grammar-rule  (term-start)
  (let (origpoint token-type token return)
    (setq origpoint (start-of-token))
    (setq token-type (next-token))
    (setq token (buffer-substring origpoint (point)))
    (cond 
     ((string-equal token ":-")
      (forward-to-clause-end term-start)
      (setq return 0))
     ((string-equal token-type "stop")
      (setq return 0))
     (t(if (grammar-rule token-type token)
	   (progn 
	     (forward-to-clause-end term-start)
	     (setq return 2))
	 (goto-char term-start)
	 (BadFind "Can't determine what type of clause this is"))))
    return))

(defun BadFind (message)
  (sleep-for 0 10)
  (error message))

(defun grammar-rule  (mgr-token-type mgr-token)
  (let (return
	origpoint
        (continue t))
    (while continue
      (cond
       ((string-equal mgr-token "-->")
        (setq continue nil)
        (setq return t))
       ((or (string-equal mgr-token-type "stop")
            (string-equal mgr-token-type "eof"))
        (setq continue nil)
        (setq return nil))
        (t (setq origpoint (start-of-token))
	   (setq mgr-token-type (next-token))
	   (setq mgr-token (buffer-substring origpoint (point))))))
    return))

; 
; find-potential-clause() finds the first line less than or equal to the
; current line which has a non-layout character in the first column or the
; first column does not start a comment ('%' or '/*'), end a comment
; ('*/'), or is within a comment.
(defun find-potential-clause ()
  (let
      ((continue t)
       (original-dot (point))
       char 
       (return))
    (while continue
      (beginning-of-line)
      (setq char (following-char))
      (if (or (or (and (>= char ?\001) (<= char ?  )) (= char ?\177))  ; layout
	      (looking-at "%\\|/\\*\\|\\*/")  ; '%' or '/*' or '*/'
	      (within-comment)
	      (eobp))
          (if (not (bobp))
	      (previous-line 1)
	    (goto-char original-dot)
	    (BadFind "Cannot find a valid line to start the procedure, command or query"))
	(if (bobp) (setq return t))
	(setq continue nil)))
    return))

; As far as I can tell, this function expected you to be at the beginning of
; a clause. It assigned the variables *functor* and *arity* and set the point
; and mark around the clause. Is it Lispish to set global variables to return
; values? Is it Emacsish to set the mark programmatically?
; I am changing this to return a list of the functor and arity. Since the
; point was at the beginning of the clause when we came in, the caller knows
; where that is. All we need to do is to move to the end of the clause. 
(defun get-clause-info ()
  (let (term-start token-type token)
    (setq term-start (start-of-token))
    (setq token-type (next-token))
    (cond 
     ((string-equal token-type "atom")
      (setq token (buffer-substring term-start (point)))
      (if (and (not (string-equal token ":-"))
	       (not (string-equal token "?-")))
	  (cons token (arity-overhead-for-grammar-rule term-start))
	(forward-to-clause-end term-start)
	(cons token 1)))
     ((string-equal token-type "functor")
      (setq token (buffer-substring term-start (point))) ; BT
      (cons token (all-arity term-start)))
     ((string-equal token-type "eof")
      (cons "end_of_file" -1))
     (t (BadFind "Wrong term type to start clause, command, or query")))))

(defun BadArity (message)
  (error message))

(defun all-arity (term-start)
  (let ((temp-arity (head-arity)))
    (+ temp-arity (arity-overhead-for-grammar-rule term-start))))

; 
; This function assumes that you are looking at the left parenthesis
; immediately following the atom of a complex predicate.  It knows that
; it's looking at the parenthesis because the tokenizer looks ahead to
; it, '(', to determine that it is just read a "functor" instead of just an 
; "atom".
;	    foo(X,Y) ...
;	       ^
; 

(defun head-arity ()
  (let  ((state 0)
         (stack)
         (arity 1)
         token-type
         token
	 origpoint
         (original-dot (point)))

    (if (= (following-char) ?\( )
	(forward-char)
      (BadArity "Can't start calculating arity at this point"))

    (while (not (= state 2))
      (setq origpoint (start-of-token))
      (setq token-type (next-token))
      (setq token (buffer-substring origpoint (point)))

      (if (or (string-equal token-type "stop")
              (string-equal token-type "eof"))
          (progn 
            (goto-char original-dot)
            (BadArity "Unclosed parenthesis.")))
      (cond ((= state 0)
	     (cond ((string-equal token "(")
		    (setq stack (cons ")" stack))
		    (setq state 1))
		   ((string-equal token "[")
		    (setq stack (cons "]" stack))
		    (setq state 1))
		   ((string-equal token "{")
		    (setq stack (cons "}" stack))
		    (setq state 1))
		   ((string-equal token ")")
		    (setq state 2))
		   ((or (string-equal token "]") (string-equal token "}"))
		    (BadArity "Mismatched parentheses."))
		   ((string-equal token ",")
		    (setq arity (+ arity 1)))))
	    ((= state 1)
	     (cond
	      ((string-equal token "(") (setq stack (cons ")" stack)))
	      ((string-equal token "[") (setq stack (cons "]" stack)))
	      ((string-equal token "{") (setq stack (cons "}" stack)))
	      ((or (string-equal token ")") 
		   (string-equal token "]") 
		   (string-equal token "}"))
	       (if (not (string-equal (car stack) token))
		   (BadArity "Mismatched parentheses."))
	       (setq stack (cdr stack))
	       (if (null stack)
		   (setq state 0)))))))
    arity))

(defun within-comment ()
  (let ((original-dot (point)) (return))
    (if (not (re-search-backward "/\\*\\|\\*/" nil t)) ; '/*' or '*/'
        (setq return nil)
      (if (= (following-char) ?*)      ; found '*/'
	  (progn 
	    (goto-char original-dot)
	    (setq return nil)
	    )
	(goto-char original-dot)
	(setq return (search-forward "*/" nil t))
	(goto-char original-dot)))
    return))
