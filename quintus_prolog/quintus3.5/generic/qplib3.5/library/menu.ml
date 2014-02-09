;   File   : menu.ml
;   Author : David Znidarsic
;   SCCS   : @(#)88/11/10 menu.ml	27.1
;   Purpose: define Mock Lisp (menu-choice menu-title menu-entries)
;   SeeAlso: menu.pl

;   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
; The following keys are bound in the "Menu" buffer:
; 
;	next-menu-entry		-	<sp>, ^N, n
;	previous-menu-entry	-	<bs>, ^P, p
;	quit-menu-system	-	q, ^G, ^C
;	choose-this-menu-entry	-	<cr>
;	ESC-prefix		-	<esc>		; binding not changed
;	menu-null-key		-	all other keys
; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(declare-global original-buffer clobbered-buffer)
(declare-global mess)
(setq mess "\" \" - Next, \"<bs>\" - Previous, \"<cr>\" - Choose, \"q\" - Quit")


; These strings are inserted before and after the menu title
; 
;   menu-title-prefix MenuTitle menu-title-suffix


(declare-global menu-title-prefix menu-title-suffix)
(setq menu-title-prefix "\n\t")
(setq menu-title-suffix "\n\n")


; These strings are inserted before and after each menu entry
; 
;   menu-entry-prefix menu-entry-key MenuEntry menu-entry-suffix


(declare-global menu-entry-prefix menu-entry-key menu-entry-suffix)
(setq menu-entry-prefix "\t\t")
(setq menu-entry-key "- ")
(setq menu-entry-suffix "\n\n")


; Define the keybindings for the menu


(define-keymap "Menu")
(save-excursion  key
    (temp-use-buffer "keys")
    (use-local-map "Menu")
    (setq key 0)
    (while (< key 128)
	(local-bind-to-key "null-menu-key" key)
	(setq key (+ key 1))
    )
    (local-bind-to-key "next-menu-entry" " ")
    (local-bind-to-key "next-menu-entry" "n")
    (local-bind-to-key "next-menu-entry" "\^N")
    (local-bind-to-key "previous-menu-entry" "\^H")
    (local-bind-to-key "previous-menu-entry" "p")
    (local-bind-to-key "previous-menu-entry" "\^P")
    (local-bind-to-key "choose-this-menu-entry" "\^M")
    (local-bind-to-key "quit-menu-system" "q")
    (local-bind-to-key "quit-menu-system" "\^G")
    (local-bind-to-key "quit-menu-system" "\^C")
    (local-bind-to-key "ESC-prefix" "\e")
)
(delete-buffer "keys")


; The only entry point.  It is invoked by Prolog with two arguments:
; 
;   (arg 1) - MenuTitle - The menu title string to be printed atop the menu
;   (arg 2) - MenuEntries - The string of menu entries (each terminated by
;			    the sentinel character {ascii 1}) to be printed


(defun (menu-choice
    (setq original-buffer (current-buffer-name))
    (if (= original-buffer "prolog-buffer")
	(progn 
	    (previous-window)
	    (setq clobbered-buffer (current-buffer-name))
	)
	(setq clobbered-buffer original-buffer)
    )
    (switch-to-buffer "Menu")
    (erase-buffer)
    (setq needs-checkpointing 0)
    (setq mode-line-format " %b")
    (insert-menu (arg 1) (arg 2))
    (end-of-file)
    (next-menu-entry)
    (use-local-map "Menu")
    (&qp-message mess)
))


(defun (insert-menu
    (insert-menu-title (arg 1))
    (insert-menu-entries (arg 2))
))


(defun (insert-menu-title
    (insert-string menu-title-prefix)
    (insert-string (arg 1))
    (insert-string menu-title-suffix)
))


(defun (insert-menu-entry
    (insert-string menu-entry-prefix)
    (insert-string menu-entry-key)
    (insert-string (arg 1))
    (insert-string menu-entry-suffix)
))


; Extracts menu entries from its single string argument, inserting each into
; the "Menu" buffer.  Each entry in the string is terminated by the sentinel
; ascii character (ascii 1).  For example,
; 
;   (insert-menu-entries "Entry 1Entry 2Entry 3")


(defun (insert-menu-entries  entries index
    (setq entries (arg 1))
    (setq index 1)
    (while (!= entries "")
	(if (> index (length entries))
	     (progn 
		 (insert-menu-entry entries)
		 (setq entries "")
	     )
	    (= (substr entries index 1) (char-to-string 1))
	     (progn 
		 (insert-menu-entry (substr entries 1 (- index 1)))
		 (setq entries (substr entries (+ index 1) (- (length entries) index)))
		 (setq index 1)
	     )
	    (setq index (+ index 1))
	)
    )
))


; Moves cursor to the beginning of the menu-entry-key string of the next menu
; entry.  It wraps to the first menu entry if the cursor is currently at
; the last menu entry.


(defun (next-menu-entry
    (if (error-occurred
	    (re-search-forward
		(concat
		     (quote menu-entry-key)
		     ".*"
		     (quote menu-entry-suffix)
	             (quote menu-entry-prefix)
		)
	    )
	)
	(progn 
	    (beginning-of-file)
	    (if (error-occurred
		    (re-search-forward
			(concat
			     (quote menu-title-prefix)
			     ".*"
			     (quote menu-title-suffix)
			     (quote menu-entry-prefix)
			)
		    )
		)
		(error-message "No Menu Entries.")
	    )
	)
    )
    (message mess)
    (sit-for 0)
))


; Moves cursor to the beginning of the menu-entry-key string of the previous
; menu entry.  It wraps to the last menu entry if the cursor is currently at
; the first menu entry.


(defun (previous-menu-entry
    (if (error-occurred
	    (re-search-reverse
		(concat
		     (quote menu-entry-key)
		     ".*"
		     (quote menu-entry-suffix)
		     (quote menu-entry-prefix)
		)
	    )
	)
	(progn 
	    (end-of-file)
	    (if (error-occurred
		    (re-search-reverse
			(concat
			     (quote menu-entry-key)
			     ".*"
			     (quote menu-entry-suffix)
			)
		    )
		)
		(error-message "No Menu Entries.")
	    )
	)
    )
    (message mess)
    (sit-for 0)
))


; Sends to Prolog the term 'menu_choice'(N), where N is the number of the
; entry where the cursor currently is.  It does this by adding 1 to the
; number of entries which precede the current entry.  It also restores the
; editor's window system to it previous state.


(defun (choose-this-menu-entry  index
    (setq index 1)
    (while (! (error-occurred
		  (re-search-reverse
		      (concat
			   (quote menu-entry-key)
			   ".*"
			   (quote menu-entry-suffix)
			   (quote menu-entry-prefix)
		      )
		  )
	      )
	   )
	(setq index (+ index 1))
    )
    (setq prolog-term-reading-mode 0)		      ; see "prolog-newline"
    (&clear-message)				      ; see 'aux.ml'
    (string-to-process "prolog-buffer" (concat "menu_choice(" index ").\n"))
    (switch-to-buffer clobbered-buffer)
    (pop-to-buffer original-buffer)
))


; Sends Prolog the term 'no_menu_choice' which should not unify which what it
; expects so that the predicate driving this menu will fail.  It also restores
; the editor's window system to it previous state.


(defun (quit-menu-system
    (setq prolog-term-reading-mode 0)		      ; see "prolog-newline"
    (&clear-message)				      ; see 'aux.ml'
    (string-to-process "prolog-buffer" "no_menu_choice.\n") ; should always fail
    (switch-to-buffer clobbered-buffer)
    (pop-to-buffer original-buffer)
))


(defun (null-menu-key
    (message mess)
    (sit-for 0)
))
