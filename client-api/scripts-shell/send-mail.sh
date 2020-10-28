#!/bin/bash
DATE_LOG=$(date +%Y-%m-%d)
LOGFILE="terrama_ftp_push_$DATE_LOG.log"

TO=$(cat "$STATIC_FILES_DIR"/mail_to.cfg )
BODY="$STATIC_FILES_DIR/$LOGFILE"
(cat - $BODY)<<HEADERS_END | /usr/sbin/sendmail -F "TerraBrasilis" -i $TO
Subject: [TerraBrasilis] - Log do envio de dados DETER-MT para o FTP
To: $TO

HEADERS_END