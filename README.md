# Gloo Gateway 1.17 - Lambda Demo

> [!NOTE
> This demo only shows the use of Lambda on Gloo Gateway with the Edge API, the K8S Gateway API and the Gloo Gateway Portal. This demo has no AuthN/AuthZ configured, as that would add additional complexity (e.g. setup of an IdP/Oauth Provider like Keycloak), without adding value to the core concept we want to demonstrate.

## Prerequisit

This demo requires a number of AWS Lambda's to be deployed in your AWS environment.
The Gloo Gateway Lambda Upstream (upstreams/lambda-upstream.yaml), if configured correctly, will automatically discover the Lambda's that the AWS account (which you will configure as part of the installation) has access to.

Which Lambda is called Gloo Gateway depends, in this demo, on the configured Lambda function on the HTTPRoute (routes/lambda-example-com-httproute.yaml) (K8S Gateway API) and VirtualService (virtualservices/lambda-example-com-vs.yaml) (Gloo Edge API).

## Installation

Install Gloo Gateway:
```
cd install
./install-gloo-gateway-with-helm.sh
```

> [!NOTE]
> The Gloo Gateway version that will be installed is set in a variable at the top of the `install/install-gloo-gateway-with-helm.sh` installation script.

The installation will also create the 2 different `gateway-proxies` and their configuration:
- `gateway-proxy` in the `gloo-system` namespace, bound to ports 81 and 444. This is the Gloo Edge API proxy
- `gloo-proxy-gw` in the `ingress-gw` namespace, bound to port 80. This is the K8S Gateway API proxy.


## Create your AWS Credentials secret

For the Upstream to be able to connect to the Lambda's in AWS, it will need to have access to the required credentials.
We will store these credentials in a secret. To generate this secret, fist add your AWS access-key and AWS secret-access-key to the following environment variables:

```
export AWS_ACCESS_KEY={your aws access key}
export AWS_SECRET_ACCESS_KEY={your aws secret access key}
```

Next run the following script to create the Kubernetes secret `aws-cred` in the `gloo-system` namespace:

```
./create-aws-cred-secret.sh
```

## Setup the environment

Run the `install/setup.sh` script to setup the environment:

```
./setup.sh
```

This will:
- Create required K8S Gateway API ReferenceGrants.
- Deploy the Lambda Upstream, Lambda ApiSchemaDiscovery, Lambda ApiProduct and Lambda HTTPRoute.
- Deploy the Portal configuration, Portal Frontend and their HTTPRoutes.
- Deploy the VirtualService (classic Gloo Edge API)

## Running the demo.

The Portal Frontend can be accessed at `http://devportal.example.com`. Make sure that this hostname maps to the public IP of the `gloo-proxy-gw` in the `ingress-gw` namespace. When running a local minikube cluster, this can be referencing a tunnel running on localhost. When running in a cloud provider, this will be the public ip-address of your loadbalancer.

If the demo is deployed correctly, the Developer Portal UI should now list our Lambda APIProduct. You can try out the Lambda via the the Swagger view by using Swagger's "Try it out" functionality.


