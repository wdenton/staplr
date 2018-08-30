all:

push:
	rsync --archive --delete --compress --itemize-changes --exclude staplr-branch-activity-01.json * wdenton:src/staplr/
