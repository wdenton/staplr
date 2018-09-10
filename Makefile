all:

push:
	rsync --archive --links --delete --compress --itemize-changes --exclude staplr-branch-activity-01.json * wdenton:src/staplr/
