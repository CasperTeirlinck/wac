# Python on MacOS does not properly use custom system ca certificates in keychain.
# If you need to use custom certificates, you can manually add them to /etc/ssl/certs/
# and set the appropriate environment variables.

CERT_PATH=/etc/ssl/certs/cacert.pem
export SSL_CERT_FILE=${CERT_PATH}
export REQUESTS_CA_BUNDLE=${CERT_PATH}