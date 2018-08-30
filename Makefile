all:

push:
	rsync --archive --compress --itemize-changes * wdenton:staplr/
