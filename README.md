Apigee Dev Portal Kickstart Drupal + Docker
---

Using the `quick-start` command is great on your local machine, but doesn't play nice in a Docker container.

Here is simple setup that lets you run the Apigee Drupal Kickstarter in a Docker container. This image is for local development purposes. This is not intended for a production setup. Please refer to the [Documentation](https://docs.apigee.com/api-platform/publish/drupal/open-source-drupal-8) for installation, configuration and production hosting considerations.

This setup uses Maria DB and creates a volume to store uploaded files.

See [here](https://github.com/apigee/apigee-devportal-kickstart-drupal) for the Drupal Installation Profile that this image is based on.

## Prerequisites

- Apigee Organization
- `docker` and `docker-compose` installed

## Features
- Apigee Kickstart profile installed
- Drupal REST UI installed
- REST endpoints configure for Apigee Entities

## Usage
Update the details of your Edge instance in the apigee.env file
Adjust values of any other variables that are relevant.

Run the below command to run start the container:
```
# build and run the container
./start.sh

# run a pre-built image (ghcr.io/apigee/docker-apigee-drupal-kickstart)
./run.sh
```

If you want to rebuild the docker image run the below command:
```
docker compose up --build
```

Navigate to `localhost:8080` and you will see an Apigee Portal installed with demo content.

Default admin credentials for the portal are: `admin@example.com` and `pass`, but you can change these in `apigee.env`.

## Demo Apigee Kickstart on Google Compute instance with docker image
1. Setup variables
   ```
    export PROJECT_NAME=gcp-project-1
    export ZONE=us-central1-a
    export VM_NAME=apigee-portal-server
    export FIREWALL_NAME=apigee-portal-server-fw
   ```
2. Create a GCE VM instance with `container-optimized-os` image and create a firewall rule to allow HTTP traffic to this VM.
	```
    gcloud compute instances create $VM_NAME \
        --project=$PROJECT_NAME \
        --zone=$ZONE \
        --machine-type=e2-medium \
        --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
        --no-restart-on-failure \
        --maintenance-policy=TERMINATE \
        --provisioning-model=SPOT \
        --instance-termination-action=STOP \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --tags=drupal-server,http-server \
        --create-disk=auto-delete=yes,boot=yes,device-name=$VM_NAME,image=projects/cos-cloud/global/images/family/cos-stable,mode=rw,size=10,type=projects/$PROJECT_NAME/zones/$ZONE/diskTypes/pd-balanced \
        --no-shielded-secure-boot \
        --shielded-vtpm \
        --shielded-integrity-monitoring \
        --labels=goog-ec-src=vm_add-gcloud \
        --reservation-affinity=any
    
    gcloud compute --project=$PROJECT_NAME firewall-rules create $FIREWALL_NAME --direction=INGRESS \
        --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 \
        --target-tags=drupal-server

	```

3. SSH into the VM and run commands in next step
  ```
    gcloud compute ssh  $VM_NAME --zone=$ZONE --project=$PROJECT_NAME
  ```

4. Login into the GCE instance and run the following commands 
  ```
    wget https://gist.githubusercontent.com/giteshk/35875a36decd24c61a9d0fb5c6afad42/raw/6c0ec1d4dc1c0d16e42d971404509f53628ec4da/startup.sh
    chmod +x startup.sh
    bash ./startup.sh
  ```

5. Run through the Drupal installation wizard @ http://GCE-INSTANCE-EXTERNAL-IP
  External IP can be located using :
  ```
    gcloud compute instances describe $VM_NAME \
      --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
      --zone=$ZONE --project=$PROJECT_NAME
  ```

6.  Clean up commands:
  ```
    gcloud compute --project=$PROJECT_NAME firewall-rules delete $FIREWALL_NAME --quiet
    gcloud compute instances delete $VM_NAME --project=$PROJECT_NAME  --zone=$ZONE --quiet
  ```


## Disclaimer

This is not an official Google Product.
