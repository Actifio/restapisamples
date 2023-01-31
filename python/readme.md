# Management Console Python Examples
This document describes how to configure REST API access to the Google Cloud Backup and DR Management Console using Python.  

## Prerequisites
To perform Google Cloud Backup and DR REST API operations, you need the following:

1. A Service Account (or accounts) with the correct roles needs to be selected or created in the relevant project  (that's the project that has access to the Management Console)
1. A host to run that service account, either:
    1. A Linux or Windows GCE Instance which has a service account attached that can get generate tokens and which has GCloud CLI and Python installed.
    1. A Linux, Mac or Windows host which has GCloud CLI installed and which has a downloaded JSON key for the relevant service account.  

## Getting Management Console details

Once you have deployed Backup and DR, then a management console will be configured.  You need to collect these two pieces of information from the Google Cloud Console.  Go to:  Backup and DR > Show API Credentials 

In this example (yours will be different!):

* API URL:  https://agm-123.backupdr.actifiogo.com/actifio
* OAuth 2.0 client ID:     456-abc.apps.googleusercontent.com


## Creating your Service Account

From Cloud Console IAM & Admin panel in the project where Backup and DR was activated, go to **Service Account** and choose **Create Service Account**.  You can also modify an existing one if desired.

Ensure it has **one** of the two following roles:

* ```Backup and DR User``` 
* ```Backup and DR Admin```

You then need to go to **IAM & Admin** > **Service Accounts**.  Find that service account, select it, go to **PERMISSIONS,** select **GRANT ACCESS**, enter the principal (email address) of the service account we will activate or attach with one of the following roles (you don't need both).  You can assign this to the same service account that was assigned the ```Backup and DR``` role:

* ```Service Account Token Creator```
* ```Service Account OpenID Connect Identity Token Creator```

> **Note**: We strongly recommend you do not assign either of these ```Token Creator``` roles to a service account at the project level.  Doing so will allow that account to _impersonate_ any other service account, which will allow that user to login as any user that has access to a **Backup and DR** role.

Decide where/how you will run your service account. You have two options:
1. Compute Engine Instance with attached service account

In option 1 we are going to use a Compute Engine instance to run our API commands/automation and because a Compute Engine Instance can have an attached Service Account, we can avoid the need to install a service key on that host.   The host needs the GCloud CLI installed (which is automatic if you use a Google image to create the instance).  

In your project create or select an instance that you want to use for API operations.   Ensure the service account that is attached to the instance has the permissions detailed above.  You can use an existing instance or create a new one.   If you need to change/set the Service Account, the instance needs to be powered off.

2. Activate your service account on a host

In option 2, we are going to use a Compute Engine instance or external host/VM to run our API commands/automation, but we are going to 'activate' the Service account using a JSON Key.   The host needs the **gcloud** CLI installed.

We need to activate our service account since we are not executing this command from a Compute Engine instance with an attached service account.
So firstly we need to download a JSON key from the Google Cloud Console and copy that key to our relevant host:

1. Go to **IAM & Admin** →  **Service Accounts**
1. Select your Service Account
1. Go to **Keys**
1. Select **Add Key** → **Create new key**
1. Leave key type as JSON and select **CREATE**
1. Copy the downloaded key to the relevant host

Note that some projects may restrict key creation or set time limits on their expiration. 

Now from the host where your service account key is eventually placed we need to activate it:
```
gcloud auth activate-service-account apiuser@avwservicelab1.iam.gserviceaccount.com --key-file=avwservicelab1-753d6ff386e3.json
gcloud config set account apiuser@avwservicelab1.iam.gserviceaccount.com 
gcloud config set project avwservicelab1
```
At this point we can proceed with the next step.


### Add the user before they login
To ensure the user has the correct role the first time it logs in, manually adding the user to the Management Console BEFORE the first login is recommended.    After you create the user in Google IAM,  login to your Management Console,  go to  Manage → Users and select Create User

Now enter the Service account email as the Username and select the relevant roles.   

You can now proceed to login having 'pre-added' user and assigned it a Management Console role.

### Configure the Python script

In each script there are two hard coded lines that need to be updated.  Note the format of the bmname does not have **https** at the start of **/actifio** at the end.

* bmcname = 'agm-1234.backupdr.actifiogo.com'
* oath2clientid = '1234-ABCDEF.apps.googleusercontent.com'



### Can I use one service account into two projects?

Let's say we have two projects, ProjectA and ProjectB:

1. You activate Google Cloud Back and DR in both projects.   
1. You create a service account api@saprojectA  in projectA and give it the roles/permissions needed to perform API operations in ProjectA
1. You can now add  api@saprojectA to project B and provided you give it the same role/permissions it can now do API operations in both ProjectA and ProjectB

The one thing you cannot do is run an instance in ProjectB as the SA from ProjectA using Option 2: Activate your service account on a host
