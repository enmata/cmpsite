all: build deploy deploy-tls test test-reliability test-ssl clean
	# runs sequentially all the workflow: "make build", "make deploy", "make test" and "make clean"

build:
	# creation and push the necessary docker images on local docker deaemon for minikube environment
	sh docker/docker_build_wrapper.sh

build-aws:
	# creation and push the necessary docker images to a new ECR registry on AWS
	sh docker/docker_build_wrapper_AWS.sh

deploy:
	# sequencial creation of all the needed resources on an isolated kubernetes namespace cmpsite-namespace for minikube environment. Also enabling ingress-nginx module.
	kubectl create -f kubernetes/cmpsite_00_namespace.yaml
	kubectl create -f kubernetes/cmpsite_01_pvc.yaml
	kubectl create -f kubernetes/cmpsite_02_configmap-cmpsite.yaml
	kubectl create -f kubernetes/cmpsite_03_configmap-logging.yaml
	kubectl create -f kubernetes/cmpsite_04_secret-cmpsite.yaml
	kubectl create -f kubernetes/cmpsite_05_secret-cmpdb.yaml
	kubectl create -f kubernetes/cmpsite_06_deployment.yaml
	kubectl create -f kubernetes/cmpsite_07_service.yaml
	-minikube addons enable ingress

deploy-AWS:
	# sequencial creation of all the needed resources on an isolated kubernetes namespace cmpsite-namespace using AWS deployment. Also installing [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/) from the official manifest.
	kubectl create -f kubernetes/cmpsite_00_namespace.yaml
	kubectl create -f kubernetes/cmpsite_01_pvc.yaml
	kubectl create -f kubernetes/cmpsite_02_configmap-cmpsite.yaml
	kubectl create -f kubernetes/cmpsite_03_configmap-logging.yaml
	kubectl create -f kubernetes/cmpsite_04_secret-cmpsite.yaml
	kubectl create -f kubernetes/cmpsite_05_secret-cmpdb.yaml
	kubectl create -f kubernetes/cmpsite_06_deployment_AWS.yaml
	kubectl create -f kubernetes/cmpsite_07_service.yaml
	-kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/cloud/deploy.yaml

deploy-tls:
	# creation of certificate secret and ingress adding https funcionality over TLS
  # Note: assumes a previous make-deploy execution. Splitted due additional kubernetes cluster modifications are needed (ingress-nginx-admission).
	kubectl create secret tls cmpsite-tls --key kubernetes/tls/key.pem --cert kubernetes/tls/cert.pem -n cmpsite-namespace
	-kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
	kubectl create -f kubernetes/tls/cmpsite_08_ingress.yaml

test:
	# runs sequentially tests from a [python script](testing/testing_requests.py) though a  [wrapper](testing/testing_wrapper-remote.sh) checking the implemented API methods are working properly against _DJANGO_BASE_URL_
	sh testing/testing_wrapper-remote.sh

test-tls:
	# runs sequentially tests from a [python script](testing/testing_requests.py) though a  [wrapper](testing/testing_wrapper-remote.sh) using HTTPS/TLS protocol and BASE_URL_TLS/secure paths against _DJANGO_BASE_URL_
	sh testing/testing_wrapper-remote-tls.sh

test-curl:
	# runs sequentially tests using django framework [tests.py](testing/testing_requests.py) though a  [wrapper](testing/testing_wrapper-local.sh) that the implemented API methods are working properly
	sh testing/testing_request-curl.sh

test-local:
	# runs sequentially tests from though a [bash script](testing/testing_wrapper-curl.sh) using HTTP/plain and HTTPS/TLS protocol and BASE_URL_TLS/secure paths against _DJANGO_BASE_URL_
	sh testing/testing_wrapper-local.sh

test-resiliency:
	# testing if after manually killing the running pod, a new pod is recreated. After is finished, any other test can be run to test if the API methods are working properly again. Set up on a [wrapper](testing/testing_wrapper-resiliency.sh)
	sh testing/testing_wrapper-resiliency.sh

test-security:
	# testing though django framework if the application passes all the documented [Deployment checks](https://docs.djangoproject.com/en/3.0/howto/deployment/checklist/). Set up on a [wrapper](testing/testing_wrapper-security.sh)
	sh testing/testing_wrapper-security.sh

clean:
	# deletes the kubernetes resources and container images created during the build and deploy
	-kubectl delete -f kubernetes/tls/cmpsite_08_ingress.yaml
	-kubectl delete secret cmpsite-tls -n cmpsite-namespace
	-kubectl delete -f kubernetes/cmpsite_07_service.yaml
	-kubectl delete -f kubernetes/cmpsite_06_deployment.yaml
	-kubectl delete -f kubernetes/cmpsite_05_secret-cmpdb.yaml
	-kubectl delete -f kubernetes/cmpsite_04_secret-cmpsite.yaml
	-kubectl delete -f kubernetes/cmpsite_03_configmap-logging.yaml
	-kubectl delete -f kubernetes/cmpsite_02_configmap-cmpsite.yaml
	-kubectl delete -f kubernetes/cmpsite_01_pvc.yaml
	-kubectl delete -f kubernetes/cmpsite_00_namespace.yaml
	-sh docker/docker_clean_wrapper.sh
