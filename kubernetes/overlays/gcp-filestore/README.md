# GCP Filestore (Scalable) Deployment

This overlay deploys a scalable, multi-replica instance of the Apigee Drupal Kickstart application using a managed **Google Cloud Filestore** instance for shared storage (`ReadWriteMany`).

This is the recommended approach for production environments on Google Kubernetes Engine (GKE), including GKE Autopilot clusters.

## Step 1: Create a Google Cloud Filestore Instance

First, you need to provision a Filestore instance.

**Note:** Ensure the Filestore instance is created in the **same VPC network** as your GKE cluster.

1.  **Set environment variables (optional, for convenience)**:
    ```sh
    export FILESTORE_INSTANCE_ID=apigee-portal-filestore
    export FILESTORE_ZONE=us-central1-c
    export FILESHARE_NAME=drupal_files
    ```

2.  **Create the Filestore instance**:
    ```sh
    gcloud filestore instances create $FILESTORE_INSTANCE_ID \
      --project=$(gcloud config get-value project) \
      --zone=$FILESTORE_ZONE \
      --tier=BASIC_HDD \
      --file-share=name="$FILESHARE_NAME",capacity=1TB \
      --network=name="default"
    ```
    This operation can take several minutes to complete.

3.  **Get the Filestore instance's IP address**:
    ```sh
    export FILESTORE_IP=$(gcloud filestore instances describe $FILESTORE_INSTANCE_ID \
      --zone=$FILESTORE_ZONE \
      --format="get(networks[0].ipAddresses[0])")
    echo "Filestore IP: $FILESTORE_IP"
    echo "Fileshare Name: $FILESHARE_NAME"
    ```

## Step 2: Configure the Deployment Patch

Edit the `deployment-patch.yaml` file in this directory to point to the Filestore instance you just created.

## Step 3: Review Secrets

The secrets for this deployment are generated from the `database.env` and `application.env` files located in the `../../base` directory. Review those files and ensure their contents are correct for your environment.

## Step 4: Deploy the Application

Apply the Kustomize configuration from this directory. This single command will create the namespace, the secrets, and all other application resources.
```sh
kubectl apply -k .
```

## Step 5: Cleanup

After you have removed the Kubernetes resources by following the main `README.md`'s cleanup guide, you must also delete the Google Cloud Filestore instance to avoid incurring further costs.

1.  **Delete the Filestore instance**:
    ```sh
    gcloud filestore instances delete $FILESTORE_INSTANCE_ID \
      --zone=$FILESTORE_ZONE
    ```
    *(Note: Ensure you have the correct `FILESTORE_INSTANCE_ID` and `FILESTORE_ZONE` environment variables set or replace them with the actual values.)*

## Next Steps

The application is now deploying. To verify the deployment, interact with the application, manage its configuration, or clean up the Kubernetes resources, please **[return to the main README.md file](../README.md)**.
