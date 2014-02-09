; @(#)qp-setup.el	1.2 04/28/03
;; simple set-up file for QP emacs mode
;; Quintus Prolog 3.4.3
;;
;; Version History:
;;  * 1.0 -- 2003-04-24 Per.Mildner@sics.se Created

;; The only set-up needed to enable the Quintus Emacs support is to
;; load this file (from its original location!). The simplest way to
;; do this is to add something like the following to your .emacs file:
;;
;; (load "/usr/local/qp/editor3.4/gnu/qp-setup") ; for UNIX
;; or
;; (load "C:/quintus/editor3.4/gnu/qp-setup") ; for Win32
;;
;; You need to adjust the paths appropriately depending on where you
;; installed Quintus Prolog.
;;
;; After doing this, and restarting Emacs (or XEmacs), you should be
;; able to do M-X run-prolog to start Prolog and source linked
;; debugging etc should work.
;;
;; For questions, contact qpsupport@sics.se
;;

;; tested in qui.pl when emacs is started by "prolog +"
(provide 'qp-setup)

(defun quintus-init-emacs (this-file-name &optional debug dry-run)
  (let* ((on-win (memq system-type '(windows-nt ms-dos cygwin32)))
         (quintus-exe-suffix
          (if on-win
              ".exe"                    ; Win32
            ""                          ; UNIX 
            ))
         (quintus-emacs-directory
          (and this-file-name           ; location of this file 
               (expand-file-name (file-name-directory this-file-name))))
         (quintus-root-directory (expand-file-name "../.." quintus-emacs-directory))
         (quintus-editor-directory
          (and quintus-emacs-directory
               (expand-file-name ".." quintus-emacs-directory))) ; editor$VERSION/gnu/.., i.e., ..../editor$VERSION
         (quintus-version-suffix
          (if on-win
              ""
            (and
             quintus-editor-directory
             ;; [PM] 3.5+ added ? to beta paren expression
             (string-match "/editor\\([0-9.]+\\(beta[0-9]*\\)?\\).*$" ; e.g., editor3.4 or editor3.5beta5
                           ;; ..../editor3.4
                           quintus-editor-directory)
             (match-beginning 1)
             (match-end 1)
             (substring quintus-emacs-directory 
                        (match-beginning 1)
                        (match-end 1)))))

         ;; How to traverse the file system to reach the Quintus bin
         ;; directory from the emacs directory
         (quintus-bin-from-emacs-directory1
          (and quintus-version-suffix
               (concat "../../bin" quintus-version-suffix)))
         (quintus-bin-directory1
          (and quintus-root-directory
               (expand-file-name (concat "bin" quintus-version-suffix) quintus-root-directory))
          ;; (and quintus-bin-from-emacs-directory1
          ;;     (expand-file-name quintus-bin-from-emacs-directory1 quintus-emacs-directory))
          )

         ;; The binaries reside in the PLATFORM sub-directory of bin. This should be the only sub-directory.
         (quintus-bin-directory         ; location of prolog, qld etc.
          (and
           quintus-bin-directory1

           ;; Full path to anything that does not contains period (FSF
           ;; Emacs does not have a way to only list directories
           (car-safe (directory-files quintus-bin-directory1 t "[^.]" t))))
         (quintus-info-dir (and
                            quintus-root-directory
                            (if on-win
                                (expand-file-name "src/helpsys/info" quintus-root-directory)
                              (expand-file-name (concat "generic/q" quintus-version-suffix "/helpsys/info") quintus-root-directory))))
         
         (quintus-program-basename "prolog")
         (quintus-exe-path (and quintus-program-basename quintus-exe-suffix quintus-bin-directory
                                (expand-file-name 
                                 (concat quintus-program-basename quintus-exe-suffix)
                                 quintus-bin-directory))))
    (if debug
        (progn
          (message "quintus-init-emacs: this-file-name==%S\nquintus-bin-directory==%S\nquintus-exe-path==%S\nquintus-emacs-directory=%S\nquintus-version-suffix==%S\nquintus-info-dir==%S"
                   this-file-name quintus-bin-directory quintus-exe-path quintus-emacs-directory quintus-version-suffix quintus-info-dir)
          (sit-for 2)))

    ;; make sure the Quintus emacs files are found before anything else
    (if (not dry-run)
        (progn
          (if quintus-emacs-directory
              (setq load-path
                    (cons quintus-emacs-directory
                          load-path)))
          ;; Ensure M-X run-prolog and opening prolog files loads the prolog mode.
          (autoload 'run-prolog "qprolog-mode" "Start a (Quintus) Prolog sub-process." t)
          (autoload 'prolog-mode "qprolog-mode" "Major mode for editing (Quintus) Prolog programs." t)

          ;; ;; Tell the prolog mode that we should use the Quintus extensions
          ;; (setq prolog-system 'quintus)

          ;; Ensure that you get the QP Prolog mode when you visit a
          ;; .pl file or prolog.ini
          (setq auto-mode-alist (append '(("\\.pl$" . prolog-mode) ("prolog.ini$" . prolog-mode)) auto-mode-alist))

          ;; Tell the run-prolog where to find the quintus executable
          (if (and quintus-exe-path
                   (file-executable-p quintus-exe-path))
              (let ((exe-path
                     (or (and (fboundp 'win32-short-file-name)
                              (win32-short-file-name quintus-exe-path))
                         quintus-exe-path)))
                (setenv "QUINTUS_PROLOG_PATH" exe-path)))
    
          ;; Ensure the Quintus Prolog mode can find the on-line documentation
          (and quintus-info-dir (quintus-init-setup-info quintus-info-dir))


          ;; we want to use the emacs-based source-linked debugger
          ;; when running prolog under emacs.
          (add-hook 'comint-prolog-hook 'enable-prolog-source-debugger)
      
          ;; Put the Quintus exe folder on the PATH for processes (such as
          ;; M-x shell) started from Emacs.
          (if (not (and (boundp 'inhibit-quintus-bin-directory-on-PATH)

                        ;; By setting
                        ;; inhibit-quintus-bin-directory-on-PATH to 't you
                        ;; can inhibit the PATH hacking. This is mostly
                        ;; for the Quintus maintainers while debugging
                        ;; Quintus.
                        inhibit-quintus-bin-directory-on-PATH))
              (and quintus-bin-directory
                   (progn 
                     (setq exec-path (cons quintus-bin-directory exec-path))
                     (setenv "PATH" (concat quintus-bin-directory path-separator (getenv "PATH"))))))
          ))                            ; not dry-run
    ))

(defun quintus-init-setup-info (info-dir)
  (if (and info-dir
           (file-accessible-directory-p info-dir))
      ;; Info directories is a mess in XEmacs and even more so in
      ;; Emacs. Do the best we can.
      ;; Currently this will not work if Info has already been
      ;; initialized. This should not be a problem as long as this
      ;; file is loaded from the users .emacs file.
      (cond ((string-match "XEmacs\\|Lucid" emacs-version) ; XEmacs
             (if (boundp 'Info-directory-list)
                 (setq Info-directory-list (append Info-directory-list (list info-dir)))))
            (t                          ; FSF (GNU) Emacs
             (setq Info-default-directory-list (append Info-default-directory-list (list info-dir)))

             ;; Emacs (to 20.7 at least) ignores
             ;; Info-default-directory-list if INFOPATH is set in the
             ;; environment. As a workaround we add Quintus info dirs
             ;; to the environment variable.
             (if (getenv "INFOPATH")
                 (setenv "INFOPATH" (concat (getenv "INFOPATH") path-separator info-dir)))
             
             ))))



(quintus-init-emacs (and (boundp 'load-file-name) load-file-name) (getenv "QP_DEBUG_QP_SETUP"))

