;;; SCCS: @(#)qpcommands.el	76.2 04/28/03
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
;;; This interface was made possible by contributions from Fernando
;;; Pereira and various customers of Quintus Computer Systems, Inc.,
;;; based on code for Quintus's Unipress Emacs interface. 
;;; 

; ----------------------------------------------------------------------
;                    Incremental reconsulting
; ----------------------------------------------------------------------

(defmacro error-occurred (&rest body)
  (list 'condition-case nil (cons 'progn (append body '(nil))) '(error t)))

(defun ensure-prolog-is-running ()	; could be better (BT)
  (if (not (comint-check-proc "*prolog*"))
      (error "No Prolog process available")))

(defun prolog-compile ()
  (interactive)
  (ensure-prolog-is-running)
  (if (not (safe-to-call-prolog))
      (error "Cannot load unless Prolog is at top-level prompt"))
  (sleep-for 1)
  (message
   "compile Prolog... enter p for procedure, r for region or b for buffer ")
  (send-load-to-prolog (read-char)))

(defun safe-to-call-prolog ()
  (or *prolog-term-reading-mode*  @at-debugger-prompt))

; ----------------------------------------------------------------------

(defvar *term-reading-mode-before-^C* nil)

(defun send-load-to-prolog  (load-char)
  (let (extent (file-name (expand-file-name (buffer-file-name))))
    (cond
     ((= load-char ?p)
      (save-excursion
        (message "Please Wait, finding predicate boundaries...")
        (sit-for 0)
	(let ((predends (find-pred)))
	  (write-region (car predends) (cdr predends) prolog-zap-file))
	(setq extent "procedure")))
     ((= load-char ?r)
      (write-region (point) (mark) prolog-zap-file)
      (setq extent "region"))
     ((= load-char ?b)
      (write-region (point-min) (point-max) prolog-zap-file)
      (setq extent "buffer"))
     (t (error "Bad option")))
    (pop-to-buffer "*prolog*")
    (goto-char (process-mark (get-buffer-process "*prolog*")))
    (setq *prolog-term-reading-mode* nil)
    (message (concat "Compiling " extent "..."))
    (sit-for 0)
    (&clear-message)
    (send-prolog
     (concat "'$editor_load_code'('" extent "','" file-name "')"))))

(defun interrupt-prolog ()
  (interactive)
  (&clear-message)
  (progn
    (setq *term-reading-mode-before-^C* *prolog-term-reading-mode*)
    (setq *prolog-term-reading-mode* nil)
    (setq @at-debugger-prompt nil)
    (comint-interrupt-subjob)))
	
(defun @restore-term-reading-mode ()
  (setq *prolog-term-reading-mode*
	*term-reading-mode-before-^C*))

; ---------------------------------------------------------------------
; 		  	   Find Definition
; ---------------------------------------------------------------------

(load "qpcommon")

(defvar *functor* 0)
(defvar *arity* 0)
(defvar *env*)
(defvar *print-name* "")
(defvar *already-saw-last-file* t)
(defvar *called-from-@find* nil)
(defvar *prolog-term-reading-mode* t)

(defun find-definition  ()
  "Find the definition of a predicate that has been  loaded into Prolog"
  (interactive)
  (@fd-clear)
  (if (not (safe-to-call-prolog))
      (error "Cannot find definition unless Prolog is at top level prompt"))
  (let ((namearity (query-user-for-predicate "Find:")))
    (setq *functor* (car namearity))
    (setq *arity* (cdr namearity))
    (message (concat "Please Wait, looking for predicate: " *functor*
			 (if (/= *arity* -1)
			     (concat "/" (int-to-string *arity*))) ; [PM] 2003-04-24 do not pass integers to concat
			 "..."))
    (sit-for 0)
    (send-prolog (concat  "find_predicate1(("  *functor* "),"
			  (if (= *arity* -1)
			      "NoArity"
			    (int-to-string *arity*)) ; [PM] 2003-04-24 do not pass integers to concat
			  ")" ))))

; ----------------------------------------------------------------------

(defun @find  (&optional flag env)
  (setq flag (or flag (read-string "Flag: ")))
  (setq *env* (or env (read-string "Env: "))) ; BT paren around read-string
  (setq *print-name* 
        (if (= *arity* -1)
            *functor*
          (concat *functor* "/" (int-to-string *arity*))) ; [PM] 2003-04-24 do not pass integers to concat
	)
  (cond 
   ((string-equal flag "built_in")
    (&qp-message (concat *print-name* " is a built-in predicate")))
   ((string-equal flag "undefined")
    (&qp-message (concat *print-name* " is undefined")))
    ((string-equal flag "none")	
     (&qp-message (concat *print-name* " has no file(s) associated with it")))
    ((string-equal flag "ok")
     (setq *already-saw-last-file* nil)
     (setq *called-from-@find* t)
     (find-more-definition))
    (t &qp-message (concat "Find definition error: " flag))))


(autoload 'push-tag-mark "etags")	; not defined in etags.el (BT)

(defun find-more-definition  ()
  (interactive)
  (if *already-saw-last-file*
      (conditional-message "find-definition \"ESC .\" must be used first")
    (if (fd-buffer-empty "*find-def*")
        (progn 
          (setq *already-saw-last-file* t)
          (conditional-message 
           (concat *print-name* " has no more source files")))
      (let ((fmd-file-name (fd-get-filename "*find-def*")) fmd-message)
        (if (string-equal fmd-file-name "user")
            (setq fmd-message (concat *print-name*
                                      " was defined in pseudo-file 'user'"))
          (progn
            (condition-case nil
                (progn
; BT              (push-tag-mark)    ; see the comment on the autoload above
		  (push-mark)	     ; to make "C-x C-x" work (BT)
                  (find-file fmd-file-name)
                  (setq fmd-message
                        (locate-definition *functor* *arity* *print-name*))
                  (if (string-equal *env* "debug")
                      (pop-to-buffer "*prolog*" nil)))
              (error
               (setq fmd-message
                     (concat *print-name*
                             " was defined in "
                             fmd-file-name 
                             ", but the file no longer exists"))))))
        (if (fd-buffer-empty "*find-def*")
            (if (string-equal fmd-message "")
                (setq fmd-message " "))
          (if (string-equal fmd-message "")
              (setq fmd-message "Type ESC , for more")
            (setq fmd-message
                  (concat fmd-message ", type ESC , for more"))))
        (conditional-message fmd-message))))
  (setq *called-from-@find* nil))

(defun @fd-clear ()
  (let ((buf (get-buffer-create "*find-def*")))
    (save-excursion
      (set-buffer buf)
      (erase-buffer))))

(defun @fd-in (file)
  (save-excursion
    (set-buffer "*find-def*")
    (end-of-buffer)
    (insert-string (concat file "\n"))))


; ---------------------------------------------------------------------
; 		  	   Change Directory
; ---------------------------------------------------------------------

;;
;  Trap M-x cd, pass all others
;;

(defun meta-x-trap (cmd)
  (interactive "CM-x ")
  (cond ((string-equal cmd "cd")
	 (call-interactively 'prolog-cd))
	(t (call-interactively cmd))))

(defun prolog-cd  (cd-path)
  (interactive "DChange default directory: ") ; it was 1 line below
  (ensure-prolog-is-running)
  (if (not (safe-to-call-prolog))
      (error "Cannot cd unless Prolog is at the top-level prompt"))
  (if (string-equal cd-path "")
      (setq cd-path (getenv "HOME"))
    (sit-for 0)
    (&no-message)
    (send-prolog (concat "unix(cd('" cd-path "'))"))))

;
; This function is only called by Prolog
;

(defun @cd  (path prolog-success)
  (cond ((not (zerop prolog-success))
	 (condition-case nil
	     (progn
	       (cd path)
	       (&qp-message (concat "Current directory now: " path)))
	   (error
	    (&qp-message
	     (concat 
	      "Prolog did, but Emacs did not change current directory to: " 
		path)))))
	(t (&qp-message
	    (concat 
	     "Neither Prolog nor Emacs changed current directory to: " 
	     path)))))  

; ---------------------------------------------------------------------
; 		  	   Library
; ---------------------------------------------------------------------

;The command "<ESC>-x library" supports the library directory package 
; of version 1.5

(defun library  ()
  (interactive)
  (cond ((bufferp (get-buffer "*prolog*"))
	 (if (not (safe-to-call-prolog))
	     (error 
	      "Cannot find library unless Prolog is at top level prompt"))
	 (let* ((lib-file (read-string "Library name: "))
		(mess (concat
		       "Please Wait, looking for library file: "
		       lib-file
		       "..." )))
	   (message mess)
	   (sit-for 0)
	   (&qp-message mess)
	   (send-prolog (concat "find_library_package((" lib-file "))"))))
	((bufferp (get-buffer "*qui-emacs*"))
	 (error "Emacs Invoked from QUI: library not a valid command"))
	(t (error "Invalid command"))))
	
(defun @lib  (lib-file)
  (if (string-equal
       lib-file
       "cannot find library file, check facts for library_directory/1")
      (&qp-message lib-file)
    (find-file-other-window lib-file)
    (&clear-message)))

(defun @debug ()
  (setq *prolog-term-reading-mode* nil)
  (setq @at-debugger-prompt t))

(defun spy ()
  (interactive)
  (@fd-clear)
  (ensure-prolog-is-running)
  (if (not (safe-to-call-prolog))
      (error "Cannot ""spy"" unless Prolog is at top level prompt"))
  (let ((namearity (query-user-for-predicate "Spy:")))
    (send-prolog (concat "spy " (car namearity)
			 (if (>= (cdr namearity) 0)
			     (concat "/" (int-to-string (cdr namearity)))))))) ; [PM] 2003-04-24 do not pass integers to concat

(defun nospy ()
  (interactive)
  (@fd-clear)
  (ensure-prolog-is-running)
  (if (not (safe-to-call-prolog))
      (error "Cannot ""nospy"" unless Prolog is at top level prompt"))
  (query-user-for-predicate "Nospy:")
  (let ((namearity (query-user-for-predicate "Spy:")))
    (send-prolog (concat "nospy " (car namearity)
			 (if (>= (cdr namearity) 0)
			     (concat "/" (int-to-string (cdr namearity)))))))) ; [PM] 2003-04-24 do not pass integers to concat

; This function returns a "name" or "name/arity" which becomes
; the default for find-definition, spy and nospy.
(defun default-predicate-prompt ()
  (let (token-type token)
    (save-excursion;; # added for FCP 
      (if (not (re-search-backward "[][?\001- \"%(#),{|}?\177]" nil t))
	  (beginning-of-buffer)
	(forward-char))
      (condition-case nil 
	  (let (token1 token1-type origpoint)
	    (setq origpoint (start-of-token))
	    (setq token-type (next-token))
	    (setq token (buffer-substring origpoint (point)))
	    (cond 
	     ((string-equal token-type "atom")
	      (setq origpoint (start-of-token))
	      (setq token1-type (next-token))
	      (setq token1 (buffer-substring origpoint (point)))
	      (cond
	       ((string-equal token1 "/")
		(setq origpoint (start-of-token))
		(setq token1-type (next-token))
		(setq token1 (buffer-substring origpoint (point)))
		(if (string-equal token1-type "integer")
		    (concat token "/" (format "%s" token1)) ; [PM] 2003-04-24 do not pass integers to concat (format instead of int-to-string fro safety)
		  token))
	       ((string-equal token1 "-->")
		(concat token "/" "2")) ; [PM] 2003-04-24 do not pass integers to concat
	       (t (concat token "/" "0")))) ; [PM] 2003-04-24 do not pass integers to concat
	     ((string-equal token-type "functor")
	      (let ((arity (head-arity)))
		(setq origpoint (start-of-token))
		(next-token)
		(if (string-equal (buffer-substring origpoint (point)) "-->")
		    (concat token "/" (int-to-string (+ arity 2))) ; [PM] 2003-04-24 do not pass integers to concat
		  (concat token "/" (int-to-string arity))))) ; [PM] 2003-04-24 do not pass integers to concat
	     (t nil)))
	(error	nil)))))
