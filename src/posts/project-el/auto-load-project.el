;;; auto-load-project.el --- Auto load elisp file on project open

;; Copyright © 2019 Yann Esposito <yann.esposito@gmail.com>

;;; Commentary:
;;

;;; Code:

(provide :auto-load-project)

(require 'projectile)

(defvar y/trusted-gpg-key-fingerprints
  '("448E9FEF4F5B86DE79C1669B0000000000000000")
  "The list of GPG fingerprint you trust when decrypting a gpg file.
           You can retrieve the fingerprints of your own private keys
           with: `gpg --list-secret-keys' (take care of removing the
           spaces when copy/pasting here)")

(defun y/get-encryption-key (file)
  "given a gpg encrypted file, returns the fingerprint of
           they key that encrypted it"
  (string-trim-right
   (shell-command-to-string
    (concat
     "gpg --status-fd 1 --decrypt -o /dev/null " file " 2>/dev/null"
     "|grep DECRYPTION_KEY"
     "|awk '{print $4}'"))))

(defun y/trusted-gpg-origin-p (file)
  "Returns true if the file is encrypted with a trusted key"
  (member (y/get-encryption-key file) y/trusted-gpg-key-fingerprints))


(defconst y/project-file ".project.el.gpg"
  "Project configuration file name.")

(defun y/init-project-el-auto-load ()
  "Initialize the autoload of .project.el.gpg for projects."

  (with-eval-after-load 'projectile

    (defvar y/loaded-projects (list)
      "Projects that have been loaded by `y/load-project-file'.")

    (defun y/load-project-file ()
      "Loads the `y/project-file' for a project. This is run once
           after the project is loaded signifying project setup."
      (interactive)
      (when (projectile-project-p)
        (lexical-let* ((current-project-root (projectile-project-root))
                       (project-init-file (expand-file-name y/project-file current-project-root)))
          (when (and (not (member current-project-root y/loaded-projects))
                     (file-exists-p project-init-file)
                     (y/trusted-gpg-origin-p project-init-file))
            (message "Loading project init file for %s" (projectile-project-name))
            (condition-case ex
                (progn (load project-init-file)
                       (add-to-list 'y/loaded-projects current-project-root)
                       (message "%s loaded successfully" project-init-file))
              ('error
               (message
                "There was an error loading %s: %s"
                project-init-file
                (error-message-string ex))))))))
    (add-hook 'find-file-hook #'y/load-project-file t)
    (add-hook 'dired-mode-hook #'y/load-project-file t)))

(provide 'auto-load-project)

;;; auto-load-project.el ends here
