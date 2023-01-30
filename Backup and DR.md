# Management Console API Examples
This document describes how to configure REST API access to the Google Cloud Backup and DR Management Console.  This document will also provide guidance if you are converting from Actifio GO

## Prerequisites
To perform Google Cloud Backup and DR REST API operations, you need the following:

1. A Service Account (or accounts) with the correct roles needs to be selected or created in the relevant project  (that's the project that has access to the Management Console)
1. A host to run that service account, either:
    1. A Linux or Windows GCE Instance which has a service account attached that can get generate tokens and which has GCloud CLI and PowerShell installed.
    1. A Linux, Mac or Windows host which has GCloud CLI installed and which has a downloaded JSON key for the relevant service account.  

## Getting Management Console details

Once you have deployed Backup and DR, then a management console will be configured.   It is useful to know the project that your management console is peered to and the region where it was deployed.  Open the Show API Credentials twisty to learn the Management Console API URL and OAuth 2.0 client ID.  You will need these.

In this example (yours will be different!):

* Management Console URL:  https://agm-666993295923.backupdr.actifiogo.com/actifio
* OAuth 2.0 client ID:     486522031570-fimdb0rbeamc17l3akilvquok1dssn6t.apps.googleusercontent.com


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
gcloud auth activate-service-account powershell@avwservicelab1.iam.gserviceaccount.com --key-file=avwservicelab1-753d6ff386e3.json
gcloud config set account powershell@avwservicelab1.iam.gserviceaccount.com 
gcloud config set project avwservicelab1
```
At this point we can proceed with the next step.

### Management server details check 

We can confirm our management console details as follows:

Modify the following command to change your project and location and then use it to validate you have the correct details for your management console:
```
curl -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" https://backupdr.googleapis.com/v1/projects/avwservicelab1/locations/asia-southeast1/managementServers
```
Here is an example:
```
$ curl -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" https://backupdr.googleapis.com/v1/projects/avwservicelab1/locations/asia-southeast1/managementServers
{
  "managementServers": [
    {
      "name": "projects/avwservicelab1/locations/asia-southeast1/managementServers/agm-64111",
      "createTime": "2022-04-19T01:38:31.793435583Z",
      "updateTime": "2022-04-28T09:51:52.374135508Z",
      "state": "READY",
      "networks": [
        {
          "network": "projects/avwarglabhost/global/networks/arg-host-network",
          "peeringMode": "PRIVATE_SERVICE_ACCESS"
        }
      ],
      "managementUri": {
        "webUi": "https://agm-666993295923.backupdr.actifiogo.com",
        "api": "https://agm-666993295923.backupdr.actifiogo.com/actifio"
      },
      "type": "BACKUP_RESTORE",
      "oauth2ClientId": "486522031570-fimdb0rbeamc17l3akilvquok1dssn6t.apps.googleusercontent.com"
    }
  ]
}
```
### Add the user before they login
To ensure the user has the correct role the first time it logs in, manually adding the user to the Management Console BEFORE the first login is recommended.    After you create the user in Google IAM,  login to your Management Console,  go to  Manage → Users and select Create User

Now enter the Service account email as the Username and select the relevant roles.   

You can now proceed to login having 'pre-added' user and assigned it a Management Console role.

## Login process - API

### Login steps

1. Create a Token - has to be be done every time you login
1. Create a Session ID using the token - has to be be done every time you login

#### Step one - create a token

Modify this command to change the service account and the oauth2ClientId
```
curl -sS -XPOST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/powershell@avwservicelab1.iam.gserviceaccount.com:generateIdToken -d '{"audience":"486522031570-fimdb0rbeamc17l3akilvquok1dssn6t.apps.googleusercontent.com", "includeEmail":"true"}'
```
This command will create a token.  Place that token into a variable called $TOKEN
To use JQ to do this:
```
TOKEN=$(curl -sS -XPOST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/powershell@avwservicelab1.iam.gserviceaccount.com:generateIdToken -d '{"audience":"486522031570-fimdb0rbeamc17l3akilvquok1dssn6t.apps.googleusercontent.com", "includeEmail":"true"}' | jq -r '.token')
```

#### Step two - create a session ID

Now we have a $TOKEN we then create a session ID with the following command.  Again you need to modify this example to set your Management Console API endpoint.   Note it needs /session at the end. 
```
curl -sS -XPOST -H "Authorization: Bearer $TOKEN" -H "Content-Length: 0"  https://agm-666993295923.backupdr.actifiogo.com/actifio/session 
```
The first part of the output should contain a section like this.  The session_id is needed for all future commands.
```
   "@type" : "sessionRest",
   "id" : "4653d447-c8f3-4ac1-af65-2816363355e0",
   "href" : "https://agm-504992018861.backupdr.actifiogo.com/actifio/session/4653d447-c8f3-4ac1-af65-2816363355e0",
   "session_id" : "4653d447-c8f3-4ac1-af65-2816363355e0",
```
Place the session ID into a variable called $SESSIONID

Here is an example with JQ:
```
SESSIONID=$(curl -sS -XPOST -H "Authorization: Bearer $TOKEN" -H "Content-Length: 0"  https://agm-666993295923.backupdr.actifiogo.com/actifio/session | jq -r  '.id')
```
Now modify this command to validate your connection.  Change the API endpoint. It needs /config/version at the end.
```
curl -H "Authorization: Bearer $TOKEN" -H "backupdr-management-session: Actifio $SESSIONID" https://agm-666993295923.backupdr.actifiogo.com/actifio/config/version
```
Here is an example:
```
[avw@powershell ~]$ curl -H "Authorization: Bearer $TOKEN" -H "backupdr-management-session: Actifio $SESSIONID" https://agm-666993295923.backupdr.actifiogo.com/actifio/config/version
{
   "product" : "AGM",
   "summary" : "11.0.0.6831"
}[avw@powershell ~]$ 
```

## Converting Scripts From Actifio GO to Backup and DR

There are three considerations when converting from Actifio GO:

1. Is the automation using AGM API commands or Sky API commands or Sky SSH
1. Configuration of the host where the automation is running 
1. The user ID being used by the automation for authentication will need to change.

Let's look at each point:

### AGM API vs Sky API

Backup and DR only supports AGM API commands, sent to the Management Console.   If your automation is targeting a Sky Appliance using udsinfo and udstask commands sent either via ActPowerCLI (PowerShell), REST API command or an SSH session, then it cannot be used with Backup and DR and will need to be re-written.   If your automation is already using AGM API commands (or AGMPowerCLI), then very few changes will be needed.

### Automation Host Configuration

The automation host for Backup and DR API calls will need the gcloud CLI installed. Once installed the gcloud CLI will need access to a Google Cloud Service Account (with the correct roles), either through being executed on a GCE Instance running as that SA, or by using an activated JSON key for that service account.   The setup tasks for this typically only need to be done once, and are detailed in the sections above.

If using JSON keys, and the JSON keys expire, then a process to renew the keys will need to be established.

## FAQ
### I can connect but don't seem to stay connected

The issue is that your Management Console user has no role.   Go to the Management Console GUI and set the Users role.  Then create a new token and session. 

### Can I use this Service Account to login to the Management Console WEB GUI?

No you cannot.   A service account cannot be used to login to a Web Browser to authorize Console access

### Can I use one service account into two projects?

Let's say we have two projects, ProjectA and ProjectB:

1. You activate Google Cloud Back and DR in both projects.   
1. You create a service account api@saprojectA  in projectA and give it the roles/permissions needed to perform API operations in ProjectA
1. You can now add  api@saprojectA to project B and provided you give it the same role/permissions it can now do API operations in both ProjectA and ProjectB

The one thing you cannot do is run an instance in ProjectB as the SA from ProjectA using Option 2: Activate your service account on a host