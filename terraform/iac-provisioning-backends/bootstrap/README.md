This Terraform main.tf bootstraps the s3 backend for the iac-provisioning-backend utility that generates all the other Terraform S3 Backends.
You need to apply it manually by running:

```shell 
terraform init
```

```shell 
terraform apply
```