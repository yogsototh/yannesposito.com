;; sign it with
;; gpg --local-user yann@esposito.host --output project.el.sig --detach-sign project.el
(setq domainname "https://her.esy.fun")
(setq base-dir (concat (projectile-project-root) "src"))
(setq publish-dir (concat (projectile-project-root) "_site"))
(setq assets-dir (concat base-dir "/"))
(setq publish-assets-dir (concat publish-dir "/"))
(setq rss-dir base-dir)
(setq rss-title "Subscribe to articles")
(setq publish-rss-dir publish-dir)
(setq css-path "/css/minimalist.css")
(setq author-name "Yann Esposito")
(setq author-email "yann@esposito.host")

(require 'org)
(require 'ox-publish)
(require 'ox-html)
(require 'org-element)
(require 'ox-rss)

(setq org-link-file-path-type 'relative)
(setq org-publish-timestamp-directory
      (concat (projectile-project-root) "_cache/"))

(defvar org-blog-head
  (concat
   "<link rel=\"stylesheet\" type=\"text/css\" href=\"" css-path "\"/>"
   "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
   "<link rel=\"alternative\" type=\"application/rss+xml\" title=\"" rss-title "\" href=\"/archives.xml\" />"
   "<link rel=\"shortcut icon\" type=\"image/x-icon\" href=\"/favicon.ico\">"))

(defun menu (lst)
  "Blog menu"
  (concat
   "<navigation>"
   (mapconcat 'identity
              (append
               '("<a href=\"/index.html\">Home</a>"
                 "<a href=\"/archive.html\">Posts</a>"
                 "<a href=\"/slides.html\">Slides</a>"
                 "<a href=\"/about-me.html\">About</a>")
               lst)
              " | ")
   "</navigation>"))


(defun str-time-to-year-float (date-str)
  (/ (float-time
      (apply 'encode-time
             (mapcar (lambda (x) (if (null x) 0 x))
                     (parse-time-string date-str))))
     (* 365.25 24 60 60)))

(defvar blog-creation-date "2019-07-01")

(defun y-date (date-str)
  "Number of year since the begining of this blog"
  (let ((y (- (str-time-to-year-float date-str)
              (str-time-to-year-float blog-creation-date))))
    (format "∆t=%.2f" y)))

(defun get-from-info (info k)
  (let ((i (car (plist-get info k))))
    (when (and i (stringp i))
      i)))

(defun org-blog-preamble (info)
  "Pre-amble for whole blog."
  (concat
   "<div class=\"content\">"
   (menu '("<a href=\"#postamble\">↓ bottom ↓</a>"))
   "<h1>"
   (format "%s" (car (plist-get info :title)))
   "</h1>"
   (when-let ((date (plist-get info :date)))
     (format "<span class=\"article-date\">%s</span>"
             (format-time-string "%Y-%m-%d"
                                 (org-timestamp-to-time
                                  (car date)))))
   (when-let ((subtitle (car (plist-get info :subtitle))))
     (format "<h2>%s</h2>" subtitle))
   "</div>"))

(defun rand-obfs (c)
  (let ((r (% (random) 20)))
    (cond ;; ((eq 0 r) (format "%c" c))
          ((<= 0 r 10) (format "&#%d;" c))
          (t (format "&#x%X;" c)))))

(defun obfuscate-html (txt)
  (apply 'concat
         (mapcar 'rand-obfs txt)))

(defun org-blog-postamble (info)
  "Post-amble for whole blog."
  (concat
   "<div class=\"content\">"
   ;; TODO install a comment system
   ;; (let ((url (format "%s%s" domainname (replace-regexp-in-string base-dir "" (plist-get info :input-file)))))
   ;;   (format "<a href=\"https://comments.esy.fun/slug/%s\">comment</a>"
   ;;           (url-hexify-string url)))
   "<footer>"
   (when-let ((author (get-from-info info :author)))
     (if-let ((email (plist-get info :email)))
         (let* ((obfs-email (obfuscate-html email))
                (obfs-author (obfuscate-html author))
                (obfs-title (obfuscate-html (get-from-info info :title)))
                (full-email (format "%s &lt;%s&gt;" obfs-author obfs-email)))
           (format "<div class=\"author\">Author: <a href=\"%s%s%s%s\">%s</a></div>"
                   (obfuscate-html "mailto:")
                   full-email
                   (obfuscate-html "?subject=yblog: ")
                   obfs-title
                   full-email))
       (format "<div class=\"author\">Author: %s</div>" author)))
   (when-let ((date (get-from-info info :date)))
     (format "<div class=\"date\">Created: %s (%s)</div>" date (y-date date)))
   (when-let ((keywords (plist-get info :keywords)))
     (format "<div class=\"keywords\">Keywords: <code>%s</code></div>" keywords))
   (format "<div class=\"date\">Generated: %s</div>"
           (format-time-string "%Y-%m-%d %H:%M:%S"))
   (format (concat "<div class=\"creator\"> Generated with "
                   "<a href=\"https://www.gnu.org/software/emacs/\" target=\"_blank\" rel=\"noopener noreferrer\">Emacs %s</a>, "
                   "<a href=\"http://spacemacs.org\" target=\"_blank\" rel=\"noopener noreferrer\">Spacemacs %s</a>, "
                   "<a href=\"http://orgmode.org\" target=\"_blank\" rel=\"noopener noreferrer\">Org Mode %s</a>"
                   "</div>")
           emacs-version spacemacs-version org-version)
   "</footer>"
   (menu '("<a href=\"#preamble\">↑ Top ↑</a>"))
   "</div>"))

(defun org-blog-sitemap-format-entry (entry _style project)
  "Return string for each ENTRY in PROJECT."
  (when (s-starts-with-p "posts/" entry)
    (format (concat "@@html:<span class=\"archive-item\">"
                    "<span class=\"archive-date\">@@ %s: @@html:</span>@@"
                    " [[file:%s][%s]]"
                    " @@html:</span>@@")
            (format-time-string "%Y-%m-%d" (org-publish-find-date entry project))
            entry
            (org-publish-find-title entry project))))

(defun org-blog-sitemap-function (title list)
  "Return sitemap using TITLE and LIST returned by `org-blog-sitemap-format-entry'."
  (concat "#+TITLE: " title "\n"
          "#+AUTHOR: " author-name "\n"
          "#+EMAIL: " author-email "\n"
          "\n#+begin_archive\n"
          (mapconcat (lambda (li)
                       (format "@@html:<li>@@ %s @@html:</li>@@" (car li)))
                     (seq-filter #'car (cdr list))
                     "\n")
          "\n#+end_archive\n"))

(defun org-blog-publish-to-html (plist filename pub-dir)
  "Same as `org-html-publish-to-html' but modifies html before finishing."
  (let ((file-path (org-html-publish-to-html plist filename pub-dir)))
    (with-current-buffer (find-file-noselect file-path)
      (goto-char (point-min))
      (search-forward "<body>")
      (insert (mapconcat 'identity
                         '(
                           "<input id=\"light\">"
                           "<input id=\"raw\">"
                           "<input id=\"modern\">"
                           "<input id=\"dark\">"
                           "<input id=\"darkraw\">"

                           "<div id=\"labels\">"
                            "<div class=\"content\">"
                            "Change theme: "
                            "<a href=\"#light\">light</a>"
                            "(<a href=\"#raw\">raw</a>,"
                            "<a href=\"#modern\">modern</a>)"
                            " / "
                            "<a href=\"#dark\">dark</a>"
                            "(<a href=\"#darkraw\">raw</a>)"
                            "</div>"
                            "</div>"
                            "<div class=\"main\">")
                         "\n"))
      (goto-char (point-max))
      (search-backward "</body>")
      (insert "\n</div>\n")
      (save-buffer)
      (kill-buffer))
    file-path))

(defun org-blog-publish-attachment (plist filename pub-dir)
  "Publish a file with no transformation of any kind.
FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.
Take care of minimizing the pictures using imagemagick.
Return output file name."
  (unless (file-directory-p pub-dir)
    (make-directory pub-dir t))
  (or (equal (expand-file-name (file-name-directory filename))
	           (file-name-as-directory (expand-file-name pub-dir)))
      (let ((dst-file (expand-file-name (file-name-nondirectory filename) pub-dir)))
        (if (string-match-p ".*\\.\\(png\\|jpg\\|gif\\)$" filename)
            (shell-command (format "~/.nix-profile/bin/convert %s -resize 800x800\\> +dither -colors 16 -depth 4 %s"
                                   filename
                                   dst-file))
          (copy-file filename dst-file t)))))

(setq org-publish-project-alist
      `(("orgfiles"
         :base-directory ,base-dir
         :exclude ".*drafts/.*"
         :base-extension "org"
         :publishing-directory ,publish-dir

         :recursive t
         :publishing-function org-blog-publish-to-html

         :with-toc nil
         :with-title nil
         :with-date t
         :section-numbers nil
         :html-doctype "html5"
         :html-html5-fancy t
         :html-head-include-default-style nil
         :html-head-include-scripts nil
         :htmlized-source t
         :html-head-extra ,org-blog-head
         :html-preamble org-blog-preamble
         :html-postamble org-blog-postamble

         :auto-sitemap t
         :sitemap-filename "archive.org"
         :sitemap-title "Blog Posts"
         :sitemap-style list
         :sitemap-sort-files anti-chronologically
         :sitemap-format-entry org-blog-sitemap-format-entry
         :sitemap-function org-blog-sitemap-function)

        ("assets"
         :base-directory ,assets-dir
         :base-extension ".*"
         :exclude ".*\.org$"
         :publishing-directory ,publish-assets-dir
         :publishing-function org-blog-publish-attachment
         :recursive t)

        ("rss"
         :base-directory ,rss-dir
         :base-extension "org"
         :html-link-home ,domainname
         :html-link-use-abs-url t
         :rss-extension "xml"
         :publishing-directory ,publish-rss-dir
         :publishing-function (org-rss-publish-to-rss)
         :exclude ".*"
         :include ("archive.org")
         :section-numbers nil
         :table-of-contents nil)

        ("blog" :components ("orgfiles" "assets" "rss"))))

;; add target=_blank and rel="noopener noreferrer" to all links by default
(defun my-org-export-add-target-blank-to-http-links (text backend info)
  "Add target=\"_blank\" to external links."
  (when (and
         (org-export-derived-backend-p backend 'html)
         (string-match "href=\"http[^\"]+" text)
         (not (string-match "target=\"" text))
         (not (string-match (concat "href=\"" domainname "[^\"]*") text)))
    (string-match "<a " text)
    (replace-match "<a target=\"_blank\" rel=\"noopener noreferrer\" " nil nil text)))

(add-to-list 'org-export-filter-link-functions
             'my-org-export-add-target-blank-to-http-links)

(provide 'her-esy-fun-publish)
