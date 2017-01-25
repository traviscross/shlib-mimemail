# shlib-mimemail

This is a library that can be used to build and send emails from `sh`
scripts or from the shell.

## Usage

This library provides primitives to build a multipart MIME-encoded
email.  You're responsible for providing a function to build the email
itself.  You then provide the function and the envelope sender address
to `send_mail` and it takes care of sending it out.  e.g.:

    #!/bin/sh
    . "$(dirname "$0")"/shlib-mimemail.sh
    sender_name="Word Sender"
    sender_addr="sender@example.com"
    to_emails="Person 1 <r1@example.com>, Person 2 <r2@example.com>"
    cc_emails=""
    msg_subject="See the attached words"

    template_body () {
      cat <<EOF
    Please find attached some words.
    EOF
    }

    compose_mail () {
      local b="$(mime_boundary)"
      template_header \
        "$sender_name" "$sender_addr" \
        "$to_emails" "$cc_emails" \
        "$msg_subject"
      mime_add_multipart_mixed "$b"
      mime_next "$b"
      template_body | mime_add_text_plain
      mime_next "$b"
      head -n100 /usr/share/dict/words \
        | mime_add_file_gzip "$b" \
        "some_words.txt.gz"
      mime_end "$b"
    }

    compose_mail | send_mail "$sender_addr"

To use the library, you must first create a MIME boundary with
`mime_boundary`.

You then create the email header.  You can define a custom function
for this or use the provided `template_header`.

Next, make the message multipart/mixed (body and attachments) by
calling `mime_add_multipart_mixed` with the boundary.

Before each section you add, call `mime_next` with the boundary.

You can now add both inline and attachment sections by streaming the
body of the section via `stdin` into the section creation function.
The available functions are:

    mime_add_text <boundary> <content-type>
    mime_add_text_plain <boundary>
    mime_add_text_html <boundary>

These add inline text sections.

    mime_add_file <boundary> <content_type> <encoding> <file_name>

This adds an attachment of a given content type, encoding, and file
name (the file name that will be suggested to the user for saving the
file).

    mime_add_file_binary <boundary> <content_type> <file_name>

This adds a binary attachment.

    mime_add_file_gzip <boundary> <file_name>

This uses gzip to compress the streamed data prior to attaching it.

When you're ready to send the email, call:

    <compose-fn> | send_mail <sender-envelope-address>

## Dependencies

This library runs under a POSIX-style `sh` on `linux`.  It has only
been tested under `dash`.  This library also requires `sendmail`,
`base64`, and `gzip`.

## Examples

For a complete example of how to use this library, see:

[Example Usage](example.sh)

## License

This project is licensed under the
[MIT/Expat](https://opensource.org/licenses/MIT) license as found in
the [LICENSE](./LICENSE) file.
