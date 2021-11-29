KUBECONFIG ?= ${HOME}/.kcli/clusters/hub/auth/kubeconfig
NS ?= kubeframe-registry
SECRET ?= auth
REG_US ?= dummy
REG_PASS ?= dummy
BUILD_DIR ?= build 
PULL_SECRET ?= pull_secret.json

.EXPORT_ALL_VARIABLES:
.PHONY: deploy

default: deploy

deploy: create_ns
	@oc -n $(NS) create configmap registry-conf --from-file=config.yml -o yaml --dry-run=client | oc apply -f -
	@oc -n $(NS) create -f manifests/deployment.yaml -o yaml --dry-run=client | oc apply -f -
	@oc -n $(NS) create -f manifests/service.yaml -o yaml --dry-run=client | oc apply -f -
	@oc -n $(NS) create -f manifests/pvc-registry.yaml -o yaml --dry-run=client | oc apply -f -
	@oc -n ${NS} create route reencrypt ${NS} --service=${NS} --port=registry --insecure-policy=Redirect -o yaml --dry-run=client | oc apply -f -

create_secret: create_ns
	@mkdir -p ./$(BUILD_DIR)
	@htpasswd -bBc  $(addsuffix /htpasswd,$(BUILD_DIR)) $(REG_US) $(REG_PASS)
	@oc -n $(NS) create secret generic $(SECRET) --from-file=$(addsuffix /htpasswd,$(BUILD_DIR)) -o yaml --dry-run=client | oc apply -f -

create_ns:
	@oc create namespace $(NS) -o yaml --dry-run=client | oc apply -f -

create_ps:
	$(eval DESTINATION_REGISTRY=$(shell oc -n $(NS) get route kubeframe-registry -o jsonpath={.status.ingress[0].host}):443)
	@podman login $(DESTINATION_REGISTRY) -u $(REG_US) -p $(REG_PASS) --authfile=$(addsuffix $(PULL_SECRET),$(BUILD_DIR))

clean:
	@oc -n $(NS) delete -k manifests/ 
	@oc -n $(NS) delete secret $(SECRET)
