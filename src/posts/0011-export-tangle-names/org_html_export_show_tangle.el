(defun my-add-link-to-tangled-files (backend)
  "Add a link just before source code block with tangled files.
BACKEND is the export backend. Used as symbol."
  (while ;; (re-search-forward )
      (re-search-forward "^\\( *\\)#\\+begin_src .*:tangle \\([^\s\n]*\\)" nil t)
    (replace-match "\\1#+CAPTION: [[./\\2][=\\2=]]\n\\&")))

(add-hook 'org-export-before-processing-hook
          'my-add-link-to-tangled-files)
