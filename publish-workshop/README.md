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
        uses: vmware-tanzu-labs/educates-github-actions/publish-workshop@v1
        with:
          token: ${{secrets.GITHUB_TOKEN}}
```

Workshop Definition
-------------------

Whether an OCI image artefact, custom workshop base image, or both are created
and published is dictated by settings contained in the Educates `Workshop`
resource definition found in the `resources/workshop.yaml` file.

An OCI image artefact with workshop content files will be published where the
`Workshop` resource definition contained `spec.content.files` set in the
following form:

```
apiVersion: training.eduk8s.io/v1alpha2
kind: Workshop
metadata:
  name: {name}
spec:
  content:
    files: imgpkg+http://registry.eduk8s.svc.cluster.local:5001/{name}-files:latest
```

A custom workshop base image for the workshop will be built and published where
the `Workshop` resource definition contained `spec.content.images` set in the
following form:

```
apiVersion: training.eduk8s.io/v1alpha2
kind: Workshop
metadata:
  name: {name}
spec:
  content:
    image: registry.eduk8s.svc.cluster.local:5001/{name}-image:latest
```

Both an OCI image artefact with workshop content files, and a custom workshop
base image for the workshop will be built and published where the `Workshop`
resource definition contained `spec.content.images` and `spec.content.files`
set in the following form:

```
apiVersion: training.eduk8s.io/v1alpha2
kind: Workshop
metadata:
  name: {name}
spec:
  content:
    image: registry.eduk8s.svc.cluster.local:5001/{name}-image:latest
    files: imgpkg+http://registry.eduk8s.svc.cluster.local:5001/{name}-files:latest
```

The text string `{name}` appearing in the `metadata.name`, `spec.content.image`
and `spec.content.files` properties should be, and must match, the name of the
GitHub repository.

The values of the `spec.content.image` and `spec.content.files` properties as a
whole which will trigger creation and publishing of the OCI image artefact and
custom workshop base image, as well as the location of the file containing the
`Workshop` resource definition can be customized using the action configuration.

When an OCI image artefact with workshop content files, or a custom workshop
base image for the workshop are built and published to GitHub container
registry, the `image` and `files` references in the `Workshop` resource
definition will be rewritten to be the target locations when the `Workshop`
resource definition is attached as asset to the release.

Action Configuration
--------------------

Configuration parameters which can be set in the `with` clause for the this
GitHub action are as follows:

| Name                            | Required | Type     | Description                        |
|---------------------------------|----------|----------|------------------------------------|
| `files-reference-source`        | False    | String   | Source `files` reference in the `Workshop` resource file to replace with target reference. Defaults to "`imgpkg+http://registry.eduk8s.svc.cluster.local:5001/{name}-files:latest`". |
| `files-reference-target`        | False    | String   | Target reference to replace source `files` reference in the `Workshop` resource file. Defaults to "`imgpkg+https://{registry}/{name}-files:{tag}`". |
| `image-reference-source`        | False    | String   | Source `image` reference in the `Workshop` resource file to replace with target reference. Defaults to "`registry.eduk8s.svc.cluster.local:5001/{name}-image:latest`". |
| `image-reference-target`        | False    | String   | Target reference to replace source image reference in the `Workshop` resource file. Defaults to "`{registry}/{name}-image:{tag}`". |
| `path`                          | False    | String   | Relative directory path under `$GITHUB_WORKSPACE` to workshop files. Defaults to "`.`". |
| `token`                         | True     | String   | GitHub access token. Must be set to `${{secrets.GITHUB_TOKEN}}` or appropriate personal access token variable reference. |
| `training-portal-resource-file` | False    | String   | Relative path under workshop directory to the `TrainingPortal` resource file. Defaults to "`resources/training-portal.yaml`". |
| `workshop-image-docker-file`    | False    | String   | Path under workshop directory to the `Dockerfile` for custom workshop image. Defaults to "`Dockerfile`". |
| `workshop-resource-file`        | False    | String   | Relative path under workshop directory to the `Workshop` resource file. Defaults to "`resources/workshop.yaml`". |

 When overriding the source reference for `image` and `files`, the `{name}` variable reference can be used. When overriding the target reference for `image` and `files`, the `{registry}`, `{owner}`, `{name}`, `{tag}` and `{version}` variable references can be used. The meaning of these variables references are as follows:
 
 | Variable     | Description |
 |--------------|-------------|
 | `{name}`     | The name of the GitHub repository (forced to lowercase). |
 | `{owner}`    | The GitHub repository account owner (forced to lowercase). |
 | `{registry}` | The expansion of `ghcr.io/{owner}`. |
 | `{tag}`      | An image tag of the form `sha-{sha7}`, where `{sha7}` is the short hash of the Git commit the action is run against. |
 | `{version}` | The Git tag applied to the commit the action is run against which triggered the action. |

Files References
----------------

The location from which workshop content files are sourced when a workshop is
deployed under Educates is dictated by the `spec.content.files` property of the
`Workshop` resource definition. By default an OCI artefact is built and pushed
to GitHub container registry by this GitHub action and the `Workshop` definition is
rewritten when added as an asset to the release, to reference the OCI artefact
stored in GitHub container registry.

To override the target reference for the workshop content files to pull the
workshop content direct from the GitHub repository, use:

```
      - name: Create release
        uses: vmware-tanzu-labs/educates-github-actions/publish-workshop@v1
        with:
          token: ${{secrets.GITHUB_TOKEN}}
          files-reference-target: github.com/{owner}/{name}?ref={version}
```

To override the target reference for the workshop content files to pull the
workshop content direct from a web server, in this case for the GitHub download
server, use:

```
      - name: Create release
        uses: vmware-tanzu-labs/educates-github-actions/publish-workshop@v1
        with:
          token: ${{secrets.GITHUB_TOKEN}}
          files-reference-target: https://github.com/{owner}/{name}/archive/refs/tags/{version}.tar.gz
```
