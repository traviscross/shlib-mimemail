#!/bin/sh
##### -*- mode:shell-script; indent-tabs-mode:nil; sh-basic-offset:2 -*-
export PATH=/usr/bin:/bin

. "$(dirname "$0")"/shlib-mimemail.sh

usage () {
  echo "usage: $0 [-h]">&2
  echo "  -j <msg-subject>">&2
  echo "  -s <sender-email>">&2
  echo "  -t <to-emails>">&2
  echo "  -c <cc-emails>">&2
  echo "  [-m]">&2
  echo "  [-p]">&2
}

usage_err () {
  usage; err "$1"
}

sender_email=""
cc_emails=""
to_emails=""
msg_subject=""
compress=false
printonly=false
while getopts "c:hj:mps:t:" o; do
  case "$o" in
    c) cc_emails="$OPTARG" ;;
    h) usage; exit 0 ;;
    j) msg_subject="$OPTARG" ;;
    m) compress=true ;;
    p) printonly=true ;;
    s) sender_email="$OPTARG" ;;
    t) to_emails="$OPTARG" ;;
  esac
done
shift $(($OPTIND-1))

test -n "$to_emails" \
  || usage_err "No destinations specified"

test -n "$sender_email" \
  || usage_err "No sender specified"

test -n "$msg_subject" \
  || usage_err "No subject specified"

sender_addr="$(email_addr "$sender_email")"
sender_name="$(email_name "$sender_email")"
msg_subject="$msg_subject | $(/bin/date -u +%Y-%m-%d)"

template_body () {
  cat <<EOF
Please find attached some words.
EOF
}

compose_mail () {
  local boundary="$(mime_boundary)"
  template_header \
    "$sender_name" "$sender_addr" \
    "$to_emails" "$cc_emails" \
    "$msg_subject"
  mime_add_multipart_mixed "$boundary"
  mime_next "$boundary"
  template_body | mime_add_text_plain
  mime_next "$boundary"
  if $compress; then
    head -n100 /usr/share/dict/words \
      | mime_add_file_gzip "$boundary" \
      "some_words.txt.gz"
  else
    head -n100 /usr/share/dict/words \
      | mime_add_file "$boundary" \
      "text/plain" "8bit" "some_words.txt"
  fi
  mime_end "$boundary"
}

if $printonly; then
  compose_mail
else
  compose_mail | send_mail "$sender_addr"
fi
