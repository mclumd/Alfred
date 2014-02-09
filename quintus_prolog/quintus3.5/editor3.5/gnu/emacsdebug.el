;;; SCCS   : @(#)emacsdebug.el	1.2 04/28/03
;;; File   : emacsdebug.el
;;; Authors: Peter Schachte
;;; Purpose: Source-linked debugger for Quintus Prolog (Emacs version)
;;; Origin : January 1999
;;;
;;;     +--------------------------------------------------------+
;;;     | WARNING: This material is CONFIDENTIAL and proprietary |
;;;     |          to the Swedish Institute of Computer Science. |
;;;     |                                                        |
;;;     |  Copyright (C) 1999 Swedish Institute of Computer      |
;;;	|  Science.  All rights reserved.                        |
;;;     |                                                        |
;;;     +--------------------------------------------------------+

(require 'ehelp)

(defun enable-prolog-source-debugger ()
  "Enable the emacs-based Prolog source-linked debugger."
  (interactive)
  ;; [PM] 3.5 was quintus('editor3.4/gnu/emacsdebug')
  (send-prolog "use_module(library(emacsdebug)), emacs_debugger(_,on)")) ; benko


(defun disable-prolog-source-debugger ()
  "Disable the emacs-based Prolog source-linked debugger."
  (interactive)
  ;; [PM] 3.5 was quintus('editor3.4/gnu/emacsdebug')
  (send-prolog "use_module(library(emacsdebug)), emacs_debugger(_,off)")) ; benko


;;; NB:  commands whose meanings have been assigned:
;;;      abcdef h   l n pqrs   wx z   @+-?=<#[]|
;;; Not yet implemented:
;;;         de          p             @    <#
;;; Not yet used:
;;;            g ijk m o    tuv  y    `~!$%^&*()_{}\;:'",.>/

;;; These are the commands I'd like to supply, but I haven't had time
;;; to implement all of them.
;(defvar prolog-debug-help-string 
;  "Commands available in prolog debugger windows:
;  c  creep          e  raise exception   @  command     w  open extra window
;  l  leap           +  spy goal/pred     b  break       x  close extra window
;  s  skip           -  nospy goal/pred   a  abort       <  set print depth
;  z  zip            [  frame up          ?  help        p  toggle portraying
;  n  nonstop        ]  frame down        h  help        d  toggle operators
;  q  quasi-skip     |  frame back        =  debugging   #  toggle number vars
;  r  retry
;  f  fail")


(defvar prolog-debug-help-string 
  "Commands available in prolog debugger windows:
  c  creep         RET creep            SPC creep       w  open extra window
  l  leap           +  spy goal/pred     b  break       x  close extra window
  s  skip           -  nospy goal/pred   a  abort                         
  z  zip            [  frame up          ?  help        .  edit definition
  n  nonstop        ]  frame down        h  help                             
  q  quasi-skip     |  frame back        =  debugging                        
  r  retry
  f  fail")


(defvar prolog-debug-buffer-var nil 
  "The Quintus Prolog debugger buffer")

(defvar prolog-debug-current-source-file nil
  "The file currently displayed in the source debugging buffer, or nil.")

(defvar prolog-debug-map nil
  "Keymap for debugger source code window")

(if prolog-debug-map 
    nil
  (setq prolog-debug-map (make-keymap))
  (let ((keyletter))
    (setq keyletter ? )
    (while (<= keyletter ?~)
      (define-key prolog-debug-map
	(char-to-string keyletter)
	'prolog-debug-command)
      (setq keyletter (1+ keyletter))))
  (define-key prolog-debug-map "\r" 'prolog-debug-command)
  (define-key prolog-debug-map "\n" 'prolog-debug-command)
  (define-key prolog-debug-map "h" 'prolog-debug-help)
  (define-key prolog-debug-map "?" 'prolog-debug-help)
  (define-key prolog-debug-map "w" 'prolog-debug-open-window)
  (define-key prolog-debug-map "x" 'prolog-debug-close-window)
  (define-key prolog-debug-map "." 'prolog-debug-edit-source)
)

(defvar prolog-debug-is-waiting nil
  "If non-nil, the debugger is waiting for a command.")

(defvar prolog-debug-window nil
  "The name of a debugger buffer.")
(defvar prolog-debug-window-string nil
  "The name of a debugger buffer as a string.  Used in mode lines.")
(defvar prolog-debug-window-letter nil
  "The letter identifying the current debugger buffer's window to prolog.")


(defun prolog-debug-buffer ()
  "Returns the Quintus Prolog debugger buffer, creating it if necessary."
  (or (and prolog-debug-buffer-var
           (buffer-live-p prolog-debug-buffer-var) ; [PM] 2003-04-24
           prolog-debug-buffer-var)
      (save-excursion
	(set-buffer (setq prolog-debug-buffer-var
			  (get-buffer-create "*prolog source*")))
	(prolog-debug-initialize-buffer 'source)
	(setq mode-name "Prolog: source")
	(setq prolog-debug-window-letter "!")
	(make-local-variable 'arrow-position)
	prolog-debug-buffer-var)))


(defun &qp-error (message)
  "Report an error."
  (&qp-message message)
  (beep))


(defun prolog-debug-source (file)
  "Load file in preparation for source debugging."
  (prolog-debug-load file file))


(defun prolog-debug-no-source (file)
  "Load and delete temp file in preparation for source debugging."
  (prolog-debug-load file "")
  (delete-file file))


(defun prolog-debug-extra (window file append)
  "Load file in preparation for source debugging."
  (let ((buf (prolog-debug-open window)))
    (save-excursion
      (set-buffer buf)
      (prolog-debug-load-buffer file append)
      (delete-file file))))


(defun prolog-debug-load (file sourceof)
  "Load file in preparation for source debugging."
  (set-buffer (prolog-debug-buffer))
  (prolog-debug-load-buffer file nil)
  (setq prolog-debug-current-source-file sourceof)
  (setq arrow-position nil))


(defun prolog-debug-load-buffer (file append)
  "Load the file into the current buffer and mark unchanged and readonly"
  (setq buffer-read-only nil)
  (goto-char (point-max))
  (condition-case nil			; benko
      (insert-file-contents-literally file nil nil nil (not append))
    ('error (insert-file-contents file nil nil nil (not append))))
  (condition-case nil			; benko
      (standard-display-ascii 13 "")
    ('error t))
  (set-buffer-modified-p nil)
  (setq buffer-read-only t))


(defun prolog-debug-port (start end alternate depth port module name arity extra1 extra2)
  "We've arrived at port of a call to module:name/arity at depth.  The source
code of the call begins at byte start of the Prolog Debug buffer and ends at 
end.  For a Head port, alternate indicates the position of the next clause
to be tried.  extra1 and extra2 give extra information about the call."
  (pop-to-buffer (prolog-debug-buffer))
  (let (pos arrow)
    (cond ((eq port 'Call) (setq pos start) (setq arrow "->"))
	  ((eq port 'Done) (setq pos end) (setq arrow "->"))
	  ((eq port 'Exit) (setq pos end) (setq arrow "=>"))
	  ((eq port 'Redo) (setq pos end) (setq arrow "<-"))
	  ((eq port 'Fail) (setq pos start) (setq arrow "<-"))
	  ((eq port 'Exception) (setq pos start) (setq arrow "<#"))
	  ((eq port 'Head) (setq pos start) (setq arrow "=>"))
	  ((eq port 'LastHead) (setq pos start) (setq arrow "->"))
	  ((eq port 'Ancestor) (setq pos start) (setq arrow "^>"))
	  (t (&qp-error (format "unknown debugger port:  %s" port))))
    (setq buffer-read-only nil)
    (if arrow-position
	(progn (goto-char arrow-position)(delete-char 2)))
    (goto-char (setq arrow-position pos))
    (insert arrow)
    (setq buffer-read-only t)
    (backward-char 2))
  (&qp-message (concat (int-to-string depth) ; [PM] 2003-04-24 do not pass integers to concat
                       ": " (symbol-name port) "  " 
		       (if (string-equal extra1 "") ""
			 (concat "(" extra1 ") "))
		       module 
		       (if (string-equal module "") "" ":")
		       name "/" (int-to-string arity)))) ; [PM] 2003-04-24 do not pass integers to concat


(defun prolog-debug-waiting ()
  "The QP source debugger is waiting for a command from emacs."
  (setq prolog-debug-is-waiting t)
  (pop-to-buffer (prolog-debug-buffer))
)

(defun prolog-debug-open (window)
  "Open the named prolog debugger window"
  (let ((actualbuf
	 (cond ((eq window 'source)
		(prolog-debug-buffer))
	       (t (let* ((name (concat "*prolog " (symbol-name window) "*"))
			 (buf (get-buffer name)))
		    (or buf
			(let ((newbuf (get-buffer-create name)))
			  (save-excursion
			    (set-buffer newbuf)
			    (prolog-debug-initialize-buffer window)
			    newbuf))))))))
    (display-buffer actualbuf)
    actualbuf))


(defun prolog-debug-close (window)
  "Open the named prolog debugger window"
  (cond ((eq window 'source)
	 (kill-buffer (prolog-debug-buffer)))
	(t (let* ((name (concat "*prolog " (symbol-name window) "*"))
		  (buf (get-buffer name)))
	     (and buf (kill-buffer buf))))))


;;; Default mode-line-format:
;;;
;;; ("-" mode-line-mule-info mode-line-modified mode-line-frame-identification 
;;;  mode-line-buffer-identification "   " global-mode-string
;;   "   %[(" mode-name mode-line-process minor-mode-alist "%n" ")%]--"
;;;  (which-func-mode
;;;   ("" which-func-format "--"))
;;;  (line-number-mode "L%l--")
;;;  (column-number-mode "C%c--")
;;;  (-3 . "%p")
;;;  "-%-")


(defun prolog-debug-initialize-buffer (window)
  "Set up the current buffer as a prolog debugger buffer."
  (setq mode-line-modified nil)
  (setq mode-line-buffer-identification
	'("Prolog debugger: " prolog-debug-window-string))
  (use-local-map prolog-debug-map)
  (make-local-variable 'prolog-debug-window)
  (make-local-variable 'prolog-debug-window-string)
  (make-local-variable 'prolog-debug-window-letter)
  (setq prolog-debug-window-letter 
	(substring (setq prolog-debug-window-string
			 (symbol-name (setq prolog-debug-window
					    window)))
		   0 1)))



;;; The debugging commands

(defun prolog-debug-command ()
  "One-size-fits-all debugger command.  Prolog decides what the key
press means."
  (interactive)
  (prolog-debug-ensure-waiting)
  (process-send-string "prolog"
		       (concat
                        ;; [PM] 2003-04-24 this-command-keys on XEmacs is a list of _events_, not a string
                        ;; Instead put last-command-char into a string
                        ;; (this-command-keys) 
                        (char-to-string last-command-char)
			       prolog-debug-window-letter "\n"))
  (setq prolog-debug-is-waiting nil)
  (if (string-equal prolog-debug-current-source-file "")
      (prolog-debug-clear-window))
  (pop-to-buffer "*prolog*"))


(defun prolog-debug-ensure-waiting ()
  "Signal an error if Prolog is not waiting for user input."
  (if (not prolog-debug-is-waiting)
    (&qp-error "Prolog debugger is not waiting for a command")))


(defun prolog-debug-help ()
  "Display Prolog debugger help message"
  (interactive)
  (with-electric-help 'prolog-debug-print-help))


(defun prolog-debug-edit-source ()
  "Edit the source code of the file currently being debugged."
  (interactive)
  (if (null prolog-debug-current-source-file)
      (&qp-error "No source file to edit")
    (find-file prolog-debug-current-source-file)
    (let ((pos (save-excursion
		 (set-buffer prolog-debug-buffer-var)
		 (point))))
      (goto-char pos))))


(defun prolog-debug-print-help ()
  (princ prolog-debug-help-string)
  nil)

(defun prolog-debug-open-window (windowchar)
  "Open an \"extra\" prolog debugger window, prompting for which one."
  (interactive "cOpen which window?  b=bindings; s=standard; a=ancestors")
  (prolog-debug-window-state t windowchar))
          
(defun prolog-debug-close-window (windowchar)
  "Close an \"extra\" prolog debugger window, prompting for which one."
  (interactive "cClose which window?  b=bindings; s=standard; a=ancestors")
  (prolog-debug-window-state nil windowchar))
  
(defun prolog-debug-window-state (newstate windowchar)
  (prolog-debug-ensure-waiting)
  (let ((window (cdr (assoc windowchar '((?b . bindings)
					 (?s . standard)
					 (?a . ancestors))))))
    (if (null window)
	(&qp-error "Invalid character, please hit one of b, s, or a")
      (let ((char (substring (symbol-name window) 0 1)))
	(process-send-string "prolog"
			     (concat (if newstate "w" "x") char "\n"))))))


(defun prolog-debug-clear-window ()
  (save-excursion
    (set-buffer (prolog-debug-buffer))
    (setq buffer-read-only nil)
    (erase-buffer)
    (set-buffer-modified-p nil)
    (setq buffer-read-only t)
    (setq arrow-position nil)))
