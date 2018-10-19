#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

# Code to set up the Nexus. It will need to
# * Create Nexus
# * Set the right options for the Nexus Deployment Config
# * Load Nexus with the right repos
# * Configure Nexus as a docker registry
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
# while : ; do
#   echo "Checking if Nexus is Ready..."
#   oc get pod -n ${GUID}-nexus|grep '\-2\-'|grep -v deploy|grep "1/1"
#   [[ "$?" == "1" ]] || break
#   echo "...no. Sleeping 10 seconds."
#   sleep 10
# done

# Ideally just calls a template
# oc new-app -f ../templates/nexus.yaml --param .....

# To be Implemented by Student

oc project ${GUID}-nexus

# Option 1: oc commands

# # Create Nexus
# oc new-app docker.io/sonatype/nexus3:latest
# oc expose svc nexus3
# # Setup Deployment Config
# oc rollout pause dc nexus3
# # Change the deployment strategy from Rolling to Recreate and set requests and limits for memory
# oc patch dc nexus3 --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'
# oc set resources dc nexus3 --limits=memory=2Gi,cpu=2 --requests=memory=1Gi,cpu=500m
# # Create a persistent volume claim and mount it at /nexus-data
# echo "apiVersion: v1
# kind: PersistentVolumeClaim
# metadata:
#   name: nexus-pvc
# spec:
#   accessModes:
#   - ReadWriteOnce
#   resources:
#     requests:
#       storage: 4Gi" | oc create -f -
# oc set volume dc/nexus3 --add --overwrite --name=nexus3-volume-1 --mount-path=/nexus-data/ --type persistentVolumeClaim --claim-name=nexus-pvc
# # Set up liveness and readiness probes
# oc set probe dc/nexus3 --liveness --failure-threshold 3 --initial-delay-seconds 60 -- echo ok
# oc set probe dc/nexus3 --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8081/repository/maven-public/
# # Resume deployment to roll out all changes at once
# oc rollout resume dc nexus3
# # Create a Service called nexus-registry that exposes port 5000 from the deployment configuration nexus3.
# oc expose dc nexus3 --port=5000 --name=nexus-registry
# # Create an OpenShift route called nexus-registry that uses edge termination for the TLS encryption and exposes port 5000.
# oc create route edge nexus-registry --service=nexus-registry --port=5000


# Option 2: import yaml template
oc process -f Infrastructure/templates/nexus.yaml | oc create -f -

# Make sure to wait until Nexus if fully up and running
while : ; do
  echo "Checking if Nexus is Ready..."
  oc get pod -n ${GUID}-nexus|grep '\-2\-'|grep -v deploy|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/wkulhanek/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh | bash -s admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}'