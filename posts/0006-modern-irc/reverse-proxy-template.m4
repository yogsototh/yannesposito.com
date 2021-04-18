# Nginx configuration

server {
  server_name SUB.DOMAIN;
  access_log  /var/log/nginx/SUB()_ssl_access.log;
  error_log   /var/log/nginx/SUB()_ssl_error.log;

  # # access restricted
  # auth_basic "Admin restricted";
  # auth_basic_user_file /etc/nginx/htpasswd;

  listen *:443 ssl;
  listen [::]:443 ssl;
  server_tokens off;

  ## SSL
  ssl on;
  ssl_certificate /etc/letsencrypt/live/DOMAIN/fullchain.pem; # managed by Certbot
  ssl_certificate_key /etc/letsencrypt/live/DOMAIN/privkey.pem; # managed by Certbot
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 5m;

  ## [Optional] Enable HTTP Strict Transport Security
  ## HSTS is a feature improving protection against MITM attacks
  ## For more information see: https://www.nginx.com/blog/http-strict-transport-security-hsts-and-nginx/
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

  location / {
	  proxy_pass http://127.0.0.1:PORT;
	  gzip off;
	  proxy_redirect off;

          ## Some requests take more than 30 seconds.
	  proxy_read_timeout      30s;
	  proxy_connect_timeout   30s;

	  proxy_http_version 1.1;

	  proxy_set_header      Host                $http_host;
	  proxy_set_header      X-Real-IP           $remote_addr;
	  proxy_set_header      X-Forwarded-Ssl     on;
	  proxy_set_header      X-Forwarded-For     $proxy_add_x_forwarded_for;
	  proxy_set_header      X-Forwarded-Proto   $scheme;
          proxy_set_header      X-Client-Verify     SUCCESS;
          proxy_set_header      X-Client-DN         $ssl_client_s_dn;
          proxy_set_header      X-SSL-Subject       $ssl_client_s_dn;
          proxy_set_header      X-SSL-Issuer        $ssl_client_i_dn;
  }
}

## Redirects all HTTP traffic to the HTTPS host
server {
  ## In case of conflict, either remove "default_server" from the listen line below,
  ## or delete the /etc/nginx/sites-enabled/default file.
  listen 0.0.0.0:80;
  listen [::]:80;
  server_name SUB.DOMAIN;
  server_tokens off; ## Don't show the nginx version number, a security best practice
  return 301 https://$http_host$request_uri;
  access_log  /var/log/nginx/SUB.DOMAIN()_access.log;
  error_log   /var/log/nginx/SUB.DOMAIN()_error.log;
}
