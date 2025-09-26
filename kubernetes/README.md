# Kubernetes Configuration for Apigee Drupal Kickstart

This directory contains the Kubernetes manifests to deploy the Apigee Drupal Kickstart application. It is structured to use [Kustomize](https://kustomize.io/) for managing different configuration variants.

## Directory Structure

-   `base/`: Contains the common Kubernetes manifests shared across all deployment variations.
-   `overlays/`: Contains Kustomize overlays for different deployment targets.
    -   `single-replica-pvc/`: A single-replica deployment using standard `ReadWriteOnce` PersistentVolumeClaims. Suitable for development and testing.
    -   `gcp-filestore/`: A scalable, multi-replica deployment using Google Cloud Filestore for shared `ReadWriteMany` storage. Recommended for production on GCP.

---

## 1. Deployment

First, choose a deployment overlay based on your needs. Follow the specific instructions in the overlay's README to deploy the application.

-   **[Single-Replica (Default) Deployment Guide](./overlays/single-replica-pvc/README.md)**
-   **[GCP Filestore (Scalable) Deployment Guide](./overlays/gcp-filestore/README.md)**

---

## 2. Post-Deployment Instructions

After you have successfully deployed the application using one of the guides above, use the following instructions to verify, interact with, and manage your deployment.

### Verifying the Deployment

1.  **Check the pods**:
    ```sh
    kubectl get pods -w -n apigee-devportal
    ```
    Wait for all pods (`apigee-kickstart-*` and `apigee-kickstart-database-*`) to be in the `Running` state.

2.  **Check the services**:
    ```sh
    kubectl get services -n apigee-devportal
    ```
    Look for the `apigee-kickstart` service. It will have an `EXTERNAL-IP` assigned once your cloud provider has provisioned the load balancer.

    ```
    NAME                          TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
    apigee-kickstart              LoadBalancer   10.96.1.234     35.222.111.222  80:31234/TCP   5m
    apigee-kickstart-database     ClusterIP      10.96.2.111     <none>          3306/TCP       5m
    ```

3.  **Access the Application**:
    Once the `EXTERNAL-IP` is available, you can access the Drupal portal by navigating to `http://<EXTERNAL-IP>` in your web browser.

    *Troubleshooting Note*: If you encounter an error after the initial browser-based installation, try navigating to `http://<EXTERNAL-IP>/update.php` or running `drush cr` (see "Interacting with the Application" below) to clear caches.

### Interacting with the Application

To run `drush` commands or access the container's shell for debugging, you can connect to a running `apigee-kickstart` pod:

1.  **Get the name of a running `apigee-kickstart` pod**:
    ```sh
    POD_NAME=$(kubectl get pod -l app=apigee-kickstart -n apigee-devportal -o jsonpath='{.items[0].metadata.name}')
    echo $POD_NAME
    ```

2.  **Execute a `drush` command (example: check status)**:
    ```sh
    kubectl exec -it $POD_NAME -n apigee-devportal -c apigee-kickstart -- drush status
    ```

3.  **Clear Drupal caches**:
    ```sh
    kubectl exec -it $POD_NAME -n apigee-devportal -c apigee-kickstart -- drush cr
    ```

4.  **Run database updates**:
    ```sh
    kubectl exec -it $POD_NAME -n apigee-devportal -c apigee-kickstart -- drush updb -y
    ```

5.  **Get a shell into the container**:
    ```sh
    kubectl exec -it $POD_NAME -n apigee-devportal -c apigee-kickstart -- /bin/sh
    ```

### Configuration

All sensitive configuration is managed in the `database.env` and `application.env` files located in the `base/` directory.

To change a configuration value:

1.  Update the desired value in the appropriate `.env` file in the `base/` directory.
2.  Re-apply your chosen overlay. Kustomize will automatically update the Secrets with the new values.
    ```sh
    # From within the overlay directory you used (e.g., overlays/single-replica-pvc)
    kubectl apply -k .
    ```
3.  Perform a rolling restart of the application pods to ensure they pick up the new secret values:
    ```sh
    kubectl rollout restart deployment/apigee-kickstart -n apigee-devportal
    ```

---

## 3. Production Considerations

### Using a Managed Database (e.g., Google Cloud SQL)

The default configuration deploys an in-cluster MariaDB database, which is convenient for development and testing. For a production environment, it is highly recommended to use a managed, external database service like **Google Cloud SQL for MySQL** for better reliability, automated backups, and maintenance.

To use a managed database:

1.  **Provision your managed database instance** (e.g., a Cloud SQL for MySQL instance). Ensure it is accessible from your GKE cluster's VPC network.

2.  **Update the secret files** in the `base/` directory with your managed database's connection details:
    -   In `database.env`, update `MYSQL_USER` and `MYSQL_PASSWORD` (and others if needed).
    -   In `application.env`, update `DRUPAL_DATABASE_USER`, `DRUPAL_DATABASE_PASSWORD`, and most importantly, `DRUPAL_DATABASE_HOST` to point to your managed database's IP address or service endpoint.

3.  **Disable the in-cluster database deployment**. In `base/kustomization.yaml`, comment out the resources related to the MariaDB deployment:
    ```yaml
    # base/kustomization.yaml

    resources:
    - namespace.yml
    # - apigee-kickstart-database-deployment.yml
    # - apigee-kickstart-database-pvc.yml
    # - apigee-kickstart-database-service.yml
    - apigee-kickstart-service.yml
    - apigee-kickstart-deployment.yml
    ```

4.  **Deploy the application** by running `kubectl apply -k .` from your chosen overlay directory. The application will now connect to your external, managed database.

### Using Managed Shared Storage (e.g., Google Cloud Filestore)

For a scalable, multi-replica production setup, you need a storage solution that supports `ReadWriteMany` access mode, allowing multiple application pods to read and write to the same file system simultaneously.

The `overlays/gcp-filestore` directory provides a production-ready example for this requirement, using Google Cloud Filestore as a managed NFS provider. This is the recommended approach for any multi-replica deployment on GCP.

## 4. Cleanup

To remove all Kubernetes resources created by your deployment:

1.  **Delete all resources from the overlay you deployed**:
    ```sh
    # From within the overlay directory you used (e.g., overlays/single-replica-pvc)
    kubectl delete -k .
    ```

2.  **Delete the namespace**:
    ```sh
    kubectl delete namespace apigee-devportal
    ```
    *(Note: If you deployed the GCP Filestore overlay, remember to follow the additional cleanup steps in its README to delete the Filestore instance.)*