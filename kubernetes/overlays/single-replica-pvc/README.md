# Single-Replica (PVC) Deployment

This overlay deploys a single-replica instance of the Apigee Drupal Kickstart application. It uses standard `ReadWriteOnce` PersistentVolumeClaims for storage, making it suitable for development and testing.

## Prerequisites

-   A running Kubernetes cluster.
-   `kubectl` installed and configured to communicate with your cluster.
-   A default `StorageClass` configured in your cluster that can dynamically provision `ReadWriteOnce` persistent volumes.

## Deployment Steps

1.  **Review and edit the secret files**:
    The `database.env` and `application.env` files are located in the `../../base` directory. Update the values in these files to match your environment.

2.  **Deploy the Application**:
    Apply the Kustomize configuration from this directory. This single command will create the namespace, the secrets, and all other application resources.
    ```sh
    kubectl apply -k .
    ```

## Next Steps

The application is now deploying. To verify the deployment, interact with the application, manage its configuration, or clean up the resources, please **[return to the main README.md file](../README.md)**.