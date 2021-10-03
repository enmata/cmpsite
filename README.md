## CMP Site
### Abstract
This document tries to explain the application workflow, set up and configuration of
Cmpsite is a python application based on django restapi framework, running Docker containers on kubernetes. The workflow is splitted on an initial InitContainer (cmpsite-init, initalizing the app), then a main container (cmpite-run, running the django server) and also a sidecar container forwarding logs (sidecar-fluentd, a fluentd standard image sharing logs volume).

### Assumptions and requirements
Deploy scripts are assuming:
-python 3, pip3, virtualenv and curl are installed on the environment
-docker daemon running building docker images
-access and rights to a docker registry (AWS ECR used during development)
-kubectl credentials set up for a kubernetes cluster
-access and rights to a kubernetes cluster with permissions to create namespace, configmaps, secrets, and deployment

### Tool/Libraries usage
The following tools has been used:
- python 3.8
- django 3.1.6 framework
- python pip3 modules (and its dependencies)
   - Site
    -- Django                [3.1.6] _# base site framework_
    -- os                    [standard python lib] _# environment variable reading from secrets and configmapst_
    -- loggger              [standard python lib] _# logging HTTP requests to _$DJANGO_LOG_LOCATION_
   - Testing
    -- requests              [2.25.1] _# http methods management_
   - Healthcheck
    -- django-health-check [3.16.2] _# implementing heathcheck BASE_URL/hc_
   - REST api
    -- djangorestframework [3.12.2] _# base REST api framework_
 - database
    SQLite 3 [django.db.backends.sqlite3] _# relational database storing user data_
 - logging
    Fluentd agent [public container image] _# using as a sidecar container forwarding application log from _DJANGO_LOG_LOCATION_
- containerization
  - Docker [20.10.2] _# containers running the application_
  - kubernetes [1.18]
        - namespaces _# application environment isolation_
        - PersistentVolumeClaim _# storing database data_
        - configMaps      _# centralizing configuration settings_
        - secrets         _# storing critical data such as users and passwords_
        - deployments     _# ensuring resiliency_
        - services        _# making services available on the network_
        - ingress         _# enabling https access_
        - initcontainers  _# splitting initialization data and scripts from the running phase_

### Deployment pipeline and testing with make file
The following stages has been defined on the [Makefile](MakeFile)

- **make all**
    runs sequentially all the workflow: "make build", "make deploy", "make test" and "make clean"
- **make build**
    creation and push the necessary docker images on local docker daemon for minikube environment
- **make build-AWS**
    creation and push the necessary docker images to a new ECR registry on AWS
- **make deploy**
    sequencial creation of all the needed resources on an isolated kubernetes namespace cmpsite-namespace for minikube environment. Also enabling ingress-nginx module.
- **make deploy-aws**
    sequential creation of all the needed resources on an isolated kubernetes namespace cmpsite-namespace using AWS deployment. Also installing [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/) from the official manifest.
- **make deploy-tls**
    creation of certificate secret and ingress adding https functionality over TLS
    Note: assumes a previous make-deploy execution. Splitted due additional kubernetes cluster modifications are needed (ingress-nginx-admission).
- **make test**
    runs sequentially tests from a [python script](testing/testing_requests.py) though a  [wrapper](testing/testing_wrapper-remote.sh) checking the implemented API methods are working properly against _DJANGO_BASE_URL_
- **make test-ssl**
    runs sequentially tests from a [python script](testing/testing_requests.py) though a  [wrapper](testing/testing_wrapper-remote.sh) using HTTPS/TLS protocol and BASE_URL_TLS/secure paths against _DJANGO_BASE_URL_
- **make test-curl**
    runs sequentially tests from though a [bash script](testing/testing_wrapper-curl.sh) using HTTP/plain and HTTPS/TLS protocol and BASE_URL_TLS/secure paths against _DJANGO_BASE_URL_
- **make test-local**
    runs sequentially tests using django framework [tests.py](testing/testing_requests.py) though a [wrapper](testing/testing_wrapper-local.sh) that the implemented API methods are working properly
- **make test-resiliency**
    esting if after manually killing the running pod, a new pod is recreated. After is finished, any other test can be run to test if the API methods are working properly again. Set up on a [wrapper](testing/testing_wrapper-resiliency.sh)
