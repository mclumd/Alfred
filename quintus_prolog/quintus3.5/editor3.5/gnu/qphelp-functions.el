;;; SCCS: %W% %G%
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

(provide 'qphelp-functions)


;; [PM] 3.5 localize xref regexp to a single place
;; [PM] 3.5 added - to node-name chars (for things like glo-glo)
;; [PM] 3.5+ added _ for things like mpg-ref-at_end_of_file.
;; [PM] 3.5 Ensure match 1 is the reference
(defconst qp-xref-node-regexp "\\([a-z_---]+-*[0-9---]*\\)")
(defconst qp-manual-xref-regexp (concat "manual(" qp-xref-node-regexp ")"))

;
; key functions. Each function is bound to a specific key code.
;

(defmacro error-occurred (&rest body)
  (list 'condition-case nil (cons 'progn (append body '(nil))) '(error t)))

(defun find-next-entry ()
  (interactive)
  (if (error-occurred (re-search-forward qp-manual-xref-regexp))
      (progn 
	(goto-char (point-min))
	(if (error-occurred (re-search-forward qp-manual-xref-regexp)) 
	    (progn 
	      (message "Bad menu format for file: %s" current-file)
	      (stop-it)))))
  (message "<Space> to advance cursor, <Return> to select item, q to Quit, ? for Help"))

(defun find-previous-entry ()
  (interactive)
  (beginning-of-line)
  (if (error-occurred (re-search-backward qp-manual-xref-regexp))
      (progn 
	(goto-char (point-max))
	(if (error-occurred (re-search-backward qp-manual-xref-regexp))
	    (progn 
	      (message "Bad menu format for file: %s" current-file)
	      (stop-it)))))
  (re-search-forward (concat qp-xref-node-regexp ")")) ; [PM] 3.5 was "[a-z]+-*[0-9---]*)"
  (message "<Space> to advance cursor, <Return> to select item, q to Quit, ? for Help"))

(defun get-entry ()
  (interactive)
  (save-excursion
    (beginning-of-line)
    (if (error-occurred (re-search-forward qp-manual-xref-regexp))
	(message (concat "The cursor is not at a cross reference, " 
			 "try typing a <Space>/<DEL>."))
      (let ((tag (buffer-substring (match-beginning 1) (match-end 1))))
        (re-search-backward "manual")   ; preserve the pre 3.5 move
        (send-manual-command tag t)))))

;; [PM] 3.5
(defun send-manual-command (&optional tag quiet)
  (let ((goal (if tag
                  (format "manual(%s)"

                          ;; [PM] 3.5+ quote sub-terms (I distinctly
                          ;; remember that not doing this caused
                          ;; problems but I cannot find and do not
                          ;; remember what kind of references were
                          ;; causing trouble.
                          (cond ((fboundp 'replace-in-string) ;XEmacs
                                 (replace-in-string tag "\\([^-]+\\)" "'\\1'"))
                                ((fboundp 'replace-regexp-in-string) ; FSF Emacs
                                 (replace-regexp-in-string "\\([^-]+\\)"
                                                           "'\\1'" tag
                                                           t))
                                (t      ; old emacs?
                                 tag)))
                "manual")))
    (or quiet
        (message "Please wait calling: %s" goal))
    (send-prolog goal)))


(defun stop-it ()
  "Return to the top level. Typically this is the prolog shell."
  (interactive)
  (let* ((list (buffer-list)))
    (while list
      (let* ((buffer (car list)))
	(and (string-match "Quintus-Help-System" (buffer-name buffer))
	     (kill-buffer buffer)))
      (setq list (cdr list))))
  (pop-to-buffer "*prolog*")
  (goto-char (point-max)))

(defun find-next-reference ()
  (interactive)
  (if (error-occurred (re-search-forward qp-manual-xref-regexp)) 
      (message "End of cross references.")))

(defun find-previous-reference ()
  (interactive)
  (let ((position (point)))
    (if (error-occurred (re-search-backward "{"))
	(progn 
	  (message "Beginning of cross references.")
	  (goto-char position))
      (if (error-occurred (re-search-backward qp-manual-xref-regexp))
	  (progn 
	    (message "Beginning of cross references.")
	    (goto-char position))
	(re-search-forward ")")))))
	  
(defun retrieve-next-reference ()
  (interactive)
  (save-excursion
    (if (error-occurred (re-search-backward qp-manual-xref-regexp))
        (message "Reference not found, try typing 'X' or 'x'.")      
      (let ((tag (buffer-substring (match-beginning 1) (match-end 1))))
        (re-search-forward ")")         ; preserve the movement done in 3.4
        (send-manual-command tag t)))))

(defun back-one-step ()
  "Return to the previous level."
  (interactive)
  (pop-state))

(defun get-menu-help ()
  (interactive)
  (message "Please wait, getting help...")
  (send-manual-command "menus, Emacs commands for" t))

(defun get-text-help ()
  (interactive)
  (message "Please wait, getting help...")
  (send-manual-command "text, Emacs commands for" t))

(defun up-one-level ()
  "Go to the parent reference"
  (interactive)
  (goto-char (point-min))
  (end-of-line)
  (cond ((equal (point-min) (point))
	 (stop-it))
        (t (cond ((re-search-backward "-" (point-min) t)
                  (send-manual-command (buffer-substring (point-min) (point))))
                 (t
                  (send-manual-command))))))


(defun previous-page ()
  (interactive)
  (scroll-down nil))

(defun next-page ()
  (interactive)
  (scroll-up nil))

(defun scroll-one-line-up ()
  (interactive)
  (scroll-up 1))

(defun scroll-one-line-down ()
  (interactive)
  (scroll-down 1))


