# Setting up ssl auto-renewal for Namecheap shared hosting with acme.sh

Reference: [Anuj Singh Tomar](https://dev.to/atomar/let-s-encrypt-ssl-certificate-in-namecheap-autorenewal-verified-working-using-acme-sh-4m7i)

- - - - -

**Install acme.sh**
```bash
curl https://get.acme.sh | sh
source ~/.bashrc
```

**Register account and issue certificate**
```bash
acme.sh --register-account --accountemail email@example.com

acme.sh --issue --webroot ~/public_html -d yourdomain.com --staging
acme.sh --issue --webroot ~/public_html -d yourdomain.com --force

acme.sh --deploy --deploy-hook cpanel_uapi --domain yourdomain.com
```

- - - - -

**Optional force-https redirect with .htaccess**
```bash
vim ~/public_html/.htaccess 

<IfModule mod_rewrite.c>
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</IfModule>
```
