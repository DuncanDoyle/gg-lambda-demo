# Lambda with Service Account


### Create an EKS cluster

```
eksctl create cluster --name GlooGatewayLambda --region=eu-central-1
```

### Add IAM OIDC Provider to your cluster's OIDC Provider:

```
cluster_name=GlooGatewayLambda
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $oidc_id
```

Determine whether an IAM OIDC provider with your cluster's issuer ID is already in your account:
```
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
```

If output is returned, then you already have an IAM OIDC provider for your cluster and you can skip the next step. If no output is returned, then you must create an IAM OIDC provider for your cluster.

Create an IAM OIDC identity provider for your cluster with the following command:
```
eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
```

##

```
export AWS_LAMBDA_REGION=eu-central-1
export ACCOUNT_ID=931713665590
```

Get the full ID of the OIDC provider:

```
export OIDC_PROVIDER=$(aws eks describe-cluster --name $cluster_name --region $AWS_LAMBDA_REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
```

Create an IAM Policy to allow access to the Lambda actions:

```
cat >policy.json <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": [
               "lambda:ListFunctions",
               "lambda:InvokeFunction",
               "lambda:GetFunction",
               "lambda:InvokeAsync"
           ],
           "Resource": "*"
       }
   ]
}
EOF

aws iam create-policy --policy-name gloo-lambda-policy --policy-document file://policy.json
```


Use an IAM role to associate the policy with the Kubernetes service account for the HTTP gateway proxy, which assumes this role to invoke Lambda functions.
```
cat >role.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": [
            "system:serviceaccount:ingress-gw:gloo-proxy-gw"
          ]
        }
      }
    }
  ]
}
EOF

aws iam create-role --role-name gloo-lambda-role --assume-role-policy-document file://role.json
```

Attach the IAM role to the policy
```
aws iam attach-role-policy --role-name gloo-lambda-role --policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/gloo-lambda-policy
```

QUESTION: THIS ONLY SEEMS TO ATTACH THE ROLE TO THE POLICY, NOT THE POLICY TO THE ROLE. NOT SURE IF THAT IS NEEDED .....

Verify that the policy is attached to the role:

```
aws iam list-attached-role-policies --role-name gloo-lambda-role
```


## Configure Helm:

```
helm get values gloo-gateway -n gloo-system -o yaml > gloo-gateway.yaml
```

```
helm upgrade -n gloo-system gloo-gateway gloo/gloo \
 -f gloo-gateway.yaml \
 --set kubeGateway.gatewayParameters.glooGateway.serviceAccount.extraAnnotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::${ACCOUNT_ID}:role/gloo-lambda-role \
 --set settings.aws.enableServiceAccountCredentials=true \
 --set settings.aws.stsCredentialsRegion=sts.amazonaws.com \
 --version=1.18.0-rc3
```

Cycle the gateway:

```
kubectl -n ingress-gw rollout restart deploy gloo-proxy-gw
```