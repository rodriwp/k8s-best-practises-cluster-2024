firsttimeinstalation:
	echo "127.0.0.1  bare-metal.rodrigomompo.com" | sudo tee -a /etc/hosts
	echo "172.19.0.2  plex.k8s.rodrigomompo.com" | sudo tee -a /etc/hosts
	wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.6.0 bash
	brew install k3d
	brew install kustomize
	brew install argocd

kubeclustercreate:
	k3d cluster create --config k3d-config.yaml
	echo "Install ArgoCD"
	cd ..; \
	kustomize build argocd/bootstrap | kubectl apply  -n argocd -f -; \
	kustomize build argocd/bootstrap | kubectl apply  -n argocd -f -

kubeclusterdelete:
	k3d cluster delete bare-metal
	echo "Everything is deleted. Now, it will sleep 10 seconds to avoid issues when you try to start a new cluster to fast"
	sleep 10
kubeclusterstart:
	k3d cluster start bare-metal
kubeclusterstop:
	k3d cluster stop bare-metal