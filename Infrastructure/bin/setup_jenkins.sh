#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student

oc project ${GUID}-jenkins

# Set up a persistent Jenkins instance with 2 GB of memory and a persistent volume claim of 4 GB.
oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi

# Allow the Maven slave pod to consume 2Gi of memory when building a JEE application
oc rollout pause dc jenkins
oc set resources dc jenkins --limits=memory=2Gi,cpu=2 --requests=memory=2Gi,cpu=1
oc rollout resume dc jenkins

# Build the custom Maven slave pod to include Skopeo
oc new-build --name="jenkins-slave-appdev" --dockerfile="$(< Infrastructure/templates/jenkins-slave-Dockerfile)"

# Build configurations for the pipelines in the source code project
oc create -f Infrastructure/templates/mlbparks-pipeline.yaml
oc create -f Infrastructure/templates/nationalparks-pipeline.yaml
oc create -f Infrastructure/templates/parksmap-pipeline.yaml

# Pass GUID and CLUSTER to all pipelines
oc set env bc/mlbparks-pipeline GUID=${GUID} CLUSTER=${CLUSTER}
oc set env bc/nationalparks-pipeline GUID=${GUID} CLUSTER=${CLUSTER}
oc set env bc/parksmap-pipeline GUID=${GUID} CLUSTER=${CLUSTER}