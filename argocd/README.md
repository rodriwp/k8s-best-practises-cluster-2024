# ArgoCD Instalation v2.9.3
This folder contains argocd and all the resources deploy by argoCD on a kubernetes cluster

## Log into ArgoCD (after bootstrap is completed)
1. Get admin password
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
2. Open the port as ingress is not configure yet
```
kubectl port-forward -n argocd svc/argocd-server 8024:80
```
3. Login to argocd, add repo cred and add clustes: - open a new terminal. Username = admin, password is the value returned from step 6

```
argocd login localhost:8024 --grpc-web
```

## ArgoCD Bootstrap Installation Bare Metal
The Makefile will execute any require commands as part of the cluster creation

We need to add the repository credentials after installation is complete. Log in  argoCD CLI first
```
argocd repocreds add https://github.com/rodriwp --github-app-id xxxxxx --github-app-installation-id xxxxxxxx --github-app-private-key-path secrets/<>
```

## ArgoCD Bootstrap Installation Managed Cloud

1. Fetch kubeconfigs - run the corresponding commands to fetch kubeconfigs. This assumes you have the correct users and roles configure in your machine.
```
aws eks update-kubeconfig --region eu-central-1 --name managed-cloud-ec1-eks  --profile <user_profile_with_assume_role_for_managed-cloud-eks> --kubeconfig ~/.kube/managed-cloud-ec1-eks
```   
NOTE: If the aws-auth configmap hasn't been applied yet, the only user that will work is the automation user which created the cluster. In the future argoCD will apply this map, so for bootstrap automation user will be needed.
2. Export KUBECONFIG
```
export KUBECONFIG=~/.kube/managed-cloud-ec1-eks
```
3. Switch context to this config
```
kubectl config use-context $(kubectl config get-contexts -o=name | grep managed-cloud-ec1-eks)
```
4. Install argocd - Open this repo in a terminal
```
kustomize build argocd/bootstrap | kubectl apply  -n argocd -f -
```
If there is a message like this, re-run the above command again:
```
unable to recognize "STDIN": no matches for kind "AppProject" in version "argoproj.io/v1alpha1"
```

5. Install repository credentials
```
argocd repocreds add https://github.com/rodriwp --github-app-id 224548 --github-app-installation-id 29068966 --github-app-private-key-path secrets/<>
```


