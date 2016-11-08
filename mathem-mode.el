;; @(#) mathem-mode.el -- A major mode for editing Mathematica files

;; Copyright (C) 1998, Robert Harlander.  All rights reserved.

;; This file is intended to be used with GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

(defvar mathem-mode-version-string "2.3.6")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                      ;;
;;  mathem-mode                                                         ;;
;;                                                                      ;;
;;  (C) by Robert Harlander                                             ;;
;;                                                                      ;;
;;  comments, bug reports, suggestions, etc.                            ;;    
;;  to robert.harlander@cern.ch                                         ;;
;;                                                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                      ;;
;;  It consists of two parts: the first one deals with submission of    ;;
;;  MATHEMATICA commands directly from the source file to buffer        ;;
;;  *math*, the second part is mainly concerned with pretty (well...)   ;;
;;  indentation of the MATHEMATICA code and is essentially a copy of    ;;
;;  perl-mode from the EMACS distribution.                              ;;
;;  There is still a lot of code that is not used at all. This is       ;;
;;  because I only modified huge parts of perl-mode, but didn't really  ;;
;;  remove things that are not needed. So this is one of the things     ;;
;;  to do.                                                              ;;
;;                                                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                      ;;
;;  INSTALLATION:                                                       ;;
;;                                                                      ;;
;;  This program requires math.el.                                      ;;
;;                                                                      ;;
;;  Put this file as mathem-mode.el into your load-path and add the     ;;
;;  following lines to .emacs:                                          ;;
;;                                                                      ;;
;; (autoload 'mathem-mode "mathem-mode"                                 ;;
;;   "Major mode for editing MATHEMATICA-files" t)                      ;;
;; (setq auto-mode-alist (cons '("\\.m\$" . mathem-mode)                ;;
;;                                            auto-mode-alist))         ;;
;;                                                                      ;;
;; You may repeat the (setq ...) bracket with different entries for     ;;
;; "\\.m\$ (e.g., "\\.mat\$), depending on your favorite extensions     ;;
;; for MATHEMATICA files.                                               ;;
;;                                                                      ;;
;; mathem-mode should be faster when byte-compiled:                     ;;
;; M-x byte-compile-file                                                ;;
;;                                                                      ;;
;; If you don't like the indentation, put also                          ;;
;; (setq mathem-mode-auto-indent nil)                                   ;;
;; to your .emacs-file.                                                 ;;
;;                                                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                      ;;
;;  FUNCTIONS:                          KEY:                            ;;
;;                                                                      ;;
;;  math-buffer                         C-M-return                      ;;
;;  math-eval-active-region             C-c C-c                         ;;
;;  math-eval-block-or-line             M-return                        ;;
;;  math-eval-line                                                      ;;
;;  math-eval-expression                C-return                        ;;
;;  math-eval-undo                      C-c C-u                         ;;
;;  math-set-dir                                                        ;;
;;  math-recenter-output-buffer         S-select                        ;;
;;                                                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                      ;;
;;                                                                      ;;
;;  last modified:                                                      ;;
;;             	                                                        ;;
;;  Aug 24 2003 (rh) (v2.3.6):                                          ;;
;;  - bug fix in math-eval-expression:                                  ;;
;;    math-eval-count  ->   (number-to-string math-eval-count)          ;;
;;    otherwise problems in Linux 2.4.20                                ;;
;;  - comment-start  modified and  comment-padding  introduced          ;;
;;                                                                      ;;
;;  Oct 08 2001 (rh) (v2.3.6):                                          ;;
;;  - made the comma equivalent to the semi-colon as far as indentation ;;
;;    is concerned. Let's hope that now long lists don't get messed up  ;;
;;    any longer.                                                       ;;
;;                                                                      ;;
;;  Sep 13 2001 (rh) (v2.3.6):                                          ;;
;;  - replaced mathem-mode-syntax-table by the one from math.el.        ;; 
;;    Now comments are properly recognized for font-locking.            ;;
;;                                                                      ;;
;;  Jul 19 2000 (rh) (v2.3.5):                                          ;;
;;  - math-eval-region and math-buffer: clear the input cell before     ;;
;;    copying the command to the *math* buffer                          ;;
;;             	                                                        ;;
;;  Jun 24 1999 (rh) (v2.3.4):                                          ;;
;;  - mathem-beginning-of-function: regexp changed in order to avoid    ;;
;;    indentation troubles with commented lines within blocks.          ;;
;;             	                                                        ;;
;;  Feb  3 1999 (rh) (v2.3.3):                                          ;;
;;  - removed special indentation for Perl's loop labels of the form    ;;
;;    LOOP: foreach (@list) {<body>}                                    ;;
;;             	                                                        ;;
;;  Nov 19 1998 (rh) (v2.3.2):                                          ;;
;;  - math-eval-block changed: if block is shorter than one line,       ;;
;;    evaluate line instead                                             ;;
;;             	                                                        ;;
;;  Nov  6 1998 (rh):                                                   ;;
;;  - bug fixed in math-recenter-output-buffer:                         ;;
;;    if -offset was larger than (window-height), recenter didn't       ;;
;;    work properly                                                     ;;
;;             	                                                        ;;
;;  Nov  5 1998 (rh):                                                   ;;
;;  - load math.el to do syntax-check BEFORE submitting to math         ;;
;;  - this required to introduce the auxiliary buffer *mathem*          ;;
;;  - bug fixes                                                         ;;
;;             	                                                        ;;
;;  Nov  2 1998 (rh):							;;
;;  - removed problem with ^G's that occured with multiple statments.   ;;
;;    The simple solution: math-eval-region surrounds the region by     ;;
;;    brackets now                                                      ;;
;;                                                                      ;;
;;  Nov  1 1998 (rh):							;;
;;  - math-eval-block introduced					;;
;;  - math-looking-at-function introduced				;;
;;  - math-eval-block-or-line modified:					;;
;;    now evaluates block if 						;;
;;     (a) cursor is looking at a function				;;
;;     (b) cursor is at the end of a block				;;
;;  - math-eval-expression modified:                                    ;;
;;    now evaluates also terms like exp[4,5,j] etc.                     ;;
;;                                                                      ;;
;;  Sep 23 1998 (rh):                                                   ;;
;;  - math-eval-block-or-line added and bound to M-return               ;;
;;    instead of math-eval-line                                         ;;
;;  - math-eval-line code modified (functionality unchanged)            ;;
;;  - math-eval-undo modified                                           ;;
;;                                                                      ;;
;;  Aug 26 1998 (rh):                                                   ;;
;;  - bug fixes                                                         ;;
;;                                                                      ;;
;;  Apr  1 1998 (rh):                                                   ;;
;;  - recenter after sending inputs                                     ;;
;;                                                                      ;;
;;                                                                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'math)

(defvar mathem-mode-map ()
    "Keymap used in mathem mode.")

(defvar mathem-mode-auto-indent t
  "If t, auto-indentation is done for Mathematica files.")
(defvar math-eval-count 0)
(defvar math-buffer-name)
(defvar line-number)
(defvar math-tmp-buffer-name)
(defvar mathem-mode-syntax-table nil
  "Syntax table in use in mathem-mode buffers.")

(defun mathem-mode-version ()
  "Report on version of mathem-mode."
  (interactive)
  (message mathem-mode-version-string)
  )

(defun mathem-math () "If no Mathematica process is running, start one."
  (if (not (get-process "math"))
      (progn (load "math")
	     (math)
	     )))


(defun math-buffer () "Load the current buffer into Mathematica."
  (interactive)
  (mathem-math)
  (math-recenter-output-buffer nil -4)
  (setq math-buffer-name buffer-file-name)
  (set-buffer "*math*")
  (goto-char (point-max))
  (search-backward ":=")
  (forward-char 3)
  (delete-region (point) (point-max))
  (insert (concat "<<" math-buffer-name))
  (math-send-input)
)

(defun math-eval-active-region () "Send active region to Mathematica."
  (interactive)
  (math-eval-region (region-beginning) (region-end) nil)
)

(defun math-eval-region (beg end mathem-colon)
  "Send region defined by 'beg' and 'end' to Mathematica."
  (copy-region-as-kill beg end)
  (mathem-math)
  (save-excursion
    (set-buffer (get-buffer-create "*mathem*"))
    (setq math-eval-count (+ 1 math-eval-count))
    (insert (concat "\n\n$" (number-to-string math-eval-count) ">> "))
    (setq pmin (point))
    (insert "(")
    (yank)
    (insert ")")
    (if mathem-colon (insert ";"))
    (setq pmax (point))
    (check-math-syntax pmin pmax)
    (copy-region-as-kill pmin pmax)
    )
  (math-recenter-output-buffer nil (- -2 (abs (count-lines
						 beg end))))
  (set-buffer "*math*")
  (goto-char (point-max))
  (search-backward ":=")
  (forward-char 3)
  (delete-region (point) (point-max))
  (yank)
  
  ;; go to beginning of cell and delete comment lines:
  ;;
  (if (not (looking-at "In\[[0-9]*\]:="))
      (search-backward-regexp "In\[[0-9]*\]:="))
  (while (re-search-forward "\(\\*[^(\\*\))]*\\*\)" nil t)
    (replace-match "" nil nil))
  
  ;; go to beginning of cell and delete blank lines:
  ;;
  (if (not (looking-at "In\[[0-9]*\]:="))
      (search-backward-regexp "In\[[0-9]*\]:="))
  (delete-matching-lines "^ *$")
  (math-send-input))




(defun math-eval-line () "Send line to MATHEMATICA."
  (interactive)
  (save-excursion
    (beginning-of-line 1)
    (let ((beg (point)))
      (end-of-line)
      (math-eval-region beg (point) nil))
    ))

(defun math-eval-expression () "Evaluate expression at point."
  (interactive)
  (math-recenter-output-buffer nil -6)
  (save-excursion
    (forward-word 1)
    (backward-word 1)
    (let ((beg (point)))
      (forward-word 1)
      (if (looking-at "\\[") (forward-sexp 1))
;      (copy-region-as-kill beg (point))
      (math-eval-region beg (point) nil)
      )
;    (set-buffer "*math*")
;    (goto-char (point-max))
;    (yank)
;    (math-send-input)
    )
)

(defun math-eval-block-or-line (mathem-mode)
  "If cursor is on the left hand side of a function definition, evaluate whole 
definition. If cursor is behind ')' or ']', searches for matching parenthesis
and evaluates the whole block, including the left hand side of '=', 
if present. If block is shorter than one line, evaluates line instead."
 (interactive "p")
 (save-excursion
   (if (= (preceding-char) ?\;) (setq mathem-colon t) (setq mathem-colon nil))
   (if (looking-at "\)\\|\\]") (forward-char 1))
   (skip-chars-backward ";\t ")
   (if (memq (preceding-char) '(?\) ?\])) (math-eval-block mathem-colon)
     (if (math-looking-at-function)
	 (progn
	   (goto-char (math-looking-at-function))
	   (math-eval-block mathem-colon)
	   )
     (math-eval-line))
     )))

(defun math-eval-block (mathem-colon) 
  "If cursor is behind ')' or ']', evaluate block that is defined through
matching bracket, including left hand side of '=', if present."
  (interactive "p")
  (let ((opoint (point)) (apoint nil))
;    (forward-char 1)
    (backward-sexp 1)
    (if (looking-at "\\[") (backward-word 1))
    (setq apoint (point))
    (skip-chars-backward "\t \n")
    (if (= (preceding-char) ?=)
	(progn
	  (skip-chars-backward "\t :=")
	  (if (= (preceding-char) ?\]) (backward-sexp 1))
	  (backward-word 1)
	  ) 
      (goto-char apoint))
    (if (= (line-number (point)) (line-number opoint))
	(math-eval-line)
      (math-eval-region (point) opoint mathem-colon)))
  )

(defun math-looking-at-function () 
  "t if expression is the left hand side of a function definition."
  (interactive)
  (save-excursion
    (if (not (looking-at "\[\]; \]*$")) (forward-word 1))
    (if (looking-at "\\[") (forward-sexp 1))
    (if (not (looking-at "\[\]; \]*$")) (skip-chars-forward "\t "))
    (if (or (looking-at ":") (looking-at "="))
	(progn
	  (skip-chars-forward "\t :=")
	  (cond ((looking-at "[A-Za-z\n]")
		 (forward-word 1)
		 (if (looking-at "\\[")
		     (progn
		       (forward-sexp 1)
		       (if (looking-at "\[ \t\n\]*;") 
			   (progn
			     (skip-chars-forward " \t\n")
			     (forward-char 1)
			     ))
		       (point)
		       )
		   ))
		((looking-at "(")
		     (progn
		       (forward-sexp 1)
		       (if (looking-at "\[ \t\n\]*;") 
			   (progn
			     (skip-chars-forward " \t\n")
			     (forward-char 1)
			     ))
		       (point)
		       ))
		(t (= 1 0)))
	    )
  (= 1 0))))

(defun math-eval-undo () "Delete current cell."
  (interactive)
  (set-buffer "*math*")
  (goto-char (point-max))
  (if (not (looking-at "In\[[0-9]*\]:="))
      (search-backward-regexp "In\[[0-9]*\]:="))
  (kill-math-cell (point) nil)
  (math-send-input)
  (previous-line 1)
  (delete-line)
  (delete-line)
  (goto-char (point-max))
)

(defun math-set-dir (dir) "Set directory for buffer *math*."
  (interactive "DSetDirectory: ")
  (set-buffer "*math*")
  (setq default-directory dir)
  (goto-char (point-max))
  (insert (concat "SetDirectory[\"" dir "\"]"))
  (math-send-input)
)


(defun math-recenter-output-buffer (linenum offset)
  "Redisplay buffer of TeX job output so that most recent output can be seen.
The last line of the buffer is displayed on line LINE of the window,
or centered if LINE is nil. (math-recenter-output-buffer LINE)"
;;
  (interactive "P")
  (let ((math (get-buffer "*math*"))
	(old-buffer (current-buffer)))
    (if (null math)
	(message "No MATHEMATICA output buffer")
      (pop-to-buffer math)
      (bury-buffer math)
      (goto-char (point-max))
      (setq pos (+ (if linenum
			  (prefix-numeric-value linenum)
			(/ (window-height) 2))
		      (if offset
			  (prefix-numeric-value offset) 0)))
      (if (< pos 0) (setq pos 0))
      (recenter pos)
      (pop-to-buffer old-buffer))))

(defvar mathem-mode-abbrev-table nil
  "Abbrev table in use in mathem-mode buffers.")
(define-abbrev-table 'mathem-mode-abbrev-table ())

(defvar mathem-mode-map ()
  "Keymap used in Mathem mode.")
(if mathem-mode-map
    ()
  (setq mathem-mode-map (make-sparse-keymap))
  (define-key mathem-mode-map "\t" 'tab-to-tab-stop)
  (define-key mathem-mode-map [M-down] 'mathem-goto-math-window)
  (define-key mathem-mode-map "\M-\C-m" 'math-eval-block-or-line)
  (define-key mathem-mode-map [C-return] 'math-eval-expression)
  (define-key mathem-mode-map [C-M-return] 'math-buffer)
  (define-key mathem-mode-map "\C-c\C-c" 'math-eval-active-region)
  (define-key mathem-mode-map "\C-c\C-u" 'math-eval-undo)
  (define-key mathem-mode-map [S-select] 'math-recenter-output-buffer)
  (define-key mathem-mode-map [S-select] 'recenter-command)
  )


(defun mathem-goto-math-window () "Go to buffer *math*."
  (interactive)
  (if (window-live-p (get-buffer-window "*math*"))
      (progn
	(math-recenter-output-buffer nil -2)
	(select-window (get-buffer-window "*math*"))
	)
    (other-window 1)
    )
)

(defun recenter-command () ""
  (interactive)
  (math-recenter-output-buffer nil -2)
)

(defun line-number (pos) "Determines line number."
  (interactive "P")
  (if (not pos) (setq pos (point)))
  (save-restriction
    (widen)
    (save-excursion
      (beginning-of-line)
      (setq line-number (1+ (count-lines 1 pos)))))
  )

;;;###autoload
(defun mathem-mode ()
  "Major mode for editing Mathem code.
Expression and list commands understand all Mathem brackets.
Tab indents for Mathem code.
Comments are delimited with # ... \\n.
Paragraphs are separated by blank lines only.
Delete converts tabs to spaces as it moves back.
\\{mathem-mode-map}
Variables controlling indentation style:
 mathem-tab-always-indent
    Non-nil means TAB in Mathem mode should always indent the current line,
    regardless of where in the line point is when the TAB command is used.
 mathem-tab-to-comment
    Non-nil means that for lines which don't need indenting, TAB will
    either delete an empty comment, indent an existing comment, move
    to end-of-line, or if at end-of-line already, create a new comment.
 mathem-nochange
    Lines starting with this regular expression are not auto-indented.
 mathem-indent-level
    Indentation of Mathem statements within surrounding block.
    The surrounding block's indentation is the indentation
    of the line on which the open-brace appears.
 mathem-continued-statement-offset
    Extra indentation given to a substatement, such as the
    then-clause of an if or body of a while.
 mathem-continued-brace-offset
    Extra indentation given to a brace that starts a substatement.
    This is in addition to `mathem-continued-statement-offset'.
 mathem-brace-offset
    Extra indentation for line if it starts with an open brace.
 mathem-brace-imaginary-offset
    An open brace following other text is treated as if it were
    this far to the right of the start of its line.
 mathem-label-offset
    Extra indentation for line that is a label.

Various indentation styles:       K&R  BSD  BLK  GNU  LW
  mathem-indent-level                5    8    0    2    4
  mathem-continued-statement-offset  5    8    4    2    4
  mathem-continued-brace-offset      0    0    0    0   -4
  mathem-brace-offset               -5   -8    0    0    0
  mathem-brace-imaginary-offset      0    0    4    0    0
  mathem-label-offset               -5   -8   -2   -2   -2

Turning on Mathem mode runs the normal hook `mathem-mode-hook'."
  (interactive)
  (kill-all-local-variables)
  (use-local-map mathem-mode-map)
  (setq major-mode 'mathem-mode)
  (setq mode-name "MATHEM")
  (make-local-variable 'comment-start)
  (setq comment-start "(*")
  (make-local-variable 'comment-padding)
  (setq comment-padding 1)
  (make-local-variable 'comment-end)
  (setq comment-end "*)")
  (make-local-variable 'comment-column)
  (setq comment-column 32)
  (make-local-variable 'comment-start-skip)
;  (setq comment-start-skip "\\(^\\|\\s-\\);?\(\\*+ *")
  (setq comment-start-skip "(\\*+ *")
  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)
  (if mathem-mode-auto-indent
      (progn
	(setq local-abbrev-table mathem-mode-abbrev-table)
	(set-syntax-table mathem-mode-syntax-table)
	(make-local-variable 'paragraph-start)
	(setq paragraph-start (concat "$\\|" page-delimiter))
	(make-local-variable 'paragraph-separate)
	(setq paragraph-separate paragraph-start)
	(make-local-variable 'paragraph-ignore-fill-prefix)
	(setq paragraph-ignore-fill-prefix t)
	(make-local-variable 'indent-line-function)
	(setq indent-line-function 'mathem-indent-line)
	(make-local-variable 'require-final-newline)
	(setq require-final-newline t)
	(make-local-variable 'comment-indent-function)
	(define-key mathem-mode-map "\e\C-q" 'indent-mathem-exp)
	(define-key mathem-mode-map "\177" 'backward-delete-char-untabify)
	(define-key mathem-mode-map "\t" 'mathem-indent-command)
	(define-key mathem-mode-map "{" 'electric-mathem-terminator)
	(define-key mathem-mode-map "}" 'electric-mathem-terminator)
	(define-key mathem-mode-map "[" 'electric-mathem-terminator)
	(define-key mathem-mode-map "]" 'electric-mathem-terminator)
	(define-key mathem-mode-map ";" 'electric-mathem-terminator)
	(define-key mathem-mode-map "," 'electric-mathem-terminator)
	(define-key mathem-mode-map "\e\C-a" 'mathem-beginning-of-function)
	(define-key mathem-mode-map "\e\C-e" 'mathem-end-of-function)
	(define-key mathem-mode-map "\e\C-h" 'mark-mathem-function)
	(setq comment-indent-function 'mathem-comment-indent)
	(make-local-variable 'parse-sexp-ignore-comments)
	(setq parse-sexp-ignore-comments t)
	;; Tell font-lock.el how to handle Mathem.
	(make-local-variable 'font-lock-defaults)
;	(setq font-lock-defaults '((mathem-font-lock-keywords
;				    mathem-font-lock-keywords-1
;				    mathem-font-lock-keywords-2)
;				   nil nil ((?\_ . "w"))))
	(setq font-lock-defaults 
	      '((mathem-font-lock-keywords
		 mathem-font-lock-keywords-1
		 mathem-font-lock-keywords-2)
		nil nil ((?\_ . "w")) beginning-of-defun
		(font-lock-comment-start-regexp . "^([*]\\|[ \t]([*]")))
	;; Tell imenu how to handle Mathem.
	(make-local-variable 'imenu-generic-expression)
	(setq imenu-generic-expression mathem-imenu-generic-expression)
	))
  (run-hooks 'mathem-mode-hook)
  )

;;----------------------------------------------------------------------
;;
;; The following is taken from PERL mode and was slightly adjusted
;; by rh.
;;
;;----------------------------------------------------------------------

(defvar mathem-mode-syntax-table nil
  "Syntax table used while in mathem-mode.")

(if mathem-mode-syntax-table
    ()
  (setq mathem-mode-syntax-table (make-syntax-table))
  (modify-syntax-entry ?% "." mathem-mode-syntax-table)
  (modify-syntax-entry ?& "." mathem-mode-syntax-table)
  (modify-syntax-entry ?* ". 23" mathem-mode-syntax-table) ;allow for (* comment *)
  (modify-syntax-entry ?+ "." mathem-mode-syntax-table)
  (modify-syntax-entry ?- "." mathem-mode-syntax-table)
  (modify-syntax-entry ?/ "." mathem-mode-syntax-table)
  (modify-syntax-entry ?< "." mathem-mode-syntax-table)
  (modify-syntax-entry ?= "." mathem-mode-syntax-table)
  (modify-syntax-entry ?> "." mathem-mode-syntax-table)
  (modify-syntax-entry ?_ "." mathem-mode-syntax-table)
  (modify-syntax-entry ?\| "." mathem-mode-syntax-table)
  (modify-syntax-entry ?\` "_" mathem-mode-syntax-table) ; Mathematica context symbol
  (modify-syntax-entry ?\( "()1" mathem-mode-syntax-table) ;allow for (* comment *)
  (modify-syntax-entry ?\) ")(4" mathem-mode-syntax-table)) ;allow for (* comment *)

(defvar mathem-imenu-generic-expression
  '(
;    ;; Functions
;    (nil "^sub\\s-+\\([-A-Za-z0-9+_:]+\\)\\(\\s-\\|\n\\)*{" 1 )
;    ;;Variables
;    ("Variables" "^\\([$@%][-A-Za-z0-9+_:]+\\)\\s-*=" 1 )
;    ("Packages" "^package\\s-+\\([-A-Za-z0-9+_:]+\\);" 1 )
    )
  "Imenu generic expression for Mathem mode.  See `imenu-generic-expression'.")

;; Regexps updated with help from Tom Tromey <tromey@cambric.colorado.edu> and
;; Jim Campbell <jec@murzim.ca.boeing.com>.

(defconst mathem-font-lock-keywords-1
  '(;; What is this for?
    ;;("\\(--- .* ---\\|=== .* ===\\)" . font-lock-string-face)
    ;;
    ;; Fontify preprocessor statements as we do in `c-font-lock-keywords'.
    ;; Ilya Zakharevich <ilya@math.ohio-state.edu> thinks this is a bad idea.
    ;;
    ;; Fontify function and package names in declarations.
;    ("\\<\\(package\\|sub\\)\\>[ \t]*\\(\\sw+\\)?"
;     (1 font-lock-keyword-face) (2 font-lock-function-name-face nil t))
;    ("\\<\\(import\\|no\\|require\\|use\\)\\>[ \t]*\\(\\sw+\\)?"
;     (1 font-lock-keyword-face) (2 font-lock-reference-face nil t))
    )
  "Subdued level highlighting for Mathem mode.")

(defconst mathem-font-lock-keywords-2
  (append mathem-font-lock-keywords-1
   (list
    ;;
    ;; Fontify keywords, except those fontified otherwise.
;   (make-regexp '("if" "until" "while" "elsif" "else" "unless" "do" "dump"
;  "for" "foreach" "exit" "die"
;  "BEGIN" "END" "return" "exec" "eval"))
;;    (concat "\\<\\("
;;	    "BEGIN\\|END\\|d\\(ie\\|o\\|ump\\)\\|"
;;	    "e\\(ls\\(e\\|if\\)\\|val\\|x\\(ec\\|it\\)\\)\\|"
;;	    "for\\(\\|each\\)\\|if\\|return\\|un\\(less\\|til\\)\\|while"
;;	    "\\)\\>")
; (search-forward-regexp "\\([a-zA-Z][a-zA-Z0-9]*\\_\\)")

    ;; parameters:  var_
    '("\\([a-zA-Z][a-zA-Z0-9]*\\_\\)" 1 font-lock-constant-face)
    ;; functions: func[...], Expand[...]
    '("\\([a-zA-Z0-9]+\\)\\[" 1 font-lock-function-name-face)
    '("\\(\\[\\|\\]\\)" 1 font-lock-constant-face)
    '("\\((\\|)\\)" 1 font-lock-reference-face)
    '("\\(\\{\\|\\}\\)" 1 font-lock-type-face)
    '("\\([a-zA-Z0-9]+\\)" 1 font-lock-variable-name-face)
    ;; filenames: <<filename.m
    '("<< *\\([^; ]+\\)\\($\\|[; ]\\)" 1 font-lock-string-face)
    ;;
;    '("\\([a-zA-Z][a-zA-Z0-9]*\\)\\($\\|[^[a-zA-Z0-9]\\)" 1 
;      font-lock-variable-name-face)
    ))
  "Gaudy level highlighting for Mathem mode.")

(defvar mathem-font-lock-keywords mathem-font-lock-keywords-1
  "Default expressions to highlight in Mathem mode.")


(defvar mathem-indent-level 4
  "*Indentation of Mathem statements with respect to containing block.")
(defvar mathem-continued-statement-offset 4
  "*Extra indent for lines not starting new statements.")
(defvar mathem-continued-brace-offset -4
  "*Extra indent for substatements that start with open-braces.
This is in addition to `mathem-continued-statement-offset'.")
(defvar mathem-brace-offset 0
  "*Extra indentation for braces, compared with other text in same context.")
(defvar mathem-brace-imaginary-offset 0
  "*Imagined indentation of an open brace that actually follows a statement.")
(defvar mathem-label-offset -2
  "*Offset of Mathem label lines relative to usual indentation.")

(defvar mathem-tab-always-indent t
  "*Non-nil means TAB in Mathem mode always indents the current line.
Otherwise it inserts a tab character if you type it past the first
nonwhite character on the line.")

;; I changed the default to nil for consistency with general Emacs
;; conventions -- rms.
(defvar mathem-tab-to-comment nil
  "*Non-nil means TAB moves to eol or makes a comment in some cases.
For lines which don't need indenting, TAB either indents an
existing comment, moves to end-of-line, or if at end-of-line already,
create a new comment.")

(defvar mathem-nochange "\(\\*\\|\\*\)"
  "*Lines starting with this regular expression are not auto-indented.")

;; This is used by indent-for-comment
;; to decide how much to indent a comment in Mathem code
;; based on its context.
(defun mathem-comment-indent ()
  (if (and (bolp) (not (eolp)))
      0					;Existing comment at bol stays there.
    (save-excursion
      (skip-chars-backward " \t")
      (max (if (bolp)			;Else indent at comment column
	       0			; except leave at least one space if
	     (1+ (current-column)))	; not at beginning of line.
	   comment-column))))

(defun electric-mathem-terminator (arg)
  "Insert character and adjust indentation.
If at end-of-line, and not in a comment or a quote, correct the's indentation."
  (interactive "P")
  (let ((insertpos (point)))
    (and (not arg)			; decide whether to indent
	 (eolp)
	 (save-excursion
	   (beginning-of-line)
	   (and (not			; eliminate comments quickly
		 (re-search-forward comment-start-skip insertpos t))
		(or (/= last-command-char ?:)
		    ;; Colon is special only after a label ....
		    (looking-at "\\s-*\\(\\w\\|\\s_\\)+$"))
		(let ((pps (parse-partial-sexp
			    (mathem-beginning-of-function) insertpos)))
		  (not (or (nth 3 pps) (nth 4 pps) (nth 5 pps))))))
	 (progn				; must insert, indent, delete
	   (insert-char last-command-char 1)
	   (mathem-indent-line)
	   (delete-char -1))))
  (self-insert-command (prefix-numeric-value arg)))

;; not used anymore, but may be useful someday:
;;(defun mathem-inside-parens-p ()
;;  (condition-case ()
;;      (save-excursion
;;	(save-restriction
;;	  (narrow-to-region (point)
;;			    (mathem-beginning-of-function))
;;	  (goto-char (point-max))
;;	  (= (char-after (or (scan-lists (point) -1 1) (point-min))) ?\()))
;;    (error nil)))

(defun mathem-indent-command (&optional arg)
  "Indent current line as Mathem code, or optionally, insert a tab character.

With an argument, indent the current line, regardless of other options.

If `mathem-tab-always-indent' is nil and point is not in the indentation
area at the beginning of the line, simply insert a tab.

Otherwise, indent the current line.  If point was within the indentation
area it is moved to the end of the indentation area.  If the line was
already indented promathemy and point was not within the indentation area,
and if `mathem-tab-to-comment' is non-nil (the default), then do the first
possible action from the following list:

  1) delete an empty comment
  2) move forward to start of comment, indenting if necessary
  3) move forward to end of line
  4) create an empty comment
  5) move backward to start of comment, indenting if necessary."
  (interactive "P")
  (if arg				; If arg, just indent this line
      (mathem-indent-line "\f")
    (if (and (not mathem-tab-always-indent)
	     (> (current-column) (current-indentation)))
	(insert-tab)
      (let (bof lsexp delta (oldpnt (point)))
	(beginning-of-line)
	(setq lsexp (point))
	(setq bof (mathem-beginning-of-function))
	(goto-char oldpnt)
	(setq delta (mathem-indent-line "\f\\|\(\\*\\|\\*\)" bof))
	(and mathem-tab-to-comment
	     (= oldpnt (point))		; done if point moved
	     (if (listp delta)		; if line starts in a quoted string
		 (setq lsexp (or (nth 2 delta) bof))
	       (= delta 0))		; done if indenting occurred
	     (let (eol state)
	       (end-of-line)
	       (setq eol (point))
	       (if (= (char-after bof) ?=)
		   (if (= oldpnt eol)
		       (message "In a format statement"))
		 (setq state (parse-partial-sexp lsexp eol))
		 (if (nth 3 state)
		     (if (= oldpnt eol)	; already at eol in a string
			 (message "In a string which starts with a %c."
				  (nth 3 state)))
		   (if (not (nth 4 state))
		       (if (= oldpnt eol) ; no comment, create one?
			   (indent-for-comment))
		     (beginning-of-line)
		     (if (re-search-forward comment-start-skip eol 'move)
			 (if (eolp)
			     (progn	; kill existing comment
			       (goto-char (match-beginning 0))
			       (skip-chars-backward " \t")
			       (kill-region (point) eol))
			   (if (or (< oldpnt (point)) (= oldpnt eol))
			       (indent-for-comment) ; indent existing comment
			     (end-of-line)))
		       (if (/= oldpnt eol)
			   (end-of-line)
			 (message "Use backslash to quote # characters.")
			 (ding t))))))))))))

(defun mathem-indent-line (&optional nochange parse-start)
  "Indent current line as Mathem code.
Return the amount the indentation
changed by, or (parse-state) if line starts in a quoted string."
  (let ((case-fold-search nil)
	(pos (- (point-max) (point)))
	(bof (or parse-start (save-excursion (mathem-beginning-of-function))))
	beg indent shift-amt)
    (beginning-of-line)
    (setq beg (point))
    (setq shift-amt
	  (cond ((= (char-after bof) ?=) 0)
		((listp (setq indent (calculate-mathem-indent bof))) indent)
		((looking-at (or nochange mathem-nochange)) 0)
		(t
		 (skip-chars-forward " \t\f")
		 (cond 
					; the following has been commented out
					; by rh on Feb 3,1999:
					;((looking-at "\\(\\w\\|\\s_\\)+:")
					;(setq indent (max 1 
					;(+ indent mathem-label-offset))))
		       ((or (= (following-char) ?}) (= (following-char) ?\]))
			(setq indent (- indent mathem-indent-level)))
		       ((or (= (following-char) ?{) (= (following-char) ?\[))
			(setq indent (+ indent mathem-brace-offset))))
		 (- indent (current-column)))))
    (skip-chars-forward " \t\f")
    (if (and (numberp shift-amt) (/= 0 shift-amt))
	(progn (delete-region beg (point))
	       (indent-to indent)))
    ;; If initial point was within line's indentation,
    ;; position after the indentation.  Else stay at same point in text.
    (if (> (- (point-max) pos) (point))
	(goto-char (- (point-max) pos)))
    shift-amt))

(defun nn () "" (interactive) (load-library "mathem-mode") (mathem-mode))

(defun calculate-mathem-indent (&optional parse-start)
  "Return appropriate indentation for current line as Mathem code.
In usual case returns an integer: the column to indent to.
Returns (parse-state) if line starts inside a string."
  (save-excursion
    (beginning-of-line)
    (let ((indent-point (point))
	  (case-fold-search nil)
	  (colon-line-end 0)
	  state containing-sexp)
      (if parse-start			;used to avoid searching
	  (goto-char parse-start)
	(mathem-beginning-of-function))
      (while (< (point) indent-point)	;repeat until right sexp
	(setq parse-start (point))
	(setq state (parse-partial-sexp (point) indent-point 0))
; state = (depth_in_parens innermost_containing_list last_complete_sexp
;          string_terminator_or_nil inside_commentp following_quotep
;          minimum_paren-depth_this_scan)
; Parsing stops if depth in parentheses becomes equal to third arg.
	(setq containing-sexp (nth 1 state)))
      (cond ((nth 3 state) state)	; In a quoted string?
	    ((null containing-sexp)	; Line is at top level.
	     (skip-chars-forward " \t\f")
	     (if (or (= (following-char) ?{) (= (following-char) ?\[))
		 0   ; move to beginning of line if it starts a function body
	       ;; indent a little if this is a continuation line
	       (mathem-backward-to-noncomment)
	       (if (or (bobp)
		       (memq (preceding-char) '(?\; ?\] ?\,)))
		   0 mathem-continued-statement-offset)))
	    ((and (/= (char-after containing-sexp) ?{)
		 (/= (char-after containing-sexp) ?\[))
	     ;; line is expression, not statement:
	     ;; indent to just after the surrounding open.
	     (goto-char (1+ containing-sexp))
	     (current-column))
	    (t
	     ;; Statement level.  Is it a continuation or a new statement?
	     ;; Find previous non-comment character.
	     (mathem-backward-to-noncomment)
	     ;; Back up over label lines, since they don't
	     ;; affect whether our line is a continuation.
;	     (while (or (eq (preceding-char) ?\,)
;			(and (eq (preceding-char) ?:)
;			     (memq (char-syntax (char-after (- (point) 2)))
;				   '(?w ?_))))
;	       (if (eq (preceding-char) ?\,)
;		   (mathem-backward-to-start-of-continued-exp containing-sexp)
;		 (beginning-of-line))
;	       (mathem-backward-to-noncomment))
	     ;; Now we get the answer.
	     (if (not (memq (preceding-char) '(?\; ?\[ ?\] ?\,)))
		 ;; This line is continuation of preceding line's statement;
		 ;; indent  mathem-continued-statement-offset  more than the
		 ;; previous line of the statement.
		 (progn
		   (mathem-backward-to-start-of-continued-exp containing-sexp)
		   (+ mathem-continued-statement-offset (current-column)
		      (if (save-excursion (goto-char indent-point)
					  (or (looking-at "[ \t]*{")
					      (looking-at "[ \t]*\\[")))
			  mathem-continued-brace-offset 0)))
	       ;; This line starts a new statement.
	       ;; Position at last unclosed open.
	       (goto-char containing-sexp)
	       (or
		 ;; If open paren is in col 0, close brace is special
		 (and (bolp)
		      (save-excursion (goto-char indent-point)
				      (or (looking-at "[ \t]*}")
					  (looking-at "[ \t]*\\]")))
		      mathem-indent-level)
		 ;; Is line first statement after an open-brace?
		 ;; If no, find that first statement and indent like it.
		 (save-excursion
		   (forward-char 1)
		   ;; Skip over comments and labels following openbrace.
		   (while (progn
			    (skip-chars-forward " \t\f\n")
			    (cond ((or (looking-at "\(\\*")
				       (looking-at "\\*\)"))
				   (forward-line 1) t)
				  ((looking-at "\\(\\w\\|\\s_\\)+:")
				   (save-excursion
				     (end-of-line)
				     (setq colon-line-end (point)))
				   (search-forward ":")))))
		   ;; The first following code counts
		   ;; if it is before the line we want to indent.
		   (and (< (point) indent-point)
			(if (> colon-line-end (point))
			    (- (current-indentation) mathem-label-offset)
			  (current-column))))
		 ;; If no previous statement,
		 ;; indent it relative to line brace is on.
		 ;; For open paren in column zero, don't let statement
		 ;; start there too.  If mathem-indent-level is zero,
		 ;; use mathem-brace-offset + mathem-continued-statement-offset
		 ;; For open-braces not the first thing in a line,
		 ;; add in mathem-brace-imaginary-offset.
		 (+ (if (and (bolp) (zerop mathem-indent-level))
			(+ mathem-brace-offset mathem-continued-statement-offset)
		      mathem-indent-level)
		    ;; Move back over whitespace before the openbrace.
		    ;; If openbrace is not first nonwhite thing on the line,
		    ;; add the mathem-brace-imaginary-offset.
		    (progn (skip-chars-backward " \t")
			   (if (bolp) 0 mathem-brace-imaginary-offset))
		    ;; If the openbrace is preceded by a parenthesized exp,
		    ;; move to the beginning of that;
		    ;; possibly a different line
		    (progn
		      (if (eq (preceding-char) ?\))
			  (forward-sexp -1))
		      ;; Get initial indentation of the line we are on.
		      (current-indentation))))))))))

(defun mathem-backward-to-noncomment ()
  ;;
  ;; completely changed to work with MATHEMATICA comments (rh, Apr 1998)
  ;;
  "Move point backward to after the first non-white-space, skipping comments."
  (interactive)
  (let (opoint stop bcom ecom)
    (while (not stop)
      (skip-chars-backward " \t\f\n")
      (setq opoint (point))
      (setq bcom (search-backward "(*" (point-min) t))
      (if (not bcom) (setq bcom 0))
      (goto-char opoint)
      (setq ecom (search-backward "*)" (point-min) t))
      (if (not ecom) (setq ecom 0))
      (goto-char opoint)
      (if (< ecom bcom) (goto-char bcom)
	(if (= (+ 2 ecom) opoint) (goto-char ecom)
	  (setq stop 1)))
      )))

(defun mathem-backward-to-noncomment-1 ()
  ;;
  ;; old version of mathem-backward-to-noncomment
  ;;
  "Move point backward to after the first non-white-space, skipping comments."
  (interactive)
  (let (opoint stop)
    (while (not stop)
      (setq opoint (point))
      (beginning-of-line)
      (if (re-search-forward comment-start-skip opoint 'move 1)
	  (progn (goto-char (match-end 1))
		 (skip-chars-forward ";")))
      (skip-chars-backward " \t\f")
      (setq stop (or (bobp)
		     (not (bolp))
		     (forward-char -1))))))

(defun mathem-backward-to-start-of-continued-exp (lim)
  (if (= (preceding-char) ?\))
      (forward-sexp -1))
  (beginning-of-line)
  (if (<= (point) lim)
      (goto-char (1+ lim)))
  (skip-chars-forward " \t\f"))

;; note: this may be slower than the c-mode version, but I can understand it.
(defun indent-mathem-exp ()
  "Indent each line of the Mathem grouping following point."
  (interactive)
  (let* ((case-fold-search nil)
	 (oldpnt (point-marker))
	 (bof-mark (save-excursion
		     (end-of-line 2)
		     (mathem-beginning-of-function)
		     (point-marker)))
	 eol last-mark lsexp-mark delta)
    (if (= (char-after (marker-position bof-mark)) ?=)
	(message "Can't indent a format statement")
      (message "Indenting Mathem expression...")
      (save-excursion (end-of-line) (setq eol (point)))
      (save-excursion			; locate matching close paren
	(while (and (not (eobp)) (<= (point) eol))
	  (parse-partial-sexp (point) (point-max) 0))
	(setq last-mark (point-marker)))
      (setq lsexp-mark bof-mark)
      (beginning-of-line)
      (while (< (point) (marker-position last-mark))
	(setq delta (mathem-indent-line nil (marker-position bof-mark)))
	(if (numberp delta)		; unquoted start-of-line?
	    (progn
	      (if (eolp)
		  (delete-horizontal-space))
	      (setq lsexp-mark (point-marker))))
	(end-of-line)
	(setq eol (point))
	(if (nth 4 (parse-partial-sexp (marker-position lsexp-mark) eol))
	    (progn			; line ends in a comment
	      (beginning-of-line)
	      (if (or (and (not (looking-at "\\s-*\(\\*"))
			   (not (looking-at "\\s-*\\*\)")))
		      (listp delta)
		      (and (/= 0 delta)
			   (= (- (current-indentation) delta) comment-column)))
		  (if (re-search-forward comment-start-skip eol t)
		      (indent-for-comment))))) ; indent existing comment
	(forward-line 1))
      (goto-char (marker-position oldpnt))
      (message "Indenting Mathem expression...done"))))

(defun mathem-beginning-of-function (&optional arg)
  "Move backward to next beginning-of-function, or as far as possible.
With argument, repeat that many times; negative args move forward.
Returns new value of point in all cases."
  (interactive "p")
  (or arg (setq arg 1))
  (if (< arg 0) (forward-char 1))
  (and (/= arg 0)
       (re-search-backward "^\\s-*sub\\b[^{]+{\\|^\\s-*format\\b[^=]*=\\|^\\."
;       (re-search-backward ""
			   nil 'move arg)
       (goto-char (1- (match-end 0))))
  (point))

;; note: this routine is adapted directly from emacs lisp.el, end-of-defun;
;; no bugs have been removed :-)
(defun mathem-end-of-function (&optional arg)
  "Move forward to next end-of-function.
The end of a function is found by moving forward from the beginning of one.
With argument, repeat that many times; negative args move backward."
  (interactive "p")
  (or arg (setq arg 1))
  (let ((first t))
    (while (and (> arg 0) (< (point) (point-max)))
      (let ((pos (point)) npos)
	(while (progn
		(if (and first
			 (progn
			  (forward-char 1)
			  (mathem-beginning-of-function 1)
			  (not (bobp))))
		    nil
		  (or (bobp) (forward-char -1))
		  (mathem-beginning-of-function -1))
		(setq first nil)
		(forward-list 1)
		(skip-chars-forward " \t")
		(<= (point) pos))))
      (setq arg (1- arg)))
    (while (< arg 0)
      (let ((pos (point)))
	(mathem-beginning-of-function 1)
	(forward-sexp 1)
	(forward-line 1)
	(if (>= (point) pos)
	    (if (progn (mathem-beginning-of-function 2) (not (bobp)))
		(progn
		  (forward-list 1)
		  (skip-chars-forward " \t")
		  )
	      (goto-char (point-min)))))
      (setq arg (1+ arg)))))

(defun mark-mathem-function ()
  "Put mark at end of Mathem function, point at beginning."
  (interactive)
  (push-mark (point))
  (mathem-end-of-function)
  (push-mark (point))
  (mathem-beginning-of-function)
  (backward-paragraph)
  )

;;;;;;;; That's all, folks! ;;;;;;;;;
