;;; SCCS: @(#)qprolog-mode.el	76.6 08/07/03

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

(provide 'qprolog-mode)

(require 'quintaux)

(cond ((null (car global-mode-string))
       (setq global-mode-string (list ""))))
(defvar original-mode-string global-mode-string
  "The default mode line string when prolog starts up. Note that if the
mode string is changed after prolog is invoked the new setting will be lost")

(defvar qprolog-prompt-pattern "^|\\( *\\?- *\\|: *\\)")

(defvar prolog-zap-file
  (make-temp-name
   (let ((tmp (getenv "TEMP")))
     (if tmp (concat tmp "/qp") "/tmp/qp")))
  "Temporary file name used for code being consulted or compiled in Prolog.")

(defvar prolog-goal-history nil
  "List of recent goals executed by Quintus prolog.")

(defvar prolog-goal-history-nodup t
  "Flag to keep/eliminate duplicates from the Quintus prolog goal history.")

(defvar multiline-goal nil
  "Multiline goal executed by Quintus prolog.")

(defvar prolog-mode-syntax-table nil
  "Syntax table used while in prolog mode.")

(defvar prolog-mode-abbrev-table nil "")

(defvar quintus-gnu-version "3.5.0"
 " Quintus-GNU emacs interface version.")

(define-abbrev-table 'prolog-mode-abbrev-table ())

(defvar prolog-mode-map nil)

(if prolog-mode-map 
    nil
  (setq prolog-mode-map (make-sparse-keymap))
  (define-key prolog-mode-map "\t"     'prolog-indent-line       )
  (define-key prolog-mode-map "\e\C-q" 'prolog-indent-clause     )
  (define-key prolog-mode-map "\e\C-a" 'beginning-of-clause      )
  (define-key prolog-mode-map "\eh"    'mark-clause              )
  (define-key prolog-mode-map "\ef"    'forward-prolog-word      )
  (define-key prolog-mode-map "\eb"    'backward-prolog-word     )
  (define-key prolog-mode-map "\e\C-f" 'forward-term             )
  (define-key prolog-mode-map "\e\C-b" 'backward-term            )
  (define-key prolog-mode-map "\ed"    'kill-prolog-word         )
  (define-key prolog-mode-map "\e\177" 'backward-kill-prolog-word)
  (define-key prolog-mode-map "\e\C-k" 'kill-clause              )
  (define-key prolog-mode-map "\e\C-e" 'end-of-clause            )
  (define-key prolog-mode-map "\e."    'find-definition          )
  (define-key prolog-mode-map "\e,"    'find-more-definition     )
  (define-key prolog-mode-map "\ek"    'prolog-compile           )
  (define-key prolog-mode-map "\ei"    'prolog-compile           )
  (define-key prolog-mode-map "\e#"    'shell-filename-complete  )
)

(fset 'prolog-mode 'prolog-mode) 

(defun quintus-version ()
  (interactive)
  (message "Quintus-Gnu Emacs interface version %s" 
	   quintus-gnu-version))
  

(defun prolog-mode ()
  "Major mode for editing files of prolog code.
 The following commands are available:
 \\{prolog-mode-map}."

  (interactive)
  (kill-all-local-variables)
  (use-local-map prolog-mode-map)
  (setq mode-name "prolog")
  (setq major-mode 'prolog-mode)
  (setq local-abbrev-table prolog-mode-abbrev-table)
  (ensure-prolog-syntax)
  (prolog-mode-variables)
  (run-hooks 'prolog-mode-hook)
  )

;; [PM] 2003-08-07 This used to be set in ensure-prolog-syntax (and
;; differently for XEmacs and FSFEmacs)
(defconst prolog-font-lock-keywords
      '(("^[a-z$]+[a-zA-Z0-9_$]*" . font-lock-function-name-face)
	("\\(^\\|[^0-9]\\)\\('\\([^\n']\\|\\\\'\\)*'\\)" . font-lock-string-face)
	("\\(\"\\([^\n\"]\\|\\\\\"\\)*\"\\)" . font-lock-string-face)
	("\\<\\([_A-Z][a-zA-Z0-9_]*\\)" . font-lock-variable-name-face)
	("[][}{!;|]\\|\\*->" . font-lock-keyword-face)
	("[^-*]\\(->\\)" . font-lock-keyword-face)
	("\\<\\([a-z$]+[a-zA-Z0-9_$]*:\\|\\)[a-z$]+[a-zA-Z0-9_$]*/[0-9]+" . font-lock-function-name-face)
	("^[?:]- *\\(block\\|dynamic\\|mode\\|module\\|multifile\\|meta_predicate\\|parallel\\|public\\|sequential\\|volatile\\)\\>" (1 font-lock-reference-face))))

(defun ensure-prolog-syntax ()
  "Make sure that the Prolog syntax table is set up properly"
  ; PMartin 18 Mar 88
  (if (null prolog-mode-syntax-table)
      (progn
	(setq prolog-mode-syntax-table (make-syntax-table))
	(modify-syntax-entry ?\\ "\\"   prolog-mode-syntax-table)
	(modify-syntax-entry ?/ "  14"  prolog-mode-syntax-table)
	(modify-syntax-entry ?* "  23"  prolog-mode-syntax-table)
	(modify-syntax-entry ?' "w"     prolog-mode-syntax-table)
;	(modify-syntax-entry ?\" "w"    prolog-mode-syntax-table)
	(modify-syntax-entry ?\_ "w"    prolog-mode-syntax-table)
	(modify-syntax-entry ?\% "<"  prolog-mode-syntax-table)
;	(modify-syntax-entry ?\% "w"  prolog-mode-syntax-table)
	(modify-syntax-entry ?\n ">"  prolog-mode-syntax-table)))
  (if (not
       ;; [PM] 2003-08-07 A way to back out of todays changes if needed (e.g., for some old emacsen)
       (and (boundp 'qp-old-font-lock-setup)
           qp-old-font-lock-setup))
      (progn
        ;; [PM] 2003-08-07 QPRM 2663 The right way, see font-lock.el
        ;; Works both for GNU Emacs 21.3.1 and XEmacs 21.4
        (make-local-variable 'font-lock-defaults)
        ;; (KEYWORDS KEYWORDS-ONLY CASE-FOLD SYNTAX-ALIST SYNTAX-BEGIN ...)
        (setq font-lock-defaults '(prolog-font-lock-keywords
                                   nil ; not only keyword (but also strings and comments)
                                   nil nil nil))
        )
    (progn
      ;; [PM] 2003-08-07 not (anymore?) the right way to set up font-lock properties
      ;;      See variable font-lock-defaults for how things should work.
      (cond
       (qp-xemacs
        (defconst prolog-font-lock-keywords
          (list
           '("[0-9]+'\\(\\w+\\|.\\)" . font-lock-preprocessor-face)
           '("\\('.*'\\|\".*\"\\)" . font-lock-string-face)
           '("\%.*" . font-lock-comment-face)))
        (make-local-variable 'font-lock-keywords)
	
        (setq font-lock-keywords prolog-font-lock-keywords)
        (put 'prolog-mode	'font-lock-keywords 'prolog-font-lock-keywords))
       (t                               ; (BT)
        (defconst prolog-font-lock-keywords
          '(("^[a-z$]+[a-zA-Z0-9_$]*" . font-lock-function-name-face)
            ("\\(^\\|[^0-9]\\)\\('\\([^\n']\\|\\\\'\\)*'\\)" . font-lock-string-face)
            ("\\(\"\\([^\n\"]\\|\\\\\"\\)*\"\\)" . font-lock-string-face)
            ("\\<\\([_A-Z][a-zA-Z0-9_]*\\)" . font-lock-variable-name-face)
            ("[][}{!;|]\\|\\*->" . font-lock-keyword-face)
            ("[^-*]\\(->\\)" . font-lock-keyword-face)
            ("\\<\\([a-z$]+[a-zA-Z0-9_$]*:\\|\\)[a-z$]+[a-zA-Z0-9_$]*/[0-9]+" . font-lock-function-name-face)
            ("^[?:]- *\\(block\\|dynamic\\|mode\\|module\\|multifile\\|meta_predicate\\|parallel\\|public\\|sequential\\|volatile\\)\\>" (1 font-lock-reference-face))))
        (make-local-variable 'font-lock-keywords)
        (setq font-lock-keywords prolog-font-lock-keywords))))))

;;(modify-syntax-entry ?' "\""     prolog-mode-syntax-table)

(autoload 'pop-tag-mark "etags")

(defun prolog-mode-commands (map)
  (define-key map "\C-m" 'prolog-newline)
  (define-key map "\e\C-f" 'forward-term)
  (define-key map "\e\C-b" 'backward-term)
  (define-key map "\e." 'find-definition)
  (define-key map "\e," 'find-more-definition)
  (define-key map "\ex" 'meta-x-trap)
  (define-key map "\M-\t" 'comint-dynamic-complete)
  (define-key map "\M-?" 'comint-dynamic-list-completions)
;  (define-key map "*" 'pop-tag-mark)
  ; the next two bindings are for backward compatibility
  (define-key map "\C-x\C-e" 'comint-previous-similar-input)
  (define-key map "\C-x\C-y" 'comint-previous-input-matching)
  (define-key map "\C-c\C-c" 'interrupt-prolog))

(defun prolog-mode-variables ()
  (set-syntax-table prolog-mode-syntax-table)
  (setq local-abbrev-table prolog-mode-abbrev-table)
  (make-local-variable 'paragraph-start)
  (setq paragraph-start (concat "^$\\|" page-delimiter))
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'prolog-indent-line)
  (make-local-variable 'comment-start)
  (setq comment-start "%")
  (make-local-variable 'comment-start-skip)
  (setq comment-start-skip "%+ *")
  (make-local-variable 'comment-column)
  (setq comment-column 50)
  (make-local-variable 'comment-indent-function)
  (setq comment-indent-function 'prolog-comment-indent))

(defvar inferior-prolog-mode-map nil)
(defvar @at-debugger-prompt nil)

; If string is just white space. Send just a new line, so we get the
; prolog prompt back - This is a hack Dave had added in prolog-newline
; which has been moved here
(defun qprolog-input-sender (proc string)
  (setq *prolog-term-reading-mode* nil)
  (setq @at-debugger-prompt nil)
  (comint-send-string proc string)
  (comint-send-string proc "\n"))

(defun qprolog-input-filter (str)
  (cond ((null *prolog-term-reading-mode*) nil)
	(t (not (string-match "\\`\\s *\\'" str)))))

(defun qprolog-get-old-input ()
  (save-excursion
    (beginning-of-line)
    (comint-skip-prompt)
    (let ((beg (point)))
      (end-of-line)
      (while (and (not (eobp))
		  (not (clause-end-p)))
	(forward-line 1)
	(end-of-line))
      (buffer-substring beg (point)))))

(require 'comint)                       ; [PM] 3.5 for comint-mode-map
(if inferior-prolog-mode-map
    nil
  (setq inferior-prolog-mode-map (copy-keymap comint-mode-map))
  (prolog-mode-commands inferior-prolog-mode-map))

(defun inferior-prolog-mode ()
    "Major mode for interacting with an inferior Prolog process.

The following commands are available:
\\{inferior-prolog-mode-map}

Entry to this mode calls the value of comint-prolog-hook with no arguments,
if that value is non-nil.  Likewise with the value of shell-mode-hook.
comint-prolog-hook is called after shell-mode-hook.

You can send text to the inferior Prolog from other buffers
using the commands comint-send-region, comint-send-string.

Commands:
Delete converts tabs to spaces as it moves back.
Tab indents for Prolog; with argument, shifts rest
 of expression rigidly with the current line.
Meta-Control-Q does Tab on each line starting within following expression.
Paragraphs are separated only by blank lines.  Percent(%) start comments.

Return at end of buffer sends line as input.
Return not at end copies rest of line to end and sends it.
C-d at end of buffer sends end-of-file as input.
C-d not at end or with arg deletes or kills characters.
C-u and C-w are kill commands, imitating normal Unix input editing.
C-c interrupts the shell or its current subjob if any.
C-z stops, likewise.  C-\\ sends quit signal, likewise.

C-x C-k deletes last batch of output from shell.
C-x C-v puts top of last batch of output at top of window."
    (interactive)
    (comint-mode)
    (setq comint-prompt-regexp qprolog-prompt-pattern)
    (setq major-mode 'inferior-prolog-mode)
    (setq mode-name "Prolog")
    (setq mode-line-format 
          "--%1*%1*-Emacs: %12b   %M          %[(%m: %s)%]----%3p--%-")
    (prolog-mode-variables)
    (use-local-map inferior-prolog-mode-map)
    (setq comint-input-filter 'qprolog-input-filter)
    (setq comint-input-sender 'qprolog-input-sender)
    (setq comint-get-old-input 'qprolog-get-old-input)
    (setq comint-ptyp nil) 	; communication via pipes
    (run-hooks 'comint-prolog-hook))

(defvar startup-jcl (concat " +C" " Emacs:" prolog-zap-file)
  "String that identifies that emacs is the sender")
(defvar *prolog-executable* nil
  "The prolog executable")
(defvar *prolog-flags* nil
  "Prolog command line switches")

(defun run-prolog (&optional gnu-context)
  "Run an inferior Prolog process, input and output via buffer
*prolog*.  Environment variable QUINTUS_PROLOG_PATH must be set to the
pathname of the prolog executable before invoking this function
interactively. Optional first argument means fire up named save-state;
Called by GNU Emacs 'recover-context'. Gnu-context is the name of the
prolog saved-state."
  (interactive)
  (ensure-prolog-syntax)
  (cond (gnu-context
         (setq *prolog-executable* gnu-context))
        (t (if (getenv "QUINTUS_PROLOG_PATH")
               (let  
                   ((prolog-command-string (concat 
                                            (getenv "QUINTUS_PROLOG_PATH")
                                            startup-jcl)))
                 (get-prolog-exec-and-flags prolog-command-string))
             (setq *prolog-executable* ""))))
  (cond ((string-equal *prolog-executable* "")
         (message "Environment variable QUINTUS_PROLOG_PATH not set"))
        (t
         (let* ((buf (get-buffer "*prolog*"))
                (already-running        ; [PM] 3.5 somewhat paranoid definition
                 (and buf
                      (get-buffer-process buf)
                      (get-process "prolog"))))
           (if already-running
               (switch-to-buffer buf)
             (progn                     ; [PM] 3.5 don't do this if already running
               (switch-to-buffer  (apply 'make-comint "prolog"
                                         *prolog-executable* nil  
                                         *prolog-flags*))
               (set-process-filter (get-process "prolog") 'prolog-process-filter)
               (sleep-for 2)
               (inferior-prolog-mode)
               (error-occurred (prolog-startup-hook))))))))

;---------------------------------------------------------------------
; Separates the executable from rest of args (to prolog)
;---------------------------------------------------------------------
(defun get-prolog-exec-and-flags-orig (prolog-command-string)
  (let ((i 1))
    (while (not (string-equal 
		  (substring prolog-command-string i (+ i 1))
		  " "))
      (setq i (+ i 1)))
    (setq *prolog-executable* (substring prolog-command-string 0 i))
    (setq *prolog-flags* (prolog-args (substring prolog-command-string
						 (+ i 1))))))

(defun get-prolog-exec-and-flags-win32 (prolog-command-string)

  ;; [PM] 3.5 This does not work well with Win32 long pathnames,
  ;; especially since the default install is in a path containing
  ;; space (e.g., C:/Program Files/Quintus Prolog 3.5/bin/ix86)
  ;; windows but QP will pass arguments on QUINTUS_PROLOG_PATH when
  ;; invoked as "prolog +"
  ;;
  ;; On XEmacs qp-setup.el will use win32-short-file-name to work
  ;; around the problem but for values set by the user and for FSF
  ;; Emacs that is not an option
  ;; FIXME: Modify the code to scan past the longest prefix that denotes a directory
  (let ((i 1))
    (while (not (string-equal 
		  (substring prolog-command-string i (+ i 1))
		  " "))
      (setq i (+ i 1)))
    (setq *prolog-executable* (substring prolog-command-string 0 i))
    (setq *prolog-flags* (prolog-args (substring prolog-command-string
						 (+ i 1))))))

(defun get-prolog-exec-and-flags (prolog-command-string)
  (if (memq system-type '(windows-nt ms-dos cygwin32))
      (get-prolog-exec-and-flags-win32 prolog-command-string)
    (get-prolog-exec-and-flags-orig prolog-command-string)))


;---------------------------------------------------------------------
; Breaks up a single string of args into individual strings
;---------------------------------------------------------------------
(defun prolog-args (prolog-command-string)
  (let ((argnum 1)
	(arg-list nil)
	(done t)
	arg)
    (while done
      (cond ((not (string-equal (setq arg
				      (get-arg prolog-command-string argnum))
				"")
	     )
	     (set-variable (intern (concat "arg" "_" (number-to-string argnum))) arg) ; [PM] 2003-04-24 do not pass integers to concat
	     (setq arg-list (cons arg arg-list))
	     (setq argnum (+ argnum 1)))
	    (t (setq done nil))))
  (nreverse arg-list)))

; ----------------------------------------------------------------------
; get-arg returns the arg-pos'th command string from prolog-command-string
; ---------------------------------------------------------------------- 
(defun get-arg (prolog-command-string arg-pos)
  (let ((i 0)
	(j 0)
	(done t)
	(arg arg-pos)
	(len (length prolog-command-string)))
    (while (and (/= arg 0)
		 done)
      (while (and (< i len)
		  (string-equal (substring prolog-command-string i (+ i 1))
				" "))
	(setq i (+ i 1))
	(setq j (+ j 1)))
      (while (and (< i len)
		  (not (string-equal 
			 (substring prolog-command-string i (+ i 1))
			 " ")))
	(setq i (+ i 1)))
      (cond ((>= i len)
	     (setq done nil)))
      (setq arg (1- arg))
      (cond ((/= arg 0)
	     (setq j i))))
    (substring prolog-command-string j i)))
	

(defun kill-prolog-word (arg)
  "Kill characters forward until encountering the end of a word.
Treats underscore as a word if it appears as an argument.
With argument, do this that many times."
  (interactive "*p")
  (kill-region (point) (progn (forward-prolog-word arg) (point))))

(defun backward-kill-prolog-word (arg)
  "Kill characters backward until encountering the end of a word.
With argument, do this that many times."
  (interactive "*p")
  (kill-prolog-word (- arg)))

(defun backward-term (arg)
  (interactive "p")
  (forward-term (- arg)))

(defun forward-term (arg)
  (interactive "p")
  (cond
   ((zerop arg) t)
   ((> arg 0)
    (forward-sexp 1)
    (if (= (following-char) ?\( )
	(forward-sexp 1))
    (forward-term (1- arg)))
   (t
    (forward-sexp -1)
    (if (= (following-char) ?\( )
	(forward-sexp -1))
    (forward-term (1+ arg)))))

(defun forward-prolog-word (arg)
  "Just like word forward, but it treats `_' like a word
if it is used in the position that it is a anynomous variable"
  (interactive "p")
  (or arg (setq arg 1))
  (cond
   ((zerop arg) t)
   ((> arg 0)
    (if (looking-at "[(,]?\\s-*_\\s-*[),]")
        (progn
          (forward-char 1)
          (re-search-forward "[),]")
          (backward-char 1))
      (forward-word 1))
    (forward-prolog-word (1- arg)))
   (t
    (if (looking-at "_") (forward-char -1))
    (if (looking-at "\\s-\\|$") (re-search-backward "\\S-"))
    (cond
     ((looking-at "[,)]")
      (forward-char -1)
      (if (looking-at "\\s-") (re-search-backward "\\S-"))
      (if (not (looking-at "_"))
          (progn
            (forward-char 1)
            (forward-word -1))))
     ((looking-at "_") t)
     (t (forward-word -1)))
    (forward-prolog-word (1+ arg)))))

(defun backward-prolog-word (arg)
  "Move backward until encountering the end of a word.
With argument, do this that many times.
In programs, it is faster to call forward-word with negative arg."
  (interactive "p")
  (forward-prolog-word (- arg)))
