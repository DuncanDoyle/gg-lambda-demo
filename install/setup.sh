#!/bin/sh

####################################################################################
#
# Initiates the Gloo Gateway Lambda Demo
#
# Requires an existing Gloo Gateway 1.17+ setup with ExtAuth
#
# Requires the glooctl CLI to be installed.
#
####################################################################################

pushd ../


# Label the default namespace, so the gateway will accept the HTTPRoute from that namespace.
printf "\nLabel default namespace ...\n"
kubectl label namespaces default --overwrite shared-gateway-access="true"


# Create reference grants
kubectl apply -f referencegrant/gloo-system-ns/httproute-portal-reference-grant.yaml
kubectl apply -f referencegrant/gloo-system-ns/httproute-upstream-reference-grant.yaml
kubectl apply -f referencegrant/gloo-system-ns/portal-reference-grant.yaml

# Deploy the policies
kubectl apply -f policies/api-cors-route-option.yaml
kubectl apply -f policies/portal-route-option.yaml


# Deploy the Lambda Upstream, APIDoc, APIProduct and HTTPRoute
kubectl apply -f upstreams/lambda-upstream.yaml
kubectl apply -f apis/lambda/lambda-apischemadiscovery.yaml
kubectl apply -f apiproduct/lambda/lambda-apiproduct.yaml
kubectl apply -f routes/lambda-example-com-httproute.yaml


# Deploy the Portal configuration and Portal Frontend and PortalServer HTTPRoute.
kubectl apply -f portal/portal.yaml
kubectl apply -f portal/portal-frontend.yaml
kubectl apply -f routes/portal-server-httproute.yaml
kubectl apply -f routes/portal-frontend-httproute.yaml


printf "\nWaiting a couple of seconds for the Lambda to be resolved so the validation webhook does not reject the VirtualService that we're about to deploy."
sleep 5

# Apply the VirtualService for the classic Gloo Edge API use-case.
kubectl apply -f virtualservices/lambda-example-com-vs.yaml

popd