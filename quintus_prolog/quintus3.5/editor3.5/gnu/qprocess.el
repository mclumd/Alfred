;;; SCCS: @(#)qprocess.el	76.2 04/28/03
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

;; [PM] 2003-04-24 Used to rely on one of the other definitions
(defmacro qprocess-error-occurred (&rest body)
  (list 'condition-case 'qp-error-condition
        (cons 'progn 
              (append body '(nil)))
        ;; [PM] 2003-04-24 debug (harmless)
        ;; Will only affect macro-expansion if qp-emacs-debug was bound at compile time
        (if (boundp 'qp-emacs-debug)
            '(error (and (boundp 'qp-emacs-debug) qp-emacs-debug (message "qprocess-error-occurred trapped error: %S" qp-error-condition)) t)
          '(error t))
        ))

;; [PM] 2004-04-24 FIXME: debug version (should be harmless unless qp-emacs-debug is set though.
(defmacro qprocess-error-occurred (&rest body)
  (if (and (boundp 'qp-emacs-debug) qp-emacs-debug)
      `(progn (progn . ,body) nil)      ; [PM] 2004-04-24 do not protect against error if debugging
    `(condition-case qp-error-condition
         (progn (progn
                  . ,body)
                nil)
       ;; [PM] 2003-04-24 debug (harmless)
       ;; Will only affect macro-expansion if qp-emacs-debug was bound at compile time
       ,(if (boundp 'qp-emacs-debug)
            '(error (and (boundp 'qp-emacs-debug) qp-emacs-debug (message "qprocess-error-occurred trapped error: %S" qp-error-condition)) t)
          '(error t))
       )))

(defvar *prolog-term-reading-mode* t)

(defun white-space-only ()
  (save-excursion
    (goto-char 
      (process-mark (get-buffer-process (current-buffer))))
    (looking-at "[\001- \177]*\\'")))

(defun prolog-newline ()
  "Send input to prolog process. At end of buffer, sends all text after last
output as input to the prolog process, including a newline inserted at the
end."
  (interactive)
  (end-of-line)
  (cond ((<= (point)
	     (process-mark (get-buffer-process (current-buffer))))
	 (comint-send-input))
	((or (not *prolog-term-reading-mode*)
	     (clause-end-p))
	 (comint-send-input))
	(t (cond ((white-space-only)   ;  print prompt
		  (comint-send-input))
		 (t (insert-string "\n     "))))))

; This flag is set to true only if in the middle of processing a packet.
(defvar *packet-pending* nil)   ; Set the flag to its default position.

(defconst *begin-packet-char* 30)
(defconst *end-packet-char* 29)
(defvar *packet-buffer* nil)

(defconst *begin-packet-string* (char-to-string *begin-packet-char*))
(defconst *end-packet-string* (char-to-string *end-packet-char*))
(defconst *packet-control-string* (concat *begin-packet-string* "\\|"
                                          *end-packet-string*))
(defun prolog-process-filter (process packet)
  (process-packets packet process)
  (display-any-messages))
    
(defun process-packets (packet process)
  (let ((packet-control (string-match *packet-control-string* packet)))
    (if *packet-pending*
	(cond 
	 ((not packet-control) 
	  (setq *packet-buffer* (concat *packet-buffer*  packet)))
	 ((string-equal 
	   (substring packet packet-control (1+ packet-control))
	   *end-packet-string*)
	  (process-prolog-packets
	   (concat *packet-buffer*
		   (substring packet 0 packet-control)))
	  (setq *packet-buffer* "")
	  (setq *packet-pending* nil)
	  (process-packets 
	   (substring packet (1+ packet-control)) process))
	 (t
	  (setq *packet-pending* nil)
	  (&qp-message "New packet arrived before end of old one")
	  (setq *packet-buffer* "")
	  (process-packets
	   (substring packet (1+ packet-control))
	   process)))
      ;; else
      (cond 
       ((not packet-control)
	(save-excursion
	  (set-buffer (process-buffer process))
	  (goto-char (point-max))
	  (let ((now (point)))
	    (insert packet))
	  (if (process-mark process)
	      (set-marker (process-mark process) (point))))
	(if (eq (process-buffer process) (current-buffer))
	    (goto-char (point-max))))
       ((string-equal 
	 (substring packet packet-control (1+ packet-control)) 
	 *end-packet-string*)
	(&qp-message "Found end of packet which was not started")
	(setq *packet-buffer* "")
	(process-packets (substring packet (1+ packet-control)) process))
       (t
	(if (> packet-control 0)
	    (progn
	      (save-excursion
		(set-buffer (process-buffer process))
		(goto-char (point-max))
		(let ((now (point)))
		  (insert (substring packet 0 packet-control))
		  (if (process-mark process)
		      (set-marker (process-mark process) (point))))
		(if (eq (process-buffer process) (current-buffer))
		    (goto-char (point-max))))))
	(setq *packet-pending* t)
	(process-packets
	 (substring packet (1+ packet-control)) process))))))

; standard packet types that are very frequently given are indicated
; by a single letter, otherwise, the packet routine is simply the name
; of the Emacs-Lisp routine to be executed.

(defun process-prolog-packets (packet)

  (and (boundp 'qp-emacs-debug)         ; [PM] 2003-04-24 debug (harmless)
       qp-emacs-debug
       (setq qp-packets  (cons packet (and (boundp 'qp-packets) qp-packets))))

  (let ((packet-type (substring packet 0 1)))
    (cond    
     ((string-equal packet-type "a") (setq *prolog-term-reading-mode* t))
     ((string-equal packet-type "d")
      (setq global-mode-string 
	    (append original-mode-string 
		    (list (strip-module packet))))
      (cond 
       ((string-match "debug" packet)
        (setq mode-line-format 
              "--%1*%1*-Emacs: %b   %M *Debug*   %[(%m: %s)%]----%3p--%-"))
       ((string-match "trace" packet)
        (setq mode-line-format 
              "--%1*%1*-Emacs: %b   %M *Trace*  %[(%m: %s)%]----%3p--%-"))
       (t
        (setq mode-line-format 
              "--%1*%1*-Emacs: %b   %M          %[(%m: %s)%]----%3p--%-")))
      (set-buffer-modified-p (buffer-modified-p)))
     ((string-equal packet-type "m") (&qp-message (substring packet 1)))
     (t (if (qprocess-error-occurred (eval (read packet)))
            (progn 
	      (&qp-message 
	       (concat "Lisp packet could not execute: " packet))))))))

;-----------------------------------------------------------------------

(defun send-prolog (query)

  ;; [PM] 2003-04-25 FSF Emacs comint-send-string does not work if
  ;; argument is the name of a process. (This could be worked around
  ;; but then we should change to comint-send-string everywhere).
  (process-send-string "prolog"          ; [PM] 2003-04-24 was send-string

               (concat "\^]" query " .\n")))

;; Function not used

(defun send-prolog-directly (string)
  (&clear-message)
  (setq *prolog-term-reading-mode* nil)
  (setq @at-debugger-prompt nil)
  ;; [PM] 2003-04-25 FSF Emacs comint-send-string does not work if argument is the name of a process
  (process-send-string "prolog" string)) ; [PM] 2003-04-24 was send-string

; mode-line support function
(defun strip-module (packet)
  (let (mod-pos)
    (cond ((setq mod-pos (string-match "Module:" packet))
	   (concat "Module:" (substring packet (+ mod-pos 7) (+ mod-pos 17))))
	  (t nil))))

(defun prolog-update-goal-history (current)
  (setq prolog-goal-history
	(if prolog-goal-history-nodup
	    (cons current (delete-string-from-list
			    current prolog-goal-history))
	    (cons current prolog-goal-history))))

(defun delete-string-from-list (string list)
  (cond ((null list) nil)
	((string-equal string (car list)) (cdr list))
	(t (cons (car list)
		 (delete-string-from-list string (cdr list))))))

; -------------------------------------------------------------------------
; clause-end-p looks to see if we are a the end of a clause, i.e. we are
; positioned after a "." which is not preceded by an agglutinating character.
; -------------------------------------------------------------------------

(defun clause-end-p ()
  (if (/= (preceding-char) 46)   ; a "."
      nil
    (backward-char)
    (if (agglutinating-charp (preceding-char))
	nil
      (forward-char)
      t)))

(defun agglutinating-charp  (char)
  (or (= char 36) (= char 38) (= char 42) (= char 43) (= char 45) ; |
      (= char 46) (= char 47) (= char 58) (= char 60) (= char 61)
      (= char 62) (= char 63) (= char 64) (= char 92) (= char 94)
      (= char 96) (= char 126) (= char 35)))

;----------------------------------------------------------------------------
; The following routines are used to properly handle message display
;  for the routines which talk to the Emacs interface from Prolog

(defvar *qpmess-buffer* " ")

(defun &qp-message (message)
  (setq *qpmess-buffer* message))

(defun display-any-messages ()
  (if (not (string-equal *qpmess-buffer* ""))
      (message *qpmess-buffer*))
  (sit-for 0)
  (&clear-message))

(defun &clear-message ()
  (setq *qpmess-buffer* ""))

(defun &no-message ()
  (setq *qpmess-buffer* ""))



