#!/bin/bash
# get global env vars from Docker Secrets
EMAIL_USER=$(cat "$SMTP_GOOGLE_MAIL_USER_FILE")
EMAIL_PASS=$(cat "$SMTP_GOOGLE_MAIL_PASS_FILE")

# Make configurations for send email using ssmtp based in Docker Secrets
## write file /etc/ssmtp/ssmtp.conf
rm -f /etc/ssmtp/ssmtp.conf
echo "#" >> /etc/ssmtp/ssmtp.conf
echo "# Config file for sSMTP sendmail" >> /etc/ssmtp/ssmtp.conf
echo "#" >> /etc/ssmtp/ssmtp.conf
echo "# The person who gets all mail for userids < 1000" >> /etc/ssmtp/ssmtp.conf
echo "# Make this empty to disable rewriting." >> /etc/ssmtp/ssmtp.conf
echo "root=$EMAIL_USER" >> /etc/ssmtp/ssmtp.conf
echo "" >> /etc/ssmtp/ssmtp.conf
echo "# The place where the mail goes. The actual machine name is required no" >> /etc/ssmtp/ssmtp.conf
echo "# MX records are consulted. Commonly mailhosts are named mail.domain.com" >> /etc/ssmtp/ssmtp.conf
echo "mailhub=smtp.gmail.com:587" >> /etc/ssmtp/ssmtp.conf
echo "" >> /etc/ssmtp/ssmtp.conf
echo "# Where will the mail seem to come from?" >> /etc/ssmtp/ssmtp.conf
echo "rewriteDomain=gmail.com" >> /etc/ssmtp/ssmtp.conf
echo "" >> /etc/ssmtp/ssmtp.conf
echo "# The full hostname" >> /etc/ssmtp/ssmtp.conf
echo "#hostname=terrabrasilis.dpi.inpe.br" >> /etc/ssmtp/ssmtp.conf
echo "hostname=localhost" >> /etc/ssmtp/ssmtp.conf
echo "" >> /etc/ssmtp/ssmtp.conf
echo "AuthUser=$EMAIL_USER" >> /etc/ssmtp/ssmtp.conf
echo "AuthPass=$EMAIL_PASS" >> /etc/ssmtp/ssmtp.conf
echo "UseTLS=YES" >> /etc/ssmtp/ssmtp.conf
echo "UseSTARTTLS=YES" >> /etc/ssmtp/ssmtp.conf
echo "" >> /etc/ssmtp/ssmtp.conf
echo "# Are users allowed to set their own From: address?" >> /etc/ssmtp/ssmtp.conf
echo "# YES - Allow the user to specify their own From: address" >> /etc/ssmtp/ssmtp.conf
echo "# NO - Use the system generated From: address" >> /etc/ssmtp/ssmtp.conf
echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf
echo "" >> /etc/ssmtp/ssmtp.conf
echo "TLS_CA_File=/etc/ssl/certs/ca-certificates.crt" >> /etc/ssmtp/ssmtp.conf
echo "" >> /etc/ssmtp/ssmtp.conf

## write file /etc/ssmtp/revaliases
rm -f /etc/ssmtp/revaliases
echo "#" >> /etc/ssmtp/revaliases
echo "# sSMTP aliases" >> /etc/ssmtp/revaliases
echo "# " >> /etc/ssmtp/revaliases
echo "# Format:	local_account:outgoing_address:mailhub" >> /etc/ssmtp/revaliases
echo "#" >> /etc/ssmtp/revaliases
echo "# Example: root:your_login@your.domain:mailhub.your.domain[:port]" >> /etc/ssmtp/revaliases
echo "# where [:port] is an optional port number that defaults to 25." >> /etc/ssmtp/revaliases
echo "root:$EMAIL_USER:smtp.gmail.com:587" >> /etc/ssmtp/revaliases

# create a configuration file for php scripts
php /usr/local/php-client/install/install.php

# run cron in foreground
cron -f