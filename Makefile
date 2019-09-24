all:

current:
	cd compositions && rm -f current.spi && ln -s ${CURRENT} current.spi

push:
	rsync --archive --links --delete --compress --itemize-changes --exclude data/live/activity.json * wdenton2:src/staplr/
