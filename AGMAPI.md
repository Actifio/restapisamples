# Goal

To show some REST API examples for the AGM API.   All examples are working examples, tested and confirmed.

### Table of Contents
**[JQ JSON Parser](#jq-json-parser)**<br>
**[Using variables](#using-variables)**<br>
**[Fetching a Session ID](#fetching-a-session-id)**<br>
**[Managing Mounts](#managing-mounts)**<br>

## JQ JSON Parser
All examples use the JQ parser.
The JQ JSON parser is portable and easy to use and can parse JSON very nicely.  
It is open source and free to use. 
Because some commands use a number of characters that cannot normally be used in HTTPS URLs, you have the choice of using quoting and special handling or URL encoding.

All examples in this article do NOT use URL encoding.

## Using variables

All examples will use variables with curl.   This means the IP address is always shown as **$agmip**.   
```
agmip=10.186.0.2
agmuser=admin
agmpass=password

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



## Fetching a Session ID

We create a session ID with this command:

```
curl -w "\n" -sS -k -XPOST --user $agmuser:$agmpass --tlsv1.2 -k https://$agmip/actifio/session
```
This returns all the information for the session, but the thing we really want is the ID field as that gives us the session ID.   We can use this command to store it as a variable:
```
agmsessionid=$(curl -w "\n" -sS -k -XPOST --user $agmuser:$agmpass --tlsv1.2 -k https://$agmip/actifio/session | jq -r '.id')
```
In this exammple we login and validate the session ID is set:
```
$ agmsessionid=$(curl -w "\n" -sS -k -XPOST --user $agmuser:$agmpass --tlsv1.2 -k https://$agmip/actifio/session | jq -r '.id')
$ echo $agmsessionid
61eaf9e3-eca3-487b-a62a-9d7d2931a84d
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

