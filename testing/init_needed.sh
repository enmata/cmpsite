
# Enabling port forwarding for minikube VM
VBoxManage controlvm minikube natpf1 k8s-apiserver,tcp,127.0.0.1,8443,,8443
VBoxManage controlvm minikube natpf1 k8s-dashboard,tcp,127.0.0.1,30000,,30000

# starring minikube
minikube start --vm-driver=virtualbox

#Setting kubectl env
kubectl config set-cluster minikube-vpn --server=https://127.0.0.1:8443 --insecure-skip-tls-verify
kubectl config set-context minikube-vpn --cluster=minikube-vpn --user=minikube
kubectl config use-context minikube-vpn

## enabling ingress
minikube addons enable ingress

#Checking service
minikube service cmpsite-service

## enable local docker client
VBoxManage controlvm minikube natpf1 k8s-docker,tcp,127.0.0.1,2374,,2376
eval $(minikube docker-env)
unset DOCKER_TLS_VERIFY
export DOCKER_HOST="tcp://127.0.0.1:2374"
alias docker='docker --tls'
