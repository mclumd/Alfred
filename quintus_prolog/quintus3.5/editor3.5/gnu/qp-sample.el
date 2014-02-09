; @(#)qp-sample.el	76.3 04/28/03
; Author: Tom Howland (tom@rahul.net)
;;
;; [PM] 3.5 NOTE: This file is obsolete, load qp-setup.el instead
;;          You may still get some ideas for customization from this file
;;


; This file is discussed in the README file in this directory.

; Here are some things you might want to put in your .emacs file.
; Alternatively, you can just load this file, but it may do some key
; bindings or font manipulation that you won't fancy.



;; [PM] 2003-04-24 The setup part is no longer needed, provided you
;; load qp-setup.el before doing any of the setup in this file.
(if nil                                 ; no longer do this
    (progn

      ;; first, you must modify your load path. It should go something
      ;; like this:

      ;; (setq load-path (append '("/opt/quintus/editor3.4/gnu") load-path))

      ;; of course, it is up to the installer where quintus is
      ;; actually installed, so /opt may or may not be the right place
      ;; to start.

      ;; we want "qprolog-mode.el" loaded, not the gnu distributed
      ;; "prolog-mode.el"

      (autoload 'prolog-mode "qprolog-mode")
      (autoload 'run-prolog "qprolog-mode" "Run an inferior prolog process" t)

      (setq auto-mode-alist
            (append
             (list
              '("\\.pl" . prolog-mode)
              '("prolog.ini$" . prolog-mode))
             auto-mode-alist))


      ;; we want to use the emacs-based source-linked debugger when
      ;; running prolog under emacs.

      (add-hook 'comint-prolog-hook 'enable-prolog-source-debugger)
      ))

; we want Prolog compilation errors to be just as selectable as any
; other error in a compilation window

(defvar compilation-mode-hook-been-here nil)
(defun qp-compilation-mode-hook ()
  (if compilation-mode-hook-been-here t
    (setq compilation-error-regexp-alist
	  (append
	   '(("[*!] Approximate line: \\([0-9]+\\), file: '\\(.*\\)'" 2 1)
	     ("[*!] between lines \\([0-9]+\\) and [0-9]+ in file \\(.*\\)$" 2 1))
	   compilation-error-regexp-alist))
    (setq compilation-mode-hook-been-here t)))
(add-hook 'compilation-mode-hook 'qp-compilation-mode-hook)

; override the default indentation

(defvar head-continuation-indent 6 
  "Offset for continuation of clause head arguments.")
(setq body-predicate-indent 2)

; provide the capability to run different prologs. That is, different
; development systems with statically linked code (see qld -D for more info)

(defun really-run-prolog (arg)
  "Allows you to run a prolog a prolog with a specific path. If your PATH is
set correctly, you only need to specify the executables name. For example, just
entering \"prolog\" should work."
  (interactive "FWhich Prolog? ")
  (setenv "QUINTUS_PROLOG_PATH" arg)
  (run-prolog))

(defun really-run-prolog-with-args (arg args)
  (interactive "FWhich Prolog? 
sWith args: ")
  (load "qprolog-mode" nil t)
  (setenv "QUINTUS_PROLOG_PATH" arg)
  (setq startup-jcl (concat " +C" " Emacs:" prolog-zap-file " " args))
  (run-prolog))

(defun run-last-prolog ()
  (interactive)
  (message
   (or (getenv "QUINTUS_PROLOG_PATH")
       "default prolog"))
  (run-prolog))

(define-key ctl-x-map "p" 'really-run-prolog)
(define-key ctl-x-map "R" 'run-last-prolog)
(define-key ctl-x-map "r" 'really-run-prolog-with-args)

;; XEmacs and Emacs 20 tricks:   highlighting of strings and comments
;; in prolog-mode

(cond 
 ((or (and (string-match "Lucid" emacs-version)
	   (boundp 'emacs-major-version)
	   (= emacs-major-version 19)
	   (>= emacs-minor-version 9))
      (and (string-match "XEmacs" emacs-version)
	   (boundp 'emacs-major-version)
	   (= emacs-major-version 19)
	   (>= emacs-minor-version 10)))
  (add-hook 'prolog-mode-hook	'turn-on-font-lock)
  (add-hook 'comint-prolog-hook 'turn-on-font-lock))
 ((and (boundp 'emacs-major-version)
       (= emacs-major-version 20)
       (>= emacs-minor-version 3))
  (add-hook 'prolog-mode-hook	'font-lock-mode)
  (add-hook 'comint-prolog-hook 'font-lock-mode)))
