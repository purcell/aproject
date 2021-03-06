;;; aproject.el --- A simple project tool for Emacs

;; Copyright (C) 2015 Vietor Liu

;; Author: Vietor Liu <vietor.liu@gmail.com>
;; Keywords: environment project
;; URL: https://github.com/vietor/aproject
;; Version: DEV

;; This file is not part of GNU Emacs.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library allows the user to use Emacs on multiple projects.
;; Any project has it's ".aproject" dirctory for store some files,
;; like: session, desktop, etc.

;;; Code:

(defconst aproject-dirname ".aproject")

(defvar aproject-project nil
  "The flag for aproject initialize as *PROJECT*.")
(defvar aproject-rootdir nil
  "The aproject's working directory.")
(defvar aproject-storedir nil
  "The aproject's store directory.")
(defvar aproject-before-change-hook nil
  "Hooks to run before aproject changed.")
(defvar aproject-after-change-hook nil
  "Hooks to run after aproject changed.")

(defun aproject-root-file (name)
  "Get the aproject's workding directory NAME file."
  (expand-file-name name aproject-rootdir))

(defun aproject-store-file (name)
  "Get the aproject's store directory NAME file."
  (expand-file-name name aproject-storedir))

(defmacro before-aproject-change (&rest body)
  "Add hook to aproject-before-change-hook, in BODY."
  `(add-hook 'aproject-before-change-hook (lambda () ,@body)))

(defmacro after-aproject-change (&rest body)
  "Add hook to aproject-after-change-hook, in BODY."
  `(add-hook 'aproject-after-change-hook (lambda () ,@body)))

(defun aproject-parse-switch ()
  "Parse aproject switch from command line."
  (let ((active nil))
    (when (member "-project" command-line-args)
      (setq active t)
      (setq command-line-args (delete "-project" command-line-args)))
    active))

(defun aproject-parse-rootdir ()
  "Parse rootdir directory from command line or use environment $PWD or $HOME."
  (let ((rootdir (getenv "PWD")))
    (unless rootdir
      (setq rootdir (getenv "HOME")))
    (when (> (length command-line-args) 1)
      (let ((dir (elt command-line-args (- (length command-line-args) 1))))
        (when (file-directory-p dir)
          (setq rootdir dir)
          (setq command-line-args (delete dir command-line-args)))))
    (expand-file-name rootdir)))

(defun aproject-kill-buffers-switch-scratch ()
  "Kill all buffers and switch scratch buffer."
  (delete-other-windows)
  (switch-to-buffer (get-buffer-create "*scratch*"))
  (mapc 'kill-buffer (cdr (buffer-list (current-buffer)))))

(defun aproject-change-rootdir (rootdir &optional storedir)
  "Change aproject's ROOTDIR directory, it can specific the STOREDIR."
  (unless (file-directory-p rootdir)
    (error "%s is not directory" rootdir))
  (unless storedir
    (setq storedir (expand-file-name aproject-dirname rootdir)))
  (unless (file-directory-p storedir)
    (make-directory storedir t))
  (when (stringp aproject-storedir)
    (run-hooks 'aproject-before-change-hook)
    (aproject-kill-buffers-switch-scratch))
  (cd rootdir)
  (setq aproject-rootdir rootdir)
  (setq aproject-storedir storedir)
  (run-hooks 'aproject-after-change-hook))

(defun aproject-auto-initialize ()
  "Auto initialize the aproject environment."
  (let* ((switch (aproject-parse-switch))
         (rootdir (aproject-parse-rootdir))
         (storedir (expand-file-name aproject-dirname rootdir)))
    (when (file-directory-p storedir)
      (setq switch t))
    (if switch
        (setq aproject-project t)
      (setq storedir (expand-file-name aproject-dirname user-emacs-directory)))
    (aproject-change-rootdir rootdir storedir)))

(add-hook 'after-init-hook 'aproject-auto-initialize)

(defun aproject-change-project ()
  "Change current project."
  (interactive)
  (let (rootdir)
    (setq rootdir (read-directory-name "Change to project directory: "))
    (when (or (equal "" rootdir)
              (not (file-accessible-directory-p rootdir)))
      (error "You not have permission to open directory"))
    (when (string-match "\/$" rootdir)
      (setq rootdir (replace-match "" t t rootdir)))
    (let ((len (length aproject-rootdir)))
      (when (eq t (compare-strings aproject-rootdir 0 len rootdir 0 len t))
        (error "You need change to difference project directory")))
    (aproject-change-rootdir rootdir)))

(provide 'aproject)
;;; aproject.el ends here
