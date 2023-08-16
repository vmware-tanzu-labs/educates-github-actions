Educates GitHub Actions
=======================

This repository contains a collection of GitHub actions supporting development
and use of Educates, including user created workshop content for Educates.

The GitHub actions included here are:

* [Publish Workshop](publish-workshop/README.md) - Publishes a workshop to
  GitHub container registry and creates a release with Kubernetes resource
  definitions for deploying the workshop as assets.

Note that versioning applies to the collection as a whole. This means that if a
breaking change is made to a single action, then the version is incremented on
all actions, even though changes may not have been made to the other actions.
