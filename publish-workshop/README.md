Publish Workshop
================

This GitHub action supports the following for an Educates workshop:

* Creating an OCI image artefact containing workshop content files and pushing
  it to the GitHub container registry.
* Creating a custom workshop base image for the workshop, with workshop content
  files optionally included if required, and pushing it to the GitHub container
  registry.
* Creating a release against the GitHub repository and attach as assets
  Kubernetes resource files for deploying the workshop to Educates.

Both a single workshop, or multiple workshops are supported. In the case of
multiple workshops, each named workshop needs to be in a separate subdirectory
of the `workshops` subdirectory. For the case of multiple workshops there is
however still only one OCI image artefact created which includes content for all
workshops in the repository. The workshop definitions therefore need to
selective filter only the files from the OCI image artefact for that workshop.
Similarly, only one custom workshop base image is supported, where the
`Dockerfile` needs to exist in the root of the repository or designated path.

The GitHub action requires that it be triggered in response to a Git tag being
applied to the GitHub repository.

GitHub Workflow
---------------

The name of the GitHub action is:

```
vmware-tanzu-labs/educates-github-actions/publish-workshop
```

To have an Educates workshop published upon the repository being tagged as
version `X.Y` use:

```
name: Publish Workshop

on:
  push:
    tags:
      - "[0-9]+.[0-9]+"

jobs:
  publish-workshop:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Create release
        uses: vmware-tanzu-labs/educates-github-actions/publish-workshop@v4
        with:
          token: ${{secrets.GITHUB_TOKEN}}
```

Workshop Definition
-------------------

Whether an OCI image artefact, custom workshop base image, or both are created
and published is dictated by settings contained in the Educates `Workshop`
resource definition found in the `resources/workshop.yaml` file.

An OCI image artefact with workshop content files will be published where the
`Workshop` resource definition contained `spec.workshop.files` set in the
following form:

```
apiVersion: training.educates.dev/v1beta1
kind: Workshop
metadata:
  name: {name}
spec:
  workshop:
    files:
    - image:
        url: $(image_repository)/{name}-files:latest
```

A custom workshop base image for the workshop will be built and published where
the `Workshop` resource definition contained `spec.workshop.image` set in the
following form:

```
apiVersion: training.educates.dev/v1beta1
kind: Workshop
metadata:
  name: {name}
spec:
  workshop:
    image: $(image_repository)/{name}-image:latest
```

Both an OCI image artefact with workshop content files, and a custom workshop
base image for the workshop will be built and published where the `Workshop`
resource definition contained `spec.workshop.image` and `spec.workshop.files`
set in the following form:

```
apiVersion: training.eduk8s.io/v1alpha2
kind: Workshop
metadata:
  name: {name}
spec:
  workshop:
    image: $(image_repository)/{name}-image:latest
    files:
    - image:
        url: $(image_repository)/{name}-files:latest
```

The text string `{name}` appearing in the `metadata.name`, `spec.workshop.image`
and `spec.workshop.files` properties should be the same, and must match the name
of the GitHub repository.

The values of the `spec.workshop.image` and `spec.workshop.files[].image.url`
properties as a whole which will trigger creation and publishing of the OCI
image artefact and custom workshop base image, as well as the location of the
file containing the `Workshop` resource definition can be customized using the
action configuration.

When an OCI image artefact with workshop content files, or a custom workshop
base image for the workshop are built and published to GitHub container
registry, the `spec.workshop.image` and `spec.workshop.files` references in the
`Workshop` resource definition will be rewritten to be the target locations when
the `Workshop` resource definition is attached as asset to the release.

Multiple Workshops
------------------

In the case of multiple workshops you must have a `workshops` subdirectory.
Under that directory there needs to be separate subdirectories for each
workshop, with name matching the name of the workshop in the workshop
definition.

The format of the respective workshop definitions for the workshop content
files should be:

```
apiVersion: training.educates.dev/v1beta1
kind: Workshop
metadata:
  name: {name}
spec:
  workshop:
    files:
    - image:
        url: $(image_repository)/{repository}-files:latest
      includePaths:
      - /workshops/{name}/workshop/**
      newRootPath: workshops/{name}
```

The text string `{name}` appearing in the `metadata.name` and
`spec.workshop.image` properties should be the same, and must match the name of
the workshop subdirectory under the `workshops` directory. The text string
`{repository}` must match the name of the GitHub repository.

Action Configuration
--------------------

Configuration parameters which can be set in the `with` clause for the this
GitHub action are as follows:

| Name                            | Required | Type     | Description                        |
|---------------------------------|----------|----------|------------------------------------|
| `image-regular-expression`      | False    | String   | Regular expression to match any image references in Workshop resource file. Defaults to `'\$\(image_repository\)/(.+):latest'`. |
| `image-replacement-string`      | False    | String   | Target reference to replace source image reference in the `Workshop` resource file. Defaults to `'{registry}/$1:{tag}'`. |
| `path`                          | False    | String   | Relative directory path under `$GITHUB_WORKSPACE` to workshop files. Defaults to "`.`". |
| `token`                         | True     | String   | GitHub access token. Must be set to `${{secrets.GITHUB_TOKEN}}` or appropriate personal access token variable reference. |
| `trainingportal-resource-file`  | False    | String   | Relative path under workshop directory to the `TrainingPortal` resource file. Defaults to "`resources/trainingportal.yaml`". |
| `workshop-image-docker-file`    | False    | String   | Path under workshop directory to the `Dockerfile` for custom workshop image. Defaults to "`Dockerfile`". |
| `workshop-resource-file`        | False    | String   | Relative path under workshop directory to the `Workshop` resource file. Defaults to "`resources/workshop.yaml`". |

 When specifying the replacement string the special `{name}`, `{registry}`, `{owner}`, `{name}` and `{tag}` variable references can be used. The meaning of these variables references are as follows:
 
 | Variable     | Description |
 |--------------|-------------|
 | `{name}`     | The name of the GitHub repository (forced to lowercase). |
 | `{owner}`    | The GitHub repository account owner (forced to lowercase). |
 | `{registry}` | The expansion of `ghcr.io/{owner}`. |
 | `{tag}`      | The Git tag applied to the commit the action is run against which triggered the action. |
