# Overview

Default deployment of OSS Nginx as a Docker container or in kubernetes does not offer great observability out of the box nor are there many OSS options to add even basic metrics monitoring. Prometheus & Grafana is one generic solution, however Nginxinc is offering a free SaaS service "Amplify".

Getting Amplify to work with a popular Bitnami nginx image & helm charts is not easy: Bitnami has instructions, but they are generic (not container image specific) and do not seem to be up-to-date.

This repo has a Dockerfile for a custom Bitnami image with Amplify that was developed through trial-n-error on getting the Amplify config right. It seems to be be working, but is not fully tested.

One major caveat in using Amplify in a container is that access log is not available anymore via Docker or kubectl logs command due to the requirements of Amplify.
