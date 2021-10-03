# cmpsite
Cmpsite is a python application based on django restapi framework, running Docker containers on kubernetes. The workflow is splitted on an initial InitContainer (cmpsite-init, initalizing the app), then a main container (cmpite-run, running the django server) and also a sidecar container forwarding logs (sidecar-fluentd, a fluentd standard image sharing logs volume).
