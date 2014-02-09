;;; SCCS: @(#)quintaux.el	76.3 05/28/03
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
;;; Load file for Quintus Prolog Emacs interface 

(provide 'quintaux)
; ----------------------------------------------------------------------
;                          Quintus files
; ----------------------------------------------------------------------

;;; from gnu3.4 (BT)
(defconst qp-xemacs (or (and (string-match "Lucid" emacs-version)
			     (boundp 'emacs-major-version)
			     (= emacs-major-version 19)
			     (>= emacs-minor-version 9))
			(and (string-match "XEmacs" emacs-version)
			     (boundp 'emacs-major-version)
                             (or
                              (and
                               (= emacs-major-version 19)
                               (>= emacs-minor-version 10))
                              ;; [PM] Recognize newer XEmacsen
                              (> emacs-major-version 19)))))

;; [PM] 3.5 modern Emacsen have comint already
;; (require 'qpcomint)
(load "qptokens" nil t)
(load "qpcommands" nil t)
(load "qpfindpred" nil t)
(load "qprocess" nil t)
(load "qprolog" nil t)
(load "qprolog-indent" nil t)
(load "emacsdebug" nil t)
(require 'qphelp)

