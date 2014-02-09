;;;    SCCS : @(#)qpcommon.el	76.1 10/28/98
;;;		      QUI - GNU Emacs Interface
;;;			  Support Functions
;;;
;;;		    Quintus Computer Systems, Inc.
;;;
;;;    This file defines functions that are common to qui_cmds.el and
;;;    qpcommands.el


(defun parse-functor-and-arity  (string)
  ; How do you like this 2 line regexp? It matches a "name/arity" or "name"
  ; The first parenthetical expression matches the name. The second matches the
  ; / and the third matches the arity.
  (if (string-match "^\\('[^']*'\\|[a-z][A-Za-z_0-9]*\\|[-+*/\\^<>=`~:.?@#$&]+\\|;\\|!\\=|\[ *\]\\|{ *}\\)\\(/\\|\\)\\([0-9]+\\|\\)$" string)
      (cons (substring string (match-beginning 1) (match-end 1))
	    (if (= (match-beginning 3) (match-end 3))
		-1
	      (string-to-int (substring string (match-beginning 3) 
					(match-end 3)))))
    (error "\"%s\" is not a proper name or name/arity" string)))
  
(defun query-user-for-predicate (msg)
  (let (user-response
	prompt
	(default (default-predicate-prompt)))
    (if default
	(setq prompt (format "%s (default %s) " msg default))
      (setq prompt (format "%s " msg)))
    (setq user-response  (read-from-minibuffer prompt))
    (if (not (string-equal user-response ""))
	(parse-functor-and-arity user-response)
      (parse-functor-and-arity default))
    ))

(defun fd-get-filename (bufname)
  (let (ans)
    (save-excursion
      (set-buffer bufname)
      (goto-char (point-min))
      (forward-char)
      (search-forward "\"")
      (backward-char)
      (setq *functor* (buffer-substring (+ (point-min) 1) (point)))
      (forward-char)
      (forward-char)
      (delete-region (point-min) (point))
      (search-forward " ")
      (backward-char)
      (setq *arity* (string-to-int (buffer-substring (point-min) (point))))
      (forward-char)
      (delete-region (point-min) (point))
      (end-of-line)
      (setq ans (buffer-substring (point-min) (point)))
      (forward-char)
      (delete-region (point-min) (point))
      ans
    )))


(defun fd-buffer-empty (bufname)
  (save-excursion
    (set-buffer bufname)
    (= (buffer-size) 0)))

(defun conditional-message (msg)
  (if *called-from-@find*
      (&qp-message msg)
    (message msg)
    (sit-for 0)))

; ----------------------------------------------------------------------

(defun locate-definition (functor arity print-name)
  (let ((continue t)
        (found-arity 0) (saved-point (point)) return)
    (goto-char (point-min))
    (while continue
      (if (not (re-search-forward (concat "^'?" functor "'?") nil t))
          (progn 
	    (goto-char saved-point)		      
	    (setq return
                  (concat "Cannot find a definition for " 
                          print-name 
                          " in this file"))
	    (setq continue nil))
        (if (not (within-comment))
            (let  (valid-arity (saved-dot (point)))
              (cond 
               ((looking-at "[A-Za-z0-9_]")
                (setq valid-arity nil))
               ((= (following-char) ?\( )
                (setq valid-arity
                      (condition-case nil
                          (progn (setq found-arity (all-arity saved-dot)) t)
                        (error nil))))
               (t
                (setq found-arity 0)
                (setq found-arity
                      (+ found-arity
                         (arity-overhead-for-grammar-rule saved-dot)))
                (setq valid-arity t)))
              (if valid-arity
                  (if (or (= arity found-arity) (= arity -1))
                      (progn 
			(goto-char saved-dot)
			(beginning-of-line)
			(setq return "")
			(setq continue nil))
		    (goto-char saved-dot))
		(goto-char saved-dot))))))
    return))
