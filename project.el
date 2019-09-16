;; sign it with
;; gpg --local-user yann@esposito.host --output project.el.sig --detach-sign project.el
(defvar domainname "https://her.esy.fun")
(defvar base-dir (concat (projectile-project-root) "src"))
(defvar publish-dir (concat (projectile-project-root) "_site"))
(defvar assets-dir (concat base-dir "/"))
(defvar publish-assets-dir (concat publish-dir "/"))
(defvar posts-dir (concat base-dir "/posts"))
(defvar rss-title "Subscribe to articles")
(defvar rss-home domainname)
(defvar rss-url (concat domainname "/rss.xml"))
(defvar rss-img (concat domainname "/img/FlatAvatar.png"))
(defvar rss-description "her.esy.fun articles, mostly random personal thoughts")
(defvar posts-descr "Articles")
(defvar css-path "/css/minimalist.css")
(defvar author-name "Yann Esposito")
(defvar author-email "yann@esposito.host")

(require 'org)
(require 'ox-publish)
(require 'ox-html)
(require 'org-element)
(require 'ox-rss)

;; (setq org-link-file-path-type 'relative)
(setq org-publish-timestamp-directory
      (concat (projectile-project-root) "_cache/"))

(defvar org-blog-head
  (concat
   "<link rel=\"stylesheet\" type=\"text/css\" href=\"" css-path "\"/>"
   "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
   "<link rel=\"alternative\" type=\"application/rss+xml\" title=\"" rss-title "\" href=\"/rss.xml\" />"
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
   "<div class=\"rss\"><a href=\"/rss.xml\">RSS</a>: <a href=\"https://validator.w3.org/feed/check.cgi?url=https%3A%2F%2Fher.esy.fun%2Frss.xml\">Valid RSS</a></div>"
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

(defun y/org-get-keywords ()
  (org-element-map (org-element-parse-buffer 'element) 'keyword
    (lambda (keyword) (cons (org-element-property :key keyword)
                            (org-element-property :value keyword)))))

(defun y/org-get-meta (keyword)
  (cdr (assoc keyword (y/org-get-keywords))))

(defun y/get-meta (file meta-name)
  "Return the value of the meta of an org-mode file.

(y/get-meta file \"DESCRIPTION\")
"
  (org-babel-with-temp-filebuffer file (y/org-get-meta meta-name)))

(defun date-format-entry (entry _style project)
  "Return string for each ENTRY in PROJECT."
  (when (string-match "posts/.*" entry)
    (let* ((file (org-publish--expand-file-name entry project))
           (title (org-publish-find-title entry project))
           (date (format-time-string "%Y-%m-%d" (org-publish-find-date entry project)))
           (keywords (split-string (y/get-meta file "KEYWORDS") ",\s*"))
           (description (y/get-meta file "DESCRIPTION")))
      (concat
       "- "
       (format " [%s]" date)
       (format " *[[file:%s][%s]]*" file title)
       (format " @@html:<div class=\"keywords\">@@%s@@html:</div>@@"
               (mapconcat (lambda (k) (format "@@html:<span class=\"keyword\">@@#%s@@html:</span>@@" k))
                          (cl-sort keywords 'string-lessp :key 'downcase)
                          " "))
       (format "@@html:<div class=\"description\">@@%s@@html:</div>@@" description)))))

(defun org-blog-sitemap-fn-descr (descr title list)
  "Return sitemap using TITLE and LIST returned by `org-blog-sitemap-format-entry'."
  (concat "#+TITLE: " title "\n"
          "#+AUTHOR: " author-name "\n"
          "#+EMAIL: " author-email "\n"
          "#+DESCRIPTION: " descr "\n"
          (mapconcat (lambda (li) (format "%s" (car li)))
                     (seq-filter #'car (cdr list))
                     "\n")))

(defun org-blog-prepare (project-plist)
  "With help from `https://github.com/howardabrams/dot-files'.
  Touch `archive.org' to rebuilt it.
  Argument `PROJECT-PLIST' contains information about the current project."
  (let* ((base-directory (plist-get project-plist :base-directory))
         (buffer (find-file-noselect (expand-file-name "archive.org" base-directory) t)))
    (with-current-buffer buffer
      (set-buffer-modified-p t)
      (save-buffer 0))
    (kill-buffer buffer)))

(defun org-blog-publish-to-html (plist filename pub-dir)
  "Same as `org-html-publish-to-html' but modifies html before finishing."
  (let ((file-path (org-html-publish-to-html plist filename pub-dir)))
    (with-current-buffer (find-file-noselect file-path)
      (goto-char (point-min))
      (search-forward "<body>")
      (insert (mapconcat 'identity
                         '("<input id=\"light\">"
                           "<input id=\"raw\">"
                           "<input id=\"modern\">"
                           "<input id=\"dark\">"
                           "<input id=\"darkraw\">"
                           "<input id=\"matrix\">"

                           "<div id=\"labels\">"
                           "<div class=\"content\">"
                           "Change theme: "
                           "<a href=\"#light\">light</a>"
                           "(<a href=\"#raw\">raw</a>,"
                           "<a href=\"#modern\">modern</a>)"
                           " / "
                           "<a href=\"#dark\">dark</a>"
                           "(<a href=\"#darkraw\">raw</a>,"
                           "<a href=\"#matrix\">matrix</a>)"
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

(defalias 'org-blog-posts-sitemap-fn
  (apply-partially 'org-blog-sitemap-fn-descr posts-descr))

(defun y/org-rss-publish-to-rss (plist filename pub-dir)
  (if (equal "rss.org" (file-name-nondirectory filename))
      (org-rss-publish-to-rss plist filename pub-dir)))

(defun y/format-rss-feed (title list)
  (concat "#+TITLE: " title "\n"
          "#+AUTHOR: " author-name "\n"
          "#+EMAIL: " author-email "\n"
          "#+DESCRIPTION: " rss-description "\n"
          "\n"
          (org-list-to-subtree list '(:icount "" :istart ""))))

(defun y/format-rss-feed-entry (entry style project)
  (cond ((not (directory-name-p entry))
         (let* ((file (org-publish--expand-file-name entry project))
                (title (org-publish-find-title entry project))
                (subtitle (y/get-meta (format "%s/%s" posts-dir entry) "SUBTITLE"))
                (keywords (y/get-meta (format "%s/%s" posts-dir entry) "KEYWORDS"))
                (description (y/get-meta (format "%s/%s" posts-dir entry) "DESCRIPTION"))
                (date (format-time-string "%Y-%m-%d" (org-publish-find-date entry project)))
                (link (concat "posts/" (file-name-sans-extension entry) ".html")))
           (with-temp-buffer
             (insert (format "* [[file:%s][%s]]\n" file title))
             (org-set-property "RSS_PERMALINK" link)
             (org-set-property "PUBDATE" date)
             (org-set-property "ID" (org-auto-id-format title))
             (when subtitle
               (org-set-property "SUBTITLE" subtitle))
             (when keywords
               (insert "Keywords: ")
               (insert keywords)
               (insert "\n\n"))
             (when description
               (insert description))
             (buffer-string))))
        ((eq style 'tree)
         (file-name-nondirectory (directory-file-name entry)))))

(setq org-publish-project-alist
      `(("orgfiles"
         :base-directory ,base-dir
         :exclude ".*drafts/.*\\|.*/rss.*"
         :base-extension "org"
         :publishing-directory ,publish-dir
         :recursive t
         :preparation-function org-blog-prepare
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
         :sitemap-title "Articles"
         :sitemap-style list
         :sitemap-sort-files anti-chronologically
         :sitemap-format-entry date-format-entry
         :sitemap-function org-blog-posts-sitemap-fn)

        ("rss"
         :base-directory ,posts-dir
         :base-extension "org"
         :recursive t
         :publishing-directory ,publish-dir
         :publishing-function y/org-rss-publish-to-rss
         :rss-extension "xml"
         :rss-image-url ,rss-img
         :rss-feed-url ,rss-url
         :html-link-home ,rss-home
         :auto-sitemap t
         :sitemap-filename "rss.org"
         :sitemap-title "her.esy.fun"
         :sitemap-style list
         :sitemap-function y/format-rss-feed
         :sitemap-format-entry y/format-rss-feed-entry)

        ("assets"
         :base-directory ,assets-dir
         :base-extension ".*"
         :exclude ".*\.org$"
         :publishing-directory ,publish-assets-dir
         :publishing-function org-blog-publish-attachment
         :recursive t)

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
