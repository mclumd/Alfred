;;; SCCS: @(#)qui_cmds.el	76.2 04/28/03
;;;		      QUI - GNU Emacs Interface
;;;			  Support Functions
;;;
;;;		  Consolidated by Sitaram Muralidhar
;;;
;;;			 sitaram@quintus.com
;;;		    Quintus Computer Systems, Inc.
;;;			     12 Nov 1990
;;;
;;;    This file defines functions that support the QUI - GNU Emacs
;;;			      interface.

(provide 'qui_cmds)			; to clam the compiler (BT)
(require 'qui)

(defvar qui-zap-file (make-temp-name "/tmp/qui")
  "Temporary file name used for code being consulted or compiled in Qui.")
(defvar  " ")

(defun qui-compile ()
  (interactive)
  ;;  Need to check this, currently just sending things blindly to emacs
  (sleep-for 1)
  (message  
   "compile Prolog... enter p for procedure, r for region or b for buffer ")
  (send-load-to-qui (read-char)))

(defun send-load-to-qui  (load-char)
  (let (word (file-name (expand-file-name (buffer-file-name))))
    (cond 
     ((= load-char ?p)
      (save-excursion
        (message "Please Wait, finding predicate boundaries...")
        (sit-for 0)
	(let ((predends (find-pred)))
	  (write-region (car predends) (cdr predends) qui-zap-file)))
      (setq word "procedure")
;;; loadpred <size> filename <size> tmpfile
      (send-qui 
       (concat LOADPRED  (padded-length file-name) 
	       file-name  (padded-length qui-zap-file)  qui-zap-file)))
     ((= load-char ?r)
      (write-region (point) (mark) qui-zap-file)
      (setq word "region")
;;; loadregi <size> filename <size> tmpfile
      (send-qui 
       (concat LOADREGI  (padded-length file-name) 
	       file-name  (padded-length qui-zap-file)  qui-zap-file)))
     ((= load-char ?b)
      (write-region (point-min) (point-max) qui-zap-file)
      (setq word "buffer")
;;; loadregi <size> filename <size> tmpfile
      (send-qui 
       (concat LOADREGI  (padded-length file-name) 
	       file-name  (padded-length qui-zap-file)  qui-zap-file)))
     (t (error "Bad option")))
    (message (concat "Compiling " word "..."))
    (sit-for 0)
    (&clear-message)))

; ---------------------------------------------------------------------
; 		  	   Find Definition
; Most of this stuff is the same as the prolog-emacs interface, minor
; modifications have been made to accomodate the manner in which Emacs
; talks to QUI.
; ---------------------------------------------------------------------

(defvar   *qui-functor*               0)
(defvar   *qui-arity* 		      0)
(defvar   *qui-env*)
(defvar   *qui-print-name*           "")
(defvar   *qui-already-saw-last-file* t)
(defvar   *called-from-@find*       nil)

(defun find-qui-definition  ()
  (interactive)
  (@fd-clear)
;;; Currently blindly sending to qui
  (let ((namearity (query-user-for-predicate "Find:")))
    (setq *qui-functor* (car namearity))
    (setq *qui-arity* (cdr namearity))
    (message (concat "Please Wait, looking for predicate: "
		     *qui-functor*
		     (if (/= *qui-arity* -1)
			 (concat "/" (int-to-string *qui-arity*))) ; [PM] 2003-04-24 do not pass integers to concat
		     "..."))
    (sit-for 0)
; Send 	"finddef <size> functor <size> arity <size> module" to QUI
; No Module information available, "_NoModule_" sent to QUI.
    (send-qui (concat FINDDEF  (padded-length *qui-functor*)
		      *qui-functor*  
		      (if (= *qui-arity* -1)
			    (padded-length "-1") 
			    (padded-length (int-to-string *qui-arity*)))
		      (if (= *qui-arity* -1)
			  -1
			  (int-to-string *qui-arity*)) ; [PM] 2003-04-24 do not pass integers to concat
		      (padded-length NOMODULE)  NOMODULE))))
  
(defun find-more-qui-definition  ()
  (interactive)
  (if *qui-already-saw-last-file*
      (conditional-message "find-definition \"ESC .\" must be used first")
    (if (fd-buffer-empty "*qui-find-def*")
        (progn 
          (setq *qui-already-saw-last-file* t)
          (conditional-message 
           (concat *qui-print-name* " has no more source files")))
      (let ((fmd-file-name (fd-get-filename "*qui-find-def*")) fmd-message)
        (if (string-equal fmd-file-name "user")
            (setq fmd-message (concat *qui-print-name*
                                      " was defined in pseudo-file 'user'"))
          (progn
            (condition-case nil
                (let () 
;;                  (find-file-other-window fmd-file-name) ; chg starts (BT)
		  (push-mark)
		  (find-file fmd-file-name) ; chg ends (BT)
                  (setq fmd-message
                        (locate-definition *qui-functor* *qui-arity* *qui-print-name*))
                  (if (string-equal *qui-env* "debug")
                      (pop-to-buffer "*prolog*" nil)))
              (error
               (setq fmd-message
                     (concat *qui-print-name*
                             " was defined in "
                             fmd-file-name 
                             ", but the file no longer exists"))))))
        (if (fd-buffer-empty "*qui-find-def*")
            (if (string-equal fmd-message "")
                (setq fmd-message " "))
          (if (string-equal fmd-message "")
              (setq fmd-message "Type ESC , for more")
            (setq fmd-message
                  (concat fmd-message ", type ESC , for more"))))
        (conditional-message fmd-message))))
  (setq *called-from-@find* nil))

(defun @fd-clear ()
  (let ((buf (get-buffer-create "*qui-find-def*")))
    (save-excursion
      (set-buffer buf)
      (erase-buffer))))

(defun @fd-in (file)
  (save-excursion
    (set-buffer "*qui-find-def*")
    (end-of-buffer)
    (insert-string (concat file "\n"))))

;---------------------------------------------------------------------------
; Qui sends a list of Name-Arity-filename triples to emacs by calling
; founddef with the Functor, Arity, Module and Filename. On receiving
; an "enddef ", the "find" begins through the triples in *qui-find-def*.
;---------------------------------------------------------------------------

;;;
;;; Built-in definition
;;;

(defun builtin (functor arity module)
  (cond ((= (string-to-int arity) -1)
	 (setq *qui-print-name* functor))
	(t (setq *qui-print-name* (concat functor "/" (int-to-string arity)))) ; [PM] 2003-04-24 do not pass integers to concat
  )
  (&qp-message (concat *qui-print-name* " is a built-in predicate")))

;;;
;;; No definition for predicate
;;;

(defun nondef (functor arity module)
  (cond ((= (string-to-int arity) -1)
	 (setq *qui-print-name* functor))
	(t (setq *qui-print-name* (concat functor "/" (int-to-string arity)))) ; [PM] 2003-04-24 do not pass integers to concat
  )
  (&qp-message 
    (concat *qui-print-name* " has no file(s) associated with it")))

;;;
;;; Undefined predicate
;;; arg3 - functor, arg2 - arity, arg1 - module

(defun undef (functor arity module)
  (cond ((= (string-to-int arity) -1)
	 (setq *qui-print-name* functor))
	(t (setq *qui-print-name* (concat functor "/" (int-to-string arity)))) ; [PM] 2003-04-24 do not pass integers to concat
  )
  (&qp-message (concat *qui-print-name* " is undefined")))

;;;
;;; Look for first definition of predicate, signaled by enddef
;;;

(defun enddef ()
  (setq *qui-already-saw-last-file* nil)
  (setq *called-from-@find* 1)
  (cond ((= *qui-arity* -1)
	 (setq *qui-print-name* *qui-functor*))
	(t (setq *qui-print-name* (concat *qui-functor* "/" (int-to-string *qui-arity*))))) ; [PM] 2003-04-24 do not pass integers to concat
  (setq *qui-env* "")
  (find-more-qui-definition))

;;;
;;; edit-file - find-file file and goto-char pos
;;; arg2 is filename arg1 is pos
;;;

(defun edit-file (file pos)
  (find-file file)
  (cond ((= pos 0)
	 (goto-char (point-min)))
	(t (goto-char (1+ pos)))))

;;;
;;; fill find defns buffer - create one if necessary and write triples
;;; to it, this is repeatedly called by QUI to fill in definitions.
;;; arg4 is functor, arg3 - arity, arg2 - module, arg1 - filename

(defun fill-defns (functor arity module filename)
  (get-buffer-create "*qui-find-def*")
  (let ((triple (concat "\"" functor "\" " (int-to-string arity) space filename))) ; [PM] 2003-04-24 do not pass integers to concat
    (@fd-in triple)))

;;;
;;; Qui to quit
;;;

(defun qui-quit ()
  (cond ((get-buffer "*qui-find-def*")
	 (kill-buffer "*qui-find-def*")))
  (cond ((get-buffer "*temp*")
	 (kill-buffer "*temp*")))
  (message "Qui quitting, terminating qui-emacs interface "))

;;;
;;; Cantload
;;;

(defun cantload ()
  (message "Cannot load into prolog now")
  (sit-for 0))

;;;
;;; Cantccp
;;;

(defun cantccp ()
  (message "Cannot find definition now")
  (sit-for 0))
