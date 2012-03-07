# Example bash script that could be used to rsync a local folder to a remote folder via ssh

localFolder=/[FOLDER_TO_SYNC]
remoteDest=/[REMOTE_FOLDER_TO_SYNC]
remoteUsername=[USERNAME]
remoteAddress=10.10.10.10

rsync -avze ssh --delete ${localFolder} ${remoteUsername}@${remoteAddress}:${remoteDest}