- **make test-security**
    testing though django framework if the application passes all the documented [Deployment checks](https://docs.djangoproject.com/en/3.0/howto/deployment/checklist/). Set up on a [wrapper](testing/testing_wrapper-security.sh)
- **make clean**
    deletes the kubernetes resources and container images created during the build and deploy

### Folder structure
Files and scripts has been distributed as follows:
```
├── Makefile    # Makefile defining the workflow deploying, testing, and wrapping up the application
├── Readme.rd   # Project documentation
├── docker      # Folder containing the application and the necessary files for docker image creation
│       ├── Dockerfile-init
│       ├── Dockerfile-run
│       ├── cmpsite         # Folder containing the entire application
│       │  ├── cmpapi       # Folder containing the API django framework application
│       │  ├── cmpsite      # Folder containing the API django framework application
│       │  └── manage.py    # Management script to migrate and start django application
│       ├── docker_build_wrapper_AWS.sh # wrapper script to build and push the necessary docker images to a new ECR registry on AWS
│       ├── docker_build_wrapper.sh # wrapper script to build and push the necessary docker images on local docker daemon for minikube environment
│       ├── docker_clean_wrapper.sh # wrapper script to clean up the necessary docker images previously created
│       ├── docker_clean_wrapper.sh # wrapper script to clean up the necessary docker images previously created
│       ├── initscript.sh   # initialization script, running on execution time from initContainer image, to initialize the application
│       └── requirements_cmpsite.txt # python pip virtualenv requirements file for the entire cmpsite django application
├── kubernetes  # Folder containing yaml files declaring the necessary resources to be created on kubernetes
└── testing     # Folder containing necessary files for testing
    ├── requirements_testing_wrapper_local.txt     # python pip requirements file for the django framework test execution
    ├── requirements_testing_wrapper_remote.txt    # python pip requirements file for virtualenv using custom python class
    ├── testing_request_curl.sh    # wrapper for testing API using curl
    ├── testing_requests.py        # custom python class for testing API methods
    ├── testing_wrapper-local.sh   # wrapper for testing API using django framework "python3 manage.py test"
    ├── testing_wrapper-remote-tls.sh   # wrapper for testing API HTTPS/TLS access on a remote location using custom python class
    ├── testing_wrapper-remote.sh       # wrapper for testing API HTTP/plain access on a remote location using custom python class
    ├── testing_wrapper-resliency.sh    # wrapper for testing API using django framework "python3 manage.py test"
    └── testing_wrapper-security.sh     # wrapper for passing security django deployment checks "python3 manage.py check"

```
**Additional notes:**
- cmpsite folder is inside docker folder due a docker-build utility limitation
- wrappers for docker build, docker clean and testing has been wrapped in separated scripts for a better structure reading and MakeFile limitations (virtualenv, environment variables and folder mobility)

### Network connectivity
  - **http/plain communication**
    -- the django application is listening internally on TCP port 8000, inside the container (targetPort)
    -- the vip of the cmpsite-service is listening on TCP port 30008
    Set up on Docker [entrypoint](docker/Dockerfile-run), kubernetes [deployment yaml](kubernetes/cmpsite_05_deployment.yaml), and kubernetes [service-yaml](kubernetes/cmpsite_06_service.yaml)

 - **https/TLS communication**
    -- TLS communication termination from cmpsite-service to public endpoint is managed by a kubernetes ingress and TLS secrets.
    -- kubernetes nginx ingress is listening on standard TCP port 443.
    -- All implemented endpoint URLs and methods can be accessed by HTTPS after deploying tls secret and kubernetes ingress on _BASE_URL_TLS/secure/_.
    TLS Requirements:
    - [NGINX kubernetes Ingress controller](https://kubernetes.github.io/ingress-nginx/user-guide/tls/) needs to be deployed
    - TLS certificates (used self-signed), or generated by request suing  [certmanager] (https://cert-manager.io/docs/installation/kubernetes/#installing-with-regular-manifests)
    Issues:
    - Certificates is self signed, so 2 changes has been needed:
    -- Skip certificate check on testing scripts by setting  the _CURL_CA_BUNDLE_ variable empty on the [testing wrapper](testing/testing_wrapper-remote-tls.sh)
    -- ValidatingWebhookConfiguration on ingress-nginx-admission has been deleted

### API Endpoints
**HTTP**
The following endpoint URLs and methods can be accessed by HTTP
- BASE_URL/admin/           # management entrypoint (admin user defined on configMap cmpsite-configmap)
- BASE_URL/user/            # main api path
    - GET /user/{id}        # Retrieves a specific user
    - POST /user            # Creates a new user
    - DELETE /user/{id}     # Deletes a specific user
- BASE_URL/hc               # path for healthcheck

**HTTPS**
All previous endpoint URLs and methods can be accessed by HTTPS after deploying tls secret and kubernetes ingress
- BASE_URL_TLS/secure/admin/    # management entrypoint (admin user defined on configMap cmpsite-configmap)
- BASE_URL_TLS/secure/user/     # main api path
    - GET /user/{id}            # Retrieves a specific user
    - POST /user                # Creates a new user
    - DELETE /user/{id}         # Deletes a specific user
- BASE_URL_TLS/secure/hc        # path for healthcheck

Set up on urls files on [cmpapi](docker/cmpsite/cmpapi/urls.py) and [cmpsite](docker/cmpsite/cmpsite/urls.py)
Ingress set up on [kubernetes ingress yaml](kubernetes/tls/cmpsite_08_ingress.yaml)

### Configuration parameters
Configuration parameters are customizable as follows:
**cmpsite configMap**: Most of cmpsite/django configuration parameters:
- **DJANGO_ALLOWED_HOSTS**: allowed IP to reach the API. Used value "192.168.99.107" during minikube tests
- **DJANGO_DEBUG**: Enabling or disabling test and debug info from django framework. Not mandatory, True by default.Make sure is set up as "False" to production
- **DJANGO_BASE_URL**: URL where the testing will be executed. Mandatory. Used value "http://192.168.99.107:30008" during minikube tests.
- **DJANGO_DB_LOCATION**: Path inside the container image where SQLite is stored. By default 'cmpsite/cmpdb/db.sqlite3'. This path should be set according to volume mountpath db-data-volume declared on [Deployment yaml](cmpsite/kubernetes/cmpsite_06_deployment.yaml).
- **DJANGO_LOG_LEVEL**: Setting logging from cmpsite REST djangorestframework framework. "INFO" by default. Accepted levels: CRITICAL, ERROR, WARNING, INFO and DEBUG.
- **DJANGO_LOG_LOCATION**: Path inside the container image where cmpsite REST djangorestframework log is stored. By default '/var/log/cmpsite/django.log'. This path should be set according to volume mountpath db-data-volume declared on [Deployment yaml](cmpsite/kubernetes/cmpsite_06_deployment.yaml).

**configmap-logging**: kubernetes configmap centralizing sidecar fluentd container parameters and config file
**cmpsite-secret**: kubernetes secret containing django application secret key
**cmpsdb-secret**: kubernetes secret containing SQLite3 django admin database credentials

### Docker images
- **cmpsite-init**: initContainer running only on the deploy used to initialize application database on _DJANGO_DB_LOCATION_
- **cmpsite-run**: main container running cmpsite application, storing logs on _DJANGO_LOG_LOCATION_ and using database from _DJANGO_DB_LOCATION_
- **sidecar-fluentd**: standard public image containing fluend agent, that will forward log from _DJANGO_LOG_LOCATION_

### Volumes
The applications is using the following volumes:
- **db-data-volume**: persistent volume storing cmpsite database, used by cmpsite-init and cmpsite-run containers, mounted according to _DJANGO_DB_LOCATION_
- **cmpsite-log-volume**: emptydir volume storing cmpsite logs, used by cmpsite-run and sidecar-fluentd, mounted according to as _DJANGO_LOG_LOCATION_

### Database
User data is saved using SQLite 3 relational database:
- Using driver/connector django.db.backends.sqlite3. Set up on [settings file](docker/cmpsite/cmpsite/settings.py) -> DATABASES section
- Saved on file "cmpsite/cmpdb/db.sqlite3", formerly stored on a shared volume "db-data-volume". Storage locations set up on [kubernetes configmap yaml](kubernetes/cmpsite_02_configmap-cmpsite ) and kubernetes [deployment yaml](kubernetes/cmpsite_05_deployment.yaml)
- Initialized by using and [init script](docker/initscript.sh) running on initContainer execution as [ENTRYPOINT] (docker/Dockerfile-init)

On future optimizations, if the data is migrated to an external database, multiple running container instances can be connected to the same database at the same time.

### Logs Management
Generated logs are managed following the sidecar container strategy.
The cmpsite application stores the log on _DJANGO_LOG_LOCATION_ using the python standard logging library (defined on [cmpapi views](cmpsite/cmpapi/views.py) and on [cmpsite settings file](cmpsite/cpsite/settings.py).
This log is stored on _cmpsite-log-volume_ volume.
Log level and path are set up using the _cmpsite-configmap_ ConfigMap accordingly to the Deployment mountPaths.
This container is also mounted by a sidecar container running fluend agent. These agents are able to forward
With this approach we are able to centralize the log processing and also restrict the access to log forwarder, reducing the attack surface.

**Additional notes**:
-The entrypoint of that container has been overridden by a "sleep" to hold the container alive during the tests. In a production environment these entrypoint and related configMap needs to be set up.
-If additional logs are needed (like all the containers output from hosts /var/lib/docker/containers), then the [fluentd daemonSet](https://docs.fluentd.org/container-deployment/kubernetes#fluentd-daemonset) image needs to be deployed on kube-system namespace with the proper rights

### Healthcheck
A healthcheck has been implemented, checking the app, db, cache, storage and migrations
- Based on django-health-check django module
- Accessible by **BASE_URL**/hc endpoint
- Json response calling **BASE_URL**/hc/?format=json
- Can be used on future loadbalancers implementations (200 status response)

Set up on [cmpsite settings file](docker/cmpsite/cmpsite/settings.py) -> INSTALLED_APPS and [cmpapi urls](docker/cmpsite/cmpapi/urls.py)

### Reliability and resiliency
Reliability and resiliency has been assured using 3 different strategies:
**Kubernetes Deployment**: The application is deployed as a deployment kubernetes resource. The deployment controller inside Kubernetes takes care of having at least one container replica always available.
**Isolating initialization on initContainer**: Initialization of the application has been isolated on a separate container using a kubernetes initContainer. In case the running container(s) needs to be recreated, we do not lose data reinitializing again the application.
**Separate volume**: All status/permanent data is stored on a separate volume (db-data-volume) on mountPath /cmpsite/cmpdb. In case the running container(s) needs to be recreated, we do not lose data.

In future optimizations, same strategy can be kept splitting running containers for initialization

Set up on Docker [entrypoint](docker/Dockerfile-run) and kubernetes [deployment yaml](kubernetes/cmpsite_05_deployment.yaml)

### Security and best practices
- sensitive data such as secret used for django application or database credentials has been stored as kubernetes secrets
- database credentials secret has been splitted from secret used for django application, making it only accessible for the necessary initContainer
- all kubernetes resources has been created on a custom namespace
- configuration parameters has been centralized on a kubernetes configMap
- minimal alpine images (python:3.8.3-alpine) has been used as base image for applications, avoiding overhead
- only specific hosts has been allowed on cmpsite settings, configurable using DJANGO_ALLOWED_HOSTS variable
- only needed methods has been allowed on [views](docker/cmpsite/cmpapi/views.py) setting _http_method_names_ variable
- all the application flow can be managed using the Makefile
- Additional verbosity has been added on unittest execution (verbosity=2)
- logging strategy is using sidecar approach, centralizing log processing and reducing attack surface
- application initialization has been isolated on a specific initContainer reducing attack surface

### Moving to production and possible upgrades
[ ] Set up [kubernetes configMap yaml](kubernetes/cmpsite_02_configmap-cmpsite.yaml) and MountPaths on [kubernetes deployment yaml](kubernetes/cmpsite_05_deployment.yaml)
[ ] Pass all the django documented [Deployment checks](https://docs.djangoproject.com/en/3.0/howto/deployment/checklist/)
[ ] Avoid self signed certificates for HTTPS TLS
[ ] Restrict network rules accessing only to the required endpoint URLs
[ ] Set up fluentd agent monitoring entrypoint on [kubernetes deployment yaml](kubernetes/cmpsite_05_deployment.yaml) and logging [kubernetes configMap yaml](kubernetes/cmpsite_02_configmap-logging.yaml)
[ ] Set up log rotation avoiding disk full issues
[ ] Set up limits on database seize disk full issues
[ ] Additional fields and methods on the API. Set up on [models](cmpsite/cmpapi/models.py) and [serializers](cmpsite/cmpapi/serializers.py)
[ ] HTTPS TLS only access on the API [kubernetes ingress nginx controller](https://kubernetes.github.io/ingress-nginx/examples/tls-termination/)
[ ] Migrate to an external database on a managed/permanent database service [on django](https://docs.djangoproject.com/en/3.1/ref/databases/)
[ ] Multiple pods on the running deployment. Set up on [kubernetes deployment yaml](kubernetes/cmpsite_05_deployment-test.yaml
[ ] Authentication based on [custom user model by token](https://docs.djangoproject.com/en/3.0/topics/auth/customizing/#writing-an-authentication-backend)
