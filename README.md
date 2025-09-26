# Apigee Dev Portal Kickstart Drupal + Docker

This repository provides a simple setup to run the [Apigee Drupal Kickstart](https://github.com/apigee/apigee-devportal-kickstart-drupal) in a Docker container.

This setup is intended for **local development purposes only** and is not recommended for a production environment. For production deployments, please refer to the [Kubernetes Deployment](#kubernetes-deployment) section and the official [Apigee documentation](https://cloud.google.com/apigee/docs/api-platform/publish/drupal/open-source-drupal) for installation, configuration, and hosting considerations.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Features](#features)
- [Docker Compose Usage](#docker-compose-usage)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Demo on Google Compute Engine](#demo-on-google-compute-engine)
- [Disclaimer](#disclaimer)

## Prerequisites

Before you begin, ensure you have the following installed:

- An [Apigee Organization](https://cloud.google.com/apigee/docs/api-platform/get-started/what-apigee)
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (for GCE demo)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (for Kubernetes deployment)
- [Kustomize](https://kustomize.io/) (for Kubernetes deployment)

## Features

- Apigee Kickstart profile installed
- Drupal REST UI installed
- REST endpoints configured for Apigee Entities

## Docker Compose Usage

This setup uses Docker Compose to run the Drupal portal and a MariaDB database in separate containers.

1.  **Configure your Apigee instance**:
    Update the details of your Apigee Edge instance in the `apigee.env` file. Adjust the values of any other variables as needed.

2.  **Choose a startup script**:

    -   `./start.sh`: This script will **build the Docker image** from the `Dockerfile` and then start the containers. It sets the `AUTO_INSTALL_PORTAL=true` environment variable, which will automatically install the Drupal site with the Apigee Kickstart profile. This is recommended for the first time you run the setup.

        ```bash
        # Build the image and run the containers with auto-install
        ./start.sh
        ```

    -   `./run.sh`: This script will use a **pre-built Docker image** from `ghcr.io/apigee/docker-apigee-drupal-kickstart` to start the containers. It sets `AUTO_INSTALL_PORTAL=false`, which means you will need to manually go through the Drupal installation wizard in your browser.

        ```bash
        # Run a pre-built image without auto-install
        ./run.sh
        ```

3.  **Access the portal**:
    Once the containers are running, navigate to `http://localhost:8080` in your web browser.

    If you used `./start.sh`, you will see a fully installed Apigee Portal with demo content. The default admin credentials are `admin@example.com` and `pass` (these can be changed in `apigee.env`).

    If you used `./run.sh`, you will be guided through the Drupal installation wizard.

## Kubernetes Deployment

For a more robust and scalable deployment, you can use the provided Kubernetes manifests to deploy the Apigee Drupal Kickstart application to a Kubernetes cluster.

The `kubernetes` directory contains all the necessary files and instructions. It uses [Kustomize](https://kustomize.io/) to manage different configuration variants.

-   **`kubernetes/base`**: Contains the common Kubernetes manifests.
-   **`kubernetes/overlays`**: Contains overlays for different deployment targets, such as a single-replica setup for development or a multi-replica setup for production on GCP with Cloud Filestore.

For detailed instructions on how to deploy to Kubernetes, please refer to the **[Kubernetes Deployment Guide](./kubernetes/README.md)**.

## Demo on Google Compute Engine

This section provides a quick guide to deploying the Apigee Drupal Kickstart on a Google Compute Engine (GCE) VM.

1.  **Set up environment variables**:
    ```bash
    export PROJECT_NAME=your-gcp-project-id
    export ZONE=us-central1-a
    export VM_NAME=apigee-portal-server
    export FIREWALL_NAME=apigee-portal-server-fw
    ```

2.  **Create a GCE VM instance and firewall rule**:
    ```bash
    gcloud compute instances create $VM_NAME \
        --project=$PROJECT_NAME \
        --zone=$ZONE \
        --machine-type=e2-medium \
        --network-interface=subnet=default \
        --image-family=cos-stable \
        --image-project=cos-cloud \
        --tags=drupal-server,http-server

    gcloud compute firewall-rules create $FIREWALL_NAME \
        --project=$PROJECT_NAME \
        --direction=INGRESS \
        --priority=1000 \
        --network=default \
        --action=ALLOW \
        --rules=tcp:80 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=drupal-server
    ```

3.  **SSH into the VM**:
    ```bash
    gcloud compute ssh $VM_NAME --zone=$ZONE --project=$PROJECT_NAME
    ```

4.  **Run the startup script**:
    On the GCE instance, run the following commands:
    ```bash
    wget https://raw.githubusercontent.com/apigee/docker-apigee-drupal-kickstart/main/container-assets/gce-startup.sh
    chmod +x gce-startup.sh
    ./gce-startup.sh
    ```

5.  **Access the installation wizard**:
    Find the external IP of your GCE instance:
    ```bash
    gcloud compute instances describe $VM_NAME \
        --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
        --zone=$ZONE --project=$PROJECT_NAME
    ```
    Navigate to `http://<EXTERNAL_IP>` in your browser and complete the Drupal installation.

6.  **Clean up**:
    ```bash
    gcloud compute firewall-rules delete $FIREWALL_NAME --project=$PROJECT_NAME --quiet
    gcloud compute instances delete $VM_NAME --project=$PROJECT_NAME --zone=$ZONE --quiet
    ```

## Disclaimer

This is not an official Google Product.