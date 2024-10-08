#!/bin/sh

TLS_CERT_TMP_DIR=`mktemp -d`

pushd $TLS_CERT_TMP_DIR

printf "\nGenerating self-signed TLS cert for api.example.com.\n"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=api.example.com"

printf "\nCreating TLS cert secret.\n"
kubectl create secret tls api-example-com --key tls.key --cert tls.crt --namespace gloo-system

printf "\n\nTLS Cert Secret 'api-example-com' for 'api.example.com' domain created in 'gloo-system' namespace. You can now create a VirtualService with TLS configuration for the 'api.example.com' domain.\n\n"

popd