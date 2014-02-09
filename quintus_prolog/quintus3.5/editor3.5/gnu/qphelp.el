;;; SCCS: @(#)qphelp.el	76.2 04/06/99
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
;;; Note: there may be a problem using Quintus Prolog help under X windows.
;;; If the emacs window is resized or moved after help is invocated, restoring
;;; the previous window  configuration will result in an error. 

(provide 'qphelp)
(require 'qphelp-functions)

; Quintus Prolog Help System file types.
;
(defconst MENU "{menu}")
(defconst TEXT "{text}")
(defconst SHELL "{shell}")
(defconst HELP "{help}")
(defconst Prolog-buffer "*prolog*")

; Constants
;
(defconst NOERROR t)
(defconst EMPTY '())

; Initialize Variables.
;
(defvar *state* '() 
  "List of buffer states, i.e. (current-buffer point).")
(defvar current-file nil 
  "The help file we are now looking for; used for error reporting.")
(defvar Quintus-help-key-map nil "Local keymap for Prolog menu help.")
(defvar Quintus-text-key-map nil "Local keymap for Prolog text help.")

; buffer:
;    Quintus-help-system: for help and text interaction.
;
(defvar Quintus-help-system "*Quintus-Help-System*" 
  "Buffer name used during a Quintus Prolog help session.")

(defmacro error-occurred (&rest body)
  (list 'condition-case nil (cons 'progn (append body '(nil))) '(error t)))

(defun push-state (buffer point)
  "Save the current buffer and point location."
  (setq *state* (append (list (cons buffer point)) *state*)))

(defun pop-state ()
  "pop to the most recent buffer. If we are returning to the 
   top level, return the point to the end of the buffer."
  (kill-buffer (current-buffer))
  (while (error-occurred (pop-to-buffer (car (car *state*)))) 
					; in case intermediate buffers have been killed
    (setq *state*  (cdr *state*)))
  (if  (equal (buffer-name (car (car *state*))) "*prolog*")
       (goto-char (point-max))			; then part
       (goto-char	 (cdr (car *state*))))  ; else part
  (setq *state*  (cdr *state*)))
  
(defun initialize-state ()
  "Initilize variables with each invocation from Quintus Prolog."
  (if (string-equal (buffer-name) Prolog-buffer)
      (setq *state* '())))

(defun @help (file)
  "Help executive for Quintus Prolog."
  (initialize-state)
  (push-state (current-buffer) (point))
  (process-file file))

(defun @manual (file)
  "Manual executive for Quintus Prolog."
  (initialize-state)
  (push-state (current-buffer) (point))
  (process-file file))

;; [PM] 3.5
(defvar qp-use-info-for-help t
  "*If non-nil (the default) tries to go to use Info for reading manual entries.
In nil, use a separate buffer as in Quntus Prolog 3.4")

(defun process-file (file)
  "Process a help or manual query from Quintus Prolog"
  (if qp-use-info-for-help
      (progn                            ; [PM] 3.5 go to the info node instead
        (require 'info)
        (let ((buf (generate-new-buffer Quintus-help-system))
              (info-buffer nil))
          (with-current-buffer buf
            ;; (erase-buffer)
            (if (error-occurred (insert-file-contents-literally file nil nil nil t)) ;read the file into an empty buffer
                (message "%s" (concat "There is no information "
                                      "currently available on this topic."))
              (progn
                ;; [PM] 3.5+ On Win32 the file has CRLF line ends (which it should have). Strip the ugly CR
                (progn
                  (goto-char (point-min))
                  (while (re-search-forward "$" nil t)
                    (replace-match "" t t)))

                (goto-char (point-min))
                (if (looking-at (concat "^File: \\([a-zA-Z.0-9---]+\\),  Node: \\(" qp-xref-node-regexp "\\),"))
                    (let* ((file-name (buffer-substring (match-beginning 1) (match-end 1)))
                           (node-name (buffer-substring (match-beginning 2) (match-end 2)))
                           (node-spec (format "(%s)%s" file-name node-name)))
                      (save-window-excursion ; [PM] 3.5 do not let Info-goto-node show *info*
                        (if (not (error-occurred 
                                  (Info-goto-node node-spec)))
                            (setq info-buffer (current-buffer)))))))))
          (if info-buffer
              (progn
                (kill-buffer buf)
                (switch-to-buffer-other-window info-buffer))
            (progn
              (switch-to-buffer-other-window buf)
              
              (setq current-file file)  ; save current file for error reporting
              (goto-char (point-min))   ; goto top of file
              (initialize)              ; initialize the window

              ))))
    (progn                              ; [PM] pre-3.5
      
  (switch-to-buffer-other-window (generate-new-buffer Quintus-help-system))
  ;; [PM] 3.5 not needed with REPLACE arg to insert-file-contents-literally
  ;; (erase-buffer)
  ;; [PM] 3.5 was insert-file but that is only for interactive use
  (if (error-occurred (insert-file-contents-literally file nil nil nil t)) ;read the file into an empty buffer
      (message "%s" (concat "There is no information "
			    "currently available on this topic."))
    (progn (setq current-file file) ; save current file for error reporting
	   (goto-char (point-min))  ; goto top of file
	   (initialize))))          ; initialize the window
    )
  )

(cond (qp-xemacs

(defun Quintus-mouse-find-help-reference (event)
  "Find the reference under the mouse."
  (interactive "e")
  (mouse-set-point event)
  (get-entry))

(defun Quintus-mouseify-xrefs ()	; seems to be XEmacs specific (BT)
  (goto-char (point-min))		; and is used only in XEmacs (BT)
  ;; [PM] 3.5 {text} buffers have contents on first line too so do not skip it:
  ;; (forward-line 1)                      ; [PM] 3.5 why was this done?
  (let ((case-fold-search nil)
	s e name extent already-fontified)
    ;; [PM] 3.5 use qp-manual-xref-regexp
    (while (re-search-forward (concat "{" qp-manual-xref-regexp "}") nil t)
      (setq s (match-beginning 0)
	    e (match-end 0)
	    name (buffer-substring (+ s 1) (- e 1)))
      (goto-char s)
      (setq already-fontified (extent-at s))
      (setq extent (make-extent s e))
      (set-extent-property extent 'qp name)
      (set-extent-property extent 'highlight t)
      (if (not already-fontified)
	  (set-extent-face extent 'italic))
      (goto-char e)))
  (goto-char (point-min)))

(defun Quintus-follow-xref (event)
  (interactive "e")
  (mouse-set-point event)
  (let ((x (extent-at (event-point event)
		      (window-buffer (event-window event))
		      'highlight)))
    (if x (send-prolog (extent-property x 'qp))
      (send-prolog (concat "help(('" (downcase (current-word)) "'))")))))

))

;; [PM] 3.5 no need
;; (defvar mode-motion-hook nil)		; no compile warning (BT)

(defun initialize () 
  "Initiailzations performed on entry to a buffer. Different actions are 
   performed depending whether the file is {menu} or {text}."
  (cond
   ((file-type MENU)
    (delete-type-marker)	; remove the type marker
    (define-local-key-map MENU) ; define local key map
    (find-next-entry)		; go to first entry
    (cond
     (qp-xemacs
      (define-key Quintus-help-key-map 'button2
	'Quintus-mouse-find-help-reference)
      ;; (make-local-variable 'mode-motion-hook)
      ;; (setq mode-motion-hook 'mode-motion-highlight-line)
      (add-hook 'mode-motion-hook 'mode-motion-highlight-line nil t) ; [PM] 3.5 the right way to add to a local hook
      )))
   ((file-type TEXT)
    (delete-type-marker) ;delete type marker
    (define-local-key-map TEXT) ;define local key map
    (cond
     (qp-xemacs
      (Quintus-mouseify-xrefs)
      (define-key Quintus-text-key-map 'button2 'Quintus-follow-xref))))
   (t (message "%s" (concat "error malformed help/manual "
			    "file: type marker not found."))))
  (toggle-read-only))


(defun define-local-key-map (type)
  "Select a key map for either menu or text files."
  (cond ((string-equal type TEXT)
         (Define-Quintus-text-keys)
         (use-local-map Quintus-text-key-map))
	((string-equal type SHELL)
         (Define-Quintus-help-keys)
         (use-local-map Quintus-help-key-map))

        ;; [PM] 3.5 {menu} is gone, always use {text}
        ;; ((string-equal type MENU)
        ;;  (Define-Quintus-help-keys)
        ;;  (use-local-map Quintus-help-key-map))
	
	(t (message "define-local-key-map: illegal map specifer: %s" type))))

(defun Define-Quintus-help-keys ()
  (if (equal Quintus-help-key-map nil)
      (progn 
	(setq Quintus-help-key-map (make-keymap))
	(suppress-keymap Quintus-help-key-map)    
	(Quintus-help-key-map))))

(defun Define-Quintus-text-keys ()
  (if (equal Quintus-text-key-map nil)
      (progn 
	(setq Quintus-text-key-map (make-keymap))
	(suppress-keymap Quintus-text-key-map)
	(Quintus-text-key-map))))

(defun Quintus-text-key-map ()
  "Define the local key for The Quintus Prolog Text System."
  (define-key Quintus-text-key-map "q"      'stop-it)
  (define-key Quintus-text-key-map "b"      'back-one-step)
  (define-key Quintus-text-key-map "l"      'back-one-step)
  (define-key Quintus-text-key-map "u"      'up-one-level)
  (define-key Quintus-text-key-map "?"      'get-text-help)
  (define-key Quintus-text-key-map "x"      'find-next-reference)
  (define-key Quintus-text-key-map "X"      'find-previous-reference)
  (define-key Quintus-text-key-map "\C-m"   'retrieve-next-reference)
  (define-key Quintus-text-key-map "\C-v"   'next-page)
  (define-key Quintus-text-key-map "\e\C-v" 'previous-page)
  (define-key Quintus-text-key-map "\ez"    'scroll-one-line-up)
  (define-key Quintus-text-key-map "\e\C-z" 'scroll-one-line-down)
  (define-key Quintus-text-key-map " "      'scroll-up)
  (define-key Quintus-text-key-map "\C-?"   'scroll-down)
  (define-key Quintus-text-key-map "<"      'beginning-of-buffer)
  (define-key Quintus-text-key-map ">"      'end-of-buffer))

(defun Quintus-help-key-map ()  
  "Define the local key map for The Quintus Prolog Help System."
  (define-key Quintus-help-key-map " "      'find-next-entry)
  (define-key Quintus-help-key-map "\C-m"   'get-entry)
  (define-key Quintus-help-key-map "\C-?"   'find-previous-entry)
  (define-key Quintus-help-key-map "q"      'stop-it)
  (define-key Quintus-help-key-map "u"      'up-one-level)
  (define-key Quintus-help-key-map "b"      'back-one-step)
  (define-key Quintus-help-key-map "l"      'back-one-step)
  (define-key Quintus-help-key-map "?"      'get-menu-help))

(defun delete-type-marker () 
  "Delete the type marker. Function 'delete-type-marker' assumes the
   existence of the type marker has been verified with 'file-type'."	
  (goto-char (point-max))
  (forward-line -1)
  (kill-line 1)
  (goto-char (point-min)))

(defun file-type (type)
  "Find the type marker: {menu} or {text}."
  (goto-char (point-max))
  (forward-line -1)
  (beginning-of-line)
  (cond ((search-forward type nil NOERROR) (goto-char (point-min)))
	(t (not (goto-char (point-min))))))

