#!/bin/bash

# Process the repository and works out whether it holds a single workshop
# or multiple workshops and processes the workshop resource files in each.

set -x

SCRIPTS_DIR=$(
    cd "$(dirname $BASH_SOURCE)"
    pwd
)

REPOSITORY_PATH=$1
REPOSITORY_NAME=$2
REPOSITORY_OWNER=$3
REPOSITORY_TAG=$4
IMAGE_PATTERN=$5
IMAGE_REPLACEMENT=$6
WORKSHOP_FILENAME=$7
PORTAL_FILENAME=$8
OUTPUT_DIRECTORY=$9

# Make the output directory and sub directories for processed files.

mkdir -p $OUTPUT_DIRECTORY/workshops

# Generate YAML data values file for use with ytt.

ytt -f $SCRIPTS_DIR/action-values.yaml \
    --data-value name=${REPOSITORY_NAME} \
    --data-value owner=${REPOSITORY_OWNER} \
    --data-value version=${REPOSITORY_TAG} \
    --data-value registry=ghcr.io/${REPOSITORY_OWNER} \
    --data-value tag=${REPOSITORY_TAG} \
    --data-value image.pattern=${IMAGE_PATTERN} \
    --data-value image.replacement=${IMAGE_REPLACEMENT} \
    > $OUTPUT_DIRECTORY/action-config.yaml


# Replace variables in each workshop file and place result in output
# workshops directory.

function process_workshop_file() {
    local WORKSHOP_FILENAME=$1

    ytt --file "$WORKSHOP_FILENAME" \
        --file-mark "$(basename $WORKSHOP_FILENAME):type=data" \
        --file $SCRIPTS_DIR/replace-variables.yaml \
        --file $SCRIPTS_DIR/core-functions.star \
        --data-values-file $OUTPUT_DIRECTORY/action-config.yaml \
        --data-value workshop.file="$(basename $WORKSHOP_FILENAME)"
}

if [ -d $REPOSITORY_PATH/workshops ]; then
    for file in $REPOSITORY_PATH/workshops/*/$WORKSHOP_FILENAME; do
        workshop=$(basename $(dirname $(dirname $file)))

        mkdir -p $OUTPUT_DIRECTORY/workshops/$workshop/resources

        process_workshop_file $file > $OUTPUT_DIRECTORY/workshops/$workshop/resources/workshop.yaml
    done

    WORKSHOP_DEFINITIONS=workshops.yaml
else
    workshop=$REPOSITORY_NAME

    mkdir -p $OUTPUT_DIRECTORY/workshops/$workshop/resources

    process_workshop_file $REPOSITORY_PATH/$WORKSHOP_FILENAME > $OUTPUT_DIRECTORY/workshops/$workshop/resources/workshop.yaml

    WORKSHOP_DEFINITIONS=workshop.yaml
fi

# Merge all the workshop files into one file and create archive as well.

ytt -f $OUTPUT_DIRECTORY/workshops > $OUTPUT_DIRECTORY/$WORKSHOP_DEFINITIONS

tar -z -C $OUTPUT_DIRECTORY -cvf $OUTPUT_DIRECTORY/workshops.tar.gz workshops

(cd $OUTPUT_DIRECTORY; zip $OUTPUT_DIRECTORY/workshops.zip -r workshops)

# Determine if we need to build an OCI image artefact for workshop content or a
# container image for a custom workshop base image. When there are multiple
# workshops only one of each can be created, and not one for each workshop.

if grep "url: *ghcr.io/${REPOSITORY_OWNER}/${REPOSITORY_NAME}-image:${REPOSITORY_TAG}" $OUTPUT_DIRECTORY/$WORKSHOP_DEFINITIONS; then
    echo "build_image=true" >> $GITHUB_OUTPUT
fi

if grep "url: *ghcr.io/${REPOSITORY_OWNER}/${REPOSITORY_NAME}-files:${REPOSITORY_TAG}" $OUTPUT_DIRECTORY/$WORKSHOP_DEFINITIONS; then
    echo "build_files=true" >> $GITHUB_OUTPUT
fi
