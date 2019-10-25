Apigee Dev Portal Kickstart Drupal + Docker
---

Using the `quick-start` command is great on your local machine, but doesn't play nice in a Docker container.

Here is simple setup that lets you run the Apigee Drupal Kickstarter in a Docker container. This image is for local development purposes. This is not intended for a production setup. Please refer to the [Documentation](https://docs.apigee.com/api-platform/publish/drupal/open-source-drupal-8) for installation, configuration and production hosting considerations.

See [here](https://github.com/apigee/apigee-devportal-kickstart-drupal) for the Drupal Installation Profile that this image is based on.

## Features
- Apigee Kickstart profile installed
- Drupal REST UI installed
- REST endpoints configure for Apigee Entities

## Usage

``` bash
export APIGEE_ORG=xxx
export APIGEE_USER=xxx
export APIGEE_PASS=xxx

#optionally if you are Private Cloud
export APIGEE_MGMT=(management server url)

# build and run the container
./start.sh
```

Navigate to `localhost:8080` and you will see an Apigee Portal installed with demo content.

Default admin credentials for the portal are: `admin@example.com` and `pass`, but you can change these in `start.sh`.

## Disclaimer

This is not an official Google Product.
