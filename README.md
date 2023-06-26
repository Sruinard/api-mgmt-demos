# A full practical guide on how to use Azure API Management

## Repo objective
The objective of this repository is to serve as a practical guide on using API Management.
Although the main goal is API-management, we combine it with other tools to give a holistic experience of the Microsoft Platform (i.e. integrate with Github, Bicep Deployments, Monitoring, etc.)

## To get Started:
In order to use this repository, the following files need to be modified. So you probably want to fork or clone the repo.

#### Modify infra/*.bicep files:
* api-api.bicep: 
    * change:
        - apimgmt name
        - api properties.value
        - graphql_api_name

* api-apps.bicep:
    * change: 
        - appserviceplan name
        - app name

* api-mgmt.bicep:
   * change:
        apimgmt name 


#### Modify .github/workflows/*.yml files:
* main.yml:
   * change:
       - env: AZURE_WEBAPP_NAME

If you have forked this repository, you can add your Azure credentials to the repo.
To obtain your credentials, run the following command:

```$az ad sp create-for-rbac --name <INSERT_SP_NAME (e.g. apim-poc-team)> --role contributor --scopes /subscriptions/<INSERT_SUBSCRIPTION_ID> --sdk-auth```

Make sure to copy the entire json and add it as a repository secret with a name of AZURE_CREDENTIALS.


update apim backend in:
[apps/distributed_tracing/webshop/templates/form.html](apps/distributed_tracing/webshop/templates/form.html)

## That's all!
You are now ready to deploy. Run: ```$/bin/bash ./infra/infra-deploy.azcli``` or push your code and see github actions kick in.
