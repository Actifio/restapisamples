# Goal

To show some REST API examples for the AGM API.   All examples are working examples, tested and confirmed.

### Table of Contents
**[JQ JSON Parser](#jq-json-parser)**<br>
**[Using variables](#using-variables)**<br>
**[Creating a Session ID](#creating-a-session-id)**<br>
**[Fetching AGM Version](#fetching-agm-version)**<br>
**[Fetching Session Details](#fetching-session-details)**<br>
**[Managing Mounts](#managing-mounts)**<br>
**[Creating an on demand backup](#creating-an-on-demand-backup)**<br>

## JQ JSON Parser
All examples use the JQ parser.
The JQ JSON parser is portable and easy to use and can parse JSON very nicely.  
It is open source and free to use. 
Because some commands use a number of characters that cannot normally be used in HTTPS URLs, you have the choice of using quoting and special handling or URL encoding.

All examples in this article do NOT use URL encoding.

## Using variables

All examples will use variables with curl.   This means the IP address is always shown as **$agmip**.   
```
agmip=10.10.0.3
agmuser=apiuser   
agmpass=Secret1

```
### What Curl options are used in these examples?
If using Curl we use the following
Option  Purpose
* -s  : Silent Mode. This stops download progress messages appearing on the screen.
* -S  : Print errors that might be stopped by -s
* -w "\n" :   Print a new line at the end of the output
* -k : Work with self signed certificates
* -G  : Send the -d data with a HTTP GET
* -d  :  Used for additional data that we separate out due to encoding requirements



## Creating a Session ID

We create a session ID with this command:

```
curl -w "\n" -sS -k -XPOST --user $agmuser:$agmpass --tlsv1.2 -k https://$agmip/actifio/session
```
This returns all the information for the session, but the thing we really want is the ID field as that gives us the session ID.   We can use this command to store it as a variable:
```
agmsessionid=$(curl -w "\n" -sS -k -XPOST --user $agmuser:$agmpass --tlsv1.2 -k https://$agmip/actifio/session | jq -r '.id')
```
In this example we login and validate the session ID is set:
```
$ agmsessionid=$(curl -w "\n" -sS -k -XPOST --user $agmuser:$agmpass --tlsv1.2 -k https://$agmip/actifio/session | jq -r '.id')
$ echo $agmsessionid
61eaf9e3-eca3-487b-a62a-9d7d2931a84d
```

### Using base64 encoding to avoid storing passwords in the clear

We can use base 64 encoding to create an encoded sets of credentials.   The syntax looks like this:
```
echo -n 'admin:password' | base64               
```
Here is an example:
```
$ echo -n 'admin:password' | base64
YWRtaW46cGFzc3dvcmQ=
```
Note you can reverse the encoding just as easily, which means this method does not make the encoded authorization details truly secret:
```
echo -n 'YWRtaW46cGFzc3dvcmQ=' | base64 -d      
```
Here is an example:
```
$ echo -n 'YWRtaW46cGFzc3dvcmQ=' | base64 -d
admin:passwordavw-macbookpro:~ avw$
```
We can use commands like this to send the encoded package:
```
encodedcredentials=$(echo -n 'admin:password' | base64)
agmsessionid=$(curl -w "\n" -sS -k -XPOST -k https://$agmip/actifio/session -H "Authorization: Basic $encodedcredentials" | jq -r '.id')
```
### Removing the session

Once you have finished running commands, it is better to remove the session, rather than leave it to time out.   You use this command:
```
curl -s -k -XDELETE https://$agmip/actifio/session/$agmsessionid
```
Here is an example where we login, confirm we can issue a command, logout and confirm the session ID is gone:
```
$ agmsessionid=$(curl -w "\n" -sS -k -XPOST --user $agmuser:$agmpass --tlsv1.2 -k https://$agmip/actifio/session | jq -r '.id')
$ echo $agmsessionid
2d8b8db9-3734-4b03-b94f-b71ba63fd9bd
$ curl -sS -X GET -H "Authorization: Actifio $agmsessionid" -k https://$agmip/actifio/config/versiondetail
{
   "product" : "AGM",
   "components" : [ {
      "component" : "AGM",
      "summary" : "10.0.2.5357",
      "installed" : 1622614922581
   } ],
   "summary" : "10.0.2.5357",
   "installed" : 1622614922581
}
$ curl -s -k -XDELETE https://$agmip/actifio/session/$agmsessionid
$ curl -sS -X GET -k https://$agmip/actifio/session/$agmsessionid
{
   "err_code" : 10040,
   "err_message" : "session id is not found"
}
$
```

## Fetching AGM Version

This is the command to get the AGM Version.  It is a useful command to confirm AGM is responding correctly:
```
curl -sS -X GET -H "Authorization: Actifio $agmsessionid" -k https://$agmip/actifio/config/versiondetail
```
Here is an example:

```
$ curl -sS -X GET -H "Authorization: Actifio $agmsessionid" -k https://$agmip/actifio/config/versiondetail
{
   "product" : "AGM",
   "components" : [ {
      "component" : "AGM",
      "summary" : "10.0.2.5357",
      "installed" : 1622614922581
   } ],
   "summary" : "10.0.2.5357",
   "installed" : 1622614922581
```
## Fetching Session Details

When you login to create a session, you get the Session ID details.    You can fetch these again using any of these commands:
```
curl -sS -X GET -k https://$agmip/actifio/session/$agmsessionid
curl -sS -X GET -H "Authorization: Actifio $agmsessionid" -k https://$agmip/actifio/session/current
curl -sS -X GET -H "Authorization: Actifio $agmsessionid" -k https://$agmip/actifio/session/$agmsessionid
```

## Managing Mounts

### Fetching details about mounts

If we want to get the details of our mounts we can use a command like this:
```
curl -sS -X GET -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid" -k "https://$agmip/actifio/backup?filter=jobclass:==mount" | jq -cr '.items[] | [.id, .backupname,  .appname]'
```

This tells us the backup ID being used by AGM.  Note that this is a different ID than the VDP appliance will be using, but the backup name will be the same:
```
$ curl -sS -X GET -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid" -k "https://$agmip/actifio/backup?filter=jobclass:==mount" | jq -cr '.items[] | [.id, .backupname,  .appname]'
["85082","Image_0110695","mysqld_3306"]
```

### Fetching Container mount YAML

We need to run this command against the backup ID.  In this example it is 85082 (yours will be different):
```
curl -sS -X GET -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid" -k https://$agmip/actifio/backup/85082
```
We can use JQ to just get the YAML:
```
curl -sS -X GET -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid" -k https://$agmip/actifio/backup/85082 | jq -r '.yaml'
```
Here is an example:
```
$ curl -sS -X GET -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid" -k https://$agmip/actifio/backup/85082 | jq -r '.yaml'

    #Copy and paste the following volumeMounts declaration within your container definition
    #Copy and paste the following volumes definition below your container definition
    containers:
      volumeMounts:
      - name: actifio-mysqld-3306-dev-vgdata-mysqldata
        mountPath: /actifio_mnt/dev/vgdata/mysqldata
      - name: actifio-mysqld-3306-logs
        mountPath: /actifio_mnt/70541_TransactionLog
    volumes:
    - name: actifio-mysqld-3306-dev-vgdata-mysqldata
      nfs:
        server: 10.152.0.12
        path: /tmp/cmounts/actdevvgdatamysqldata_1623111761279_act_staging_vol_Job_0110695
    - name: actifio-mysqld-3306-logs
      nfs:
        server: 10.152.0.12
        path: /tmp/cmounts/act70541_TransactionLog_1623111763606_act_staging_vol_Job_0110695

$
```

## Creating an on demand backup

If we want to create an on-demand backup, we need to learn:

* The Application ID for the application the job will run against
* The policy ID for the backup in question

### Learning the application ID

We can query the application end point like this, but this will return a lot of data
```
curl -sS -X GET -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid" -k "https://$agmip/actifio/application"
```
We can make the output easier to read by doing this to display only applications that managed (creating backups):
```
curl -sS -X GET -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid" -k "https://$agmip/actifio/application?filter=managed:==true" | jq -cr '.items[] | [.id,  .appname, .apptype]'
```
Here is an example output:
```
["8766","bastion","GCPInstance"]
```
We now have the application ID for our application (in this example 8766).

### Learning the policy ID

This is done in two parts.   First we need to learn the template (SLT) ID.  So use your application ID like this:
```
appid=8766
curl -sS -X GET -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid" -k "https://$agmip/actifio/sla?filter=appid:==$appid" | jq -cr '.items[] | [.slt]'
```
Example output:
```
[{"id":"6717","href":"https://10.10.0.3/actifio/slt/6717","name":"snap","override":"true","sourcename":"snap"}]
```
Now we have the SLT ID, which in this example is 6717.

Now we learn the policy IDs in that template.
```
sltid=6717
curl -sS -X GET -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid" -k "https://$agmip/actifio/slt/$sltid/policy" | jq -cr '.items[] | [.id, .name, .op]'
```
Here is an example of the output, where the ID of our policy in this example is 6718.
```
["6718","snap","snap"]
```
### Run the on demand backup

Now we have the appid and policy ID we can run the backup job.

```
appid=8766
policyid=6718
curl -w "\n" -sS -k -XPOST -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid"  "https://$agmip/actifio/application/$appid/backup" -d "{\"policy\":{\"id\":$policyid}}"
```
If this is a database application you need to also specify a backuptype of **log** or **DB** so the JSON data block would look like this:
```
appid=8766
policyid=6718
backuptype="log"
curl -w "\n" -sS -k -XPOST -H "Content-type: application/json" -H "Authorization: Actifio $agmsessionid"  "https://$agmip/actifio/application/$appid/backup" -d "{\"policy\":{\"id\":$policyid},\"backuptype\":\"$backuptype\"}"
```
