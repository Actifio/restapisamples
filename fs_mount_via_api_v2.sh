#!/bin/bash

# Set -e to exit immediately if a command exits with a non-zero status.
set -e

# Set -x to display commands as they are executed. (Enable for debugging)
#set -x

# Define the usage function.
usage() {
  cat <<EOF
  echo "Usage: $0 <MS_URL> <appname> <targetmountpoint> <targethostname>"
   MS_URL: Management Console URL (e.g., https://bmc-xxxx-dot-asia-southeast1.backupdr.googleusercontent.com)
   appname           : The Filesystem appname you want to mount
   targetmountpoint  : Target mountpoint (e.g., /mnt/recovery)
   targethostname    : Target host where you want to recover the files (e.g., linuxfs01)
   e.g.### ./fs_mount_via_api.sh https://bmc-xxxx-dot-asia-southeast1.backupdr.googleusercontent.com <data> /mnt/recovery linuxfs01
EOF
  exit 1
  }

output_date()
{
  echo "Date: "$(date +"%m-%d-%Y %H:%M:%S")""
}

label="$(tr -dc 'a-z' < /dev/urandom | head -c 8; echo)"
label='apimount_'"$label"

TMPPATH=$PWD
remove_file()
{
  filename=$1
  if [[ -f $filename ]]; then
     rm -f $filename
  fi
}
# Assign arguments to variables with more descriptive names
 MS_URL="$1"
 APP_NAME="$2"
 TARGET_MOUNT_POINT="$3"
 TARGET_HOSTNAME="$4"

# Check if arguments are empty
if [[ -z "$MS_URL" ]]; then
  echo "Error: MS URL cannot be empty."
  echo ""
  usage
fi

if [[ -z "$APP_NAME" ]]; then
  echo "Error: App Name cannot be empty."
  echo ""
  usage
fi

if [[ -z "$TARGET_MOUNT_POINT" ]]; then
  echo "Error: Target Mount Point cannot be empty."
  echo ""
  usage
fi

if [[ -z "$TARGET_HOSTNAME" ]]; then
  echo "Error: Target Hostname cannot be empty."
  echo ""
  usage
fi


# Construct the BMC API URL
readonly BMC_API_URL="${MS_URL}/actifio"

echo "Starting mount process for ${APP_NAME} on ${TARGET_HOSTNAME} at ${TARGET_MOUNT_POINT}"

# --- Get Google Cloud Access Token ---
echo "Getting Google Cloud access token..."
ACCESS_TOKEN=$(gcloud auth print-access-token)
if [[ -z "${ACCESS_TOKEN}" ]]; then
  echo "Error: Failed to get Google Cloud access token. Please ensure you are logged in with gcloud."
  exit 1
fi
echo "Access token retrieved successfully."

# --- Get BackupDR Session ---
echo "Creating BackupDR session..."
SESSION_RESPONSE=$(curl -s -X POST -H "Authorization: Bearer ${ACCESS_TOKEN}" "${BMC_API_URL}/session")
if [[ $? -ne 0 ]] || [[ -z "${SESSION_RESPONSE}" ]]; then
    echo "Error: Failed to create BackupDR session."
    exit 1
fi
SESSION_ID=$(echo "${SESSION_RESPONSE}" | jq -r '.session_id')
if [[ -z "${SESSION_ID}" ]]; then
    echo "Error: Failed to extract session ID from the response: ${SESSION_RESPONSE}"
    exit 1
fi
echo "BackupDR session created successfully -> ${SESSION_ID}"

# --- Get Application ID ---
echo "Getting application ID for ${APP_NAME}..."
APP_ID=$(curl -s -X GET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/application?filter=appname:==${APP_NAME}" | jq -r '.items[0]?.id')
if [[ -z "${APP_ID}" ]]; then
    echo "Error: Failed to get application ID for ${APP_NAME}."
    echo "Response: $(curl -s -X GET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/application?filter=appname:==${APP_NAME}")"
    exit 1
fi
echo "Application ID retrieved successfully -> ${APP_ID}"

# --- Get Latest Backup Details ---
echo "Getting latest backup details for ${APP_ID}..."
BACKUP_DETAILS=$(curl -s -X GET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/backup?filter=appid:==${APP_ID}&jobclass=1&sort=consistencydate:desc&limit=1")
if [[ $? -ne 0 ]] || [[ -z "${BACKUP_DETAILS}" ]]; then
  echo "Error: Failed to get backup details."
  exit 1
fi
BACKUP_ID=$(echo "${BACKUP_DETAILS}" | jq -r '.items[0]?.id')
if [[ -z "${BACKUP_ID}" ]]; then
    echo "Error: Failed to extract backup ID from the response: ${BACKUP_DETAILS}"
    exit 1
fi
BACKUP_NAME=$(echo "${BACKUP_DETAILS}" | jq -r '.items[0]?.backupname')
if [[ -z "${BACKUP_NAME}" ]]; then
    echo "Error: Failed to extract backup name from the response: ${BACKUP_DETAILS}"
    exit 1
fi
APP_NAME=$(echo "${BACKUP_DETAILS}" | jq -r '.items[0]?.appname')
if [[ -z "${APP_NAME}" ]]; then
    echo "Error: Failed to extract app name from the response: ${BACKUP_DETAILS}"
    exit 1
fi

echo "Latest backup ID: ${BACKUP_ID}, backup name: ${BACKUP_NAME}, app name: ${APP_NAME}"

# --- Get Target Host ID ---
echo "Getting target host ID for ${TARGET_HOSTNAME}..."
TARGET_HOST_ID=$(curl -s -f -X GET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/host?filter=name:==${TARGET_HOSTNAME}" | jq -r '.items[0]?.id')
if [[ -z "${TARGET_HOST_ID}" ]]; then
  echo "Error: Failed to get target host ID for ${TARGET_HOSTNAME}."
  exit 1
fi
echo "Target host ID retrieved successfully -> ${TARGET_HOST_ID}"

# --- Get Source Cluster ID ---
echo "Getting source cluster ID for ${TARGET_HOSTNAME}..."
HOST_CLUSTER_ID=$(curl -s -f -X GET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/host?filter=name:==${TARGET_HOSTNAME}" | jq -r '.items[0]?.sourcecluster')
if [[ -z "${HOST_CLUSTER_ID}" ]]; then
  echo "Error: Failed to get host cluster ID for ${TARGET_HOSTNAME}."
  exit 1
fi
echo "Host cluster ID retrieved successfully -> ${HOST_CLUSTER_ID}"

# --- Perform Mount Operation ---
echo "Performing mount of ${APP_NAME} on ${TARGET_HOSTNAME} at ${TARGET_MOUNT_POINT}..."
MOUNT_RESPONSE=$(curl -s -f -X POST -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/backup/${BACKUP_ID}/mount" -d '{
  "restoreobjectmappings":[
    {
      "restoreobject": "'"${APP_NAME}"'"
    }
  ],
  "label": "'"${label}"'",
  "host": {
    "id": "'"${TARGET_HOST_ID}"'"
  },
  "restoreoptions" : [
    {
      "name": "mountpointperimage",
      "value": "'"${TARGET_MOUNT_POINT}"'"
    }
  ],
  "selectedobjects":  [
    {
      "restorableobject": "'"${APP_NAME}"'"
    }
  ],
  "hostclusterid": "'"${HOST_CLUSTER_ID}"'"
}')

if [[ $? -ne 0 ]] ; then
  echo "Error: Failed to perform mount operation."
  echo "Response: ${MOUNT_RESPONSE}"
  exit 1
fi

echo "Mount operation triggered successfully."

echo "=======  Monitoring the mount job ========"
sleep 10
jobs=$(curl -s -f -X GET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/jobstatus?filter=label:==$label&filter=jobclass:==mount")
#echo "outputofjobs"
#echo $jobs
output_date

########################## Get the Job ID #######################
count=0
echo "$jobs" > $TMPPATH/data_$label.json  # Save data to a file
jobid=$(jq -r '.items[0].id' $TMPPATH/data_$label.json)
echo "Jobid: $jobid"

while [[ -z "$jobid" ]] || [[ "$jobid" == "null" ]]; do
      sleep 20
      echo "Trying to get the job id"
      jobs=`curl -s -f -X GET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/jobstatus?filter=label:==$label&filter=jobclass:==mount"`
      if [[ -z "$jobs" ]]; then
      echo   generate_token
      fi
     echo "$jobs" > $TMPPATH/data_$label.json  # Save data to a file
     jobid=$(jq -r '.items[0].id' $TMPPATH/data_$label.json)
     count=$(($count+1))
     if [[ "$count" -eq 360 ]]; then
        echo "Unable to get the Job ID"
        remove_file $TMPPATH/data_$label.json
        remove_file $TMPPATH/test_$label.out
        exit 1
     fi
done
########################## Get the Job status #######################
status=`curl -s -f -X GET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/job/$jobid"`
sleep 2

output_date

echo "$status" > $TMPPATH/data_$label.json
jobstatus=$(jq -r '.status' $TMPPATH/data_$label.json)
while [[ "$jobstatus" == "running" ]]; do
   echo "====== Mount job $jobid is still running ====="
   sleep 20
   status=`curl -s -f -XGET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/job/$jobid"` 2>&1
   if [[ -z "$status" ]]; then
   echo "status not found"
   fi
   echo "$status" > $TMPPATH/data_$label.json
   jobstatus=$(jq -r '.status' $TMPPATH/data_$label.json)
   if [[ -z "$jobstatus" ]]; then
      sleep 20
      status=`curl -s -f -XGET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/job/$jobid"` 2>&1
      echo "$status" > $TMPPATH/data_$label.json
      jobstatus=$(jq -r '.status' $TMPPATH/data_$label.json)
   fi
done
output_date
sleep 10
count=0

###################################### Job Message ############################
jobmessage=$(jq -r '.message' $TMPPATH/data_$label.json)
while [[ "$jobmessage" == "null" ]] || [[ -z "$jobmessage" ]]; do
    sleep 20
    status=`curl -s -f -XGET -H "backupdr-management-session: Actifio ${SESSION_ID}" -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" "${BMC_API_URL}/job/$jobid"` 2>&1
    if [[ -z "$status" ]]; then
       echo "status not found"
    fi
    echo "$status" > $TMPPATH/data_$label.json
    jobmessage=$(jq -r '.message' $TMPPATH/data_$label.json)
    count=$(($count+1))
    if [[ "$count" -eq 360 ]]; then
       echo "Unable to get the Job ID"
       remove_file $TMPPATH/data_$label.json
       remove_file $TMPPATH/test_$label.out
       exit 1
    fi
done
output_date

if [[ "$jobstatus" == "succeeded" ]]; then
   echo "================ Mount completed successfully for the app:$appid==================="
else
   echo "Mount job failed with the error message :$jobmessage"
   #echo "Mount job failed for the application: $appid  with the error message :$jobmessage" | mail -s "Integrity Check Failed" xyz@abc.com
   remove_file $TMPPATH/data_$label.json
   remove_file $TMPPATH/test_$label.out
   remove_file $TOUCH_DIR/'.'"$appid"_mount.txt
   exit 1
fi
output_date
remove_file $TMPPATH/data_$label.json
remove_file $TMPPATH/test_$label.out
