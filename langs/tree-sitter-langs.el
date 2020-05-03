;;; tree-sitter-langs.el --- Grammar bundle for tree-sitter -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2020 Tuấn-Anh Nguyễn
;;
;; Author: Tuấn-Anh Nguyễn <ubolonton@gmail.com>
;; Keywords: languages tools parsers tree-sitter
;; Homepage: https://github.com/ubolonton/emacs-tree-sitter
;; Version: 0.2.0
;; Package-Requires: ((emacs "25.1") (tree-sitter "0.7.0"))
;; License: MIT

;;; Commentary:

;; This is a convenient bundle of language grammars and queries for
;; `tree-sitter'. It serves as an interim distribution mechanism, until
;; `tree-sitter' is widespread enough for language major modes to include these
;; definitions on their own.
;;
;; Basically it's a multi-step process:
;;
;; 1. `tree-sitter-langs' populates global registries of grammars and queries.
;;    These global registries are defined by `tree-sitter-mode' and other
;;    `tree-sitter'-based language-agnostic minor modes, to extend existing
;;    major modes.
;;
;; 2. New `tree-sitter'-based language-specific minor modes use these global
;;    registries to extend existing major modes.
;;
;; 3. Major modes adopt new `tree-sitter'-based features, and distribute the
;;    grammars and queries on their own. They can either put these definitions
;;    in the global registries, or keep using them only internally.

;;; Code:

(require 'cl-lib)

(require 'tree-sitter)
(require 'tree-sitter-load)
(require 'tree-sitter-hl)

(require 'tree-sitter-langs-build)

(eval-when-compile
  (require 'pcase))

(defun tree-sitter-langs-ensure (lang-symbol)
  "Return the language object identified by LANG-SYMBOL.
If it cannot be loaded, this function tries to compile the grammar.

See `tree-sitter-langs-repos'."
  (unwind-protect
      (condition-case nil
          (tree-sitter-require lang-symbol)
        (error
         (display-warning 'tree-sitter-test
                          (format "Could not load grammar for `%s', trying to compile it"
                                  lang-symbol))
         (tree-sitter-langs-compile lang-symbol)
         (tree-sitter-require lang-symbol)))
    (tree-sitter-langs-copy-query lang-symbol)))

;;; Add the bundle directory.
(cl-pushnew tree-sitter-langs--bin-dir
            tree-sitter-load-path)

;;; Link known major modes to languages in the bundle.
(pcase-dolist
    (`(,major-mode . ,lang-symbol)
     (reverse '((agda-mode       . agda)
                (sh-mode         . bash)
                (c-mode          . c)
                (c++-mode        . cpp)
                (css-mode        . css)
                (go-mode         . go)
                (haskell-mode    . haskell)
                (html-mode       . html)
                (java-mode       . java)
                (js-mode         . javascript)
                (js2-mode        . javascript)
                (json-mode       . json)
                (julia-mode      . julia)
                (ocaml-mode      . ocaml)
                (php-mode        . php)
                (python-mode     . python)
                (ruby-mode       . ruby)
                (rust-mode       . rust)
                (scala-mode      . scala)
                (swift-mode      . swift)
                (typescript-mode . typescript))))
  (setf (map-elt tree-sitter-major-mode-language-alist major-mode)
        lang-symbol))

(defun tree-sitter-langs--hl-default-patterns (lang-symbol)
  "Return default syntax highlighting patterns for LANG-SYMBOL."
  (let ((query-path (concat (file-name-as-directory
                             (concat tree-sitter-langs--queries-dir
                                     (symbol-name lang-symbol)))
                            "highlights.scm")))
    (with-temp-buffer
      (insert-file-contents query-path)
      (buffer-string))))

(defun tree-sitter-langs--set-hl-default-patterns (&rest _args)
  "Use syntax highlighting patterns provided by `tree-sitter-langs'."
  (unless tree-sitter-hl-default-patterns
    (let ((lang-symbol (alist-get major-mode tree-sitter-major-mode-language-alist)))
      (setq tree-sitter-hl-default-patterns
            (tree-sitter-langs--hl-default-patterns lang-symbol)))))

(advice-add 'tree-sitter-hl--setup :before
            #'tree-sitter-langs--set-hl-default-patterns)

(provide 'tree-sitter-langs)
;;; tree-sitter-langs.el ends here
