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

deploy:
	@oc create namespace ${NS}
	@oc -n ${NS} create configmap registry-conf --from-file=registry-config.yaml
	@oc -n ${NS} create -f deployment.yaml
	@oc -n ${NS} create -f service.yaml
	#oc -n ${NS} create route edge ${NS} --service=${NS} --port=app --insecure-policy=Redirect

create_secret:
	@mkdir -p ./${BUILD_DIR}
	@htpasswd -bBc ./${BUILD_DIR}/htpasswd ${REG_US} ${REG_PASS}
	@oc -n ${NS} create secret generic ${SECRET} --from-file=./${BUILD_DIR}/htpasswd

create_ps:
	@podman login ${DESTINATION_REGISTRY} -u ${REG_US} -p ${REG_PASS} --authfile=${BUILD_DIR}/${PULL_SECRET}

clean:
	@oc -n ${NS} delete -f service.yaml -f deployment.yaml
	@oc -n ${NS} delete secret ${SECRET}
