Publish Workshop
================

This GitHub action supports the following for an Educates workshop:

* Creating an OCI image artefact containing workshop content files and pushing
  it to the GitHub container registry.
* Creating a release against the GitHub repository and attach as assets
  Kubernetes resource files for deploying the workshop to Educates.

Note that this GitHub action can only publish a single workshop and will only
publish an OCI image artefact containing the workshop files. Prior versions of
this GitHub action could publish multiple workshops and also build custom
workshop images. Neither of those capabilities are now supported by this GitHub
action.

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
        uses: vmware-tanzu-labs/educates-github-actions/publish-workshop@v6
        with:
          token: ${{secrets.GITHUB_TOKEN}}
```

Note that version `v6` of this GitHub action produces an exported workshop
definition which requires Educates 2.6.0 or later.

Workshop Definition
-------------------

This GitHub action makes use of the `educates publish-workshop` command. As
such, the workshop definition must include a `spec.publish` section which
defines where the image is to be published:

```
apiVersion: training.educates.dev/v1beta1
kind: Workshop
metadata:
  name: {name}
spec:
  publish:
    image: $(image_repository)/{name}-files:$(workshop_version)
```

The workshop definition may optionally specify what files should be included in
the OCI image artefact for the workshop.

```
apiVersion: training.educates.dev/v1beta1
kind: Workshop
metadata:
  name: {name}
spec:
  publish:
    image: $(image_repository)/{name}-files:$(workshop_version)
    files:
    - directory:
        path: .
      includePaths:
      - /workshop/**
      - /templates/**
      - /README.md
```

See the Educates documentation for more information.

Action Configuration
--------------------

Configuration parameters which can be set in the `with` clause for the this
GitHub action are as follows:

| Name                            | Required | Type     | Description                        |
|---------------------------------|----------|----------|------------------------------------|
| `path`                          | False    | String   | Relative directory path under `$GITHUB_WORKSPACE` to workshop files. Defaults to "`.`". |
| `token`                         | True     | String   | GitHub access token. Must be set to `${{secrets.GITHUB_TOKEN}}` or appropriate personal access token variable reference. |
| `trainingportal-resource-file`  | False    | String   | Relative path under workshop directory to the `TrainingPortal` resource file. Defaults to "`resources/trainingportal.yaml`". |
| `workshop-resource-file`        | False    | String   | Relative path under workshop directory to the `Workshop` resource file. Defaults to "`resources/workshop.yaml`". |
