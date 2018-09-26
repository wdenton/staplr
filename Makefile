all:

current:
	cd compositions && rm -f current.spi && ln -s ${CURRENT} current.spi

push:
	rsync --archive --links --delete --compress --itemize-changes --exclude staplr-branch-activity-01.json * wdenton:src/staplr/
