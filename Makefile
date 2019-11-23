#
#	You need to have an SSH key on the app
# 	TEST APP PORT 13644
# 	PRODUCTION APP PORT 13640
#

BASEDIR=$(shell pwd)
DESTINATIONMACHINE=node-13.rosti.cz
DESTINATIONPORT=13640
DESTINATIONDIR=/srv/app/
DESTINATIONUSER=app
NAME=rosti-docs
VERSION=0.1

.PHONY: all build upload clean

sync:
	pipenv --python /usr/bin/python3 sync

build: sync
	pipenv run mkdocs build

upload: build
	rsync -avz -e "ssh -p ${DESTINATIONPORT}" ${BASEDIR}/site/ ${DESTINATIONUSER}@${DESTINATIONMACHINE}:${DESTINATIONDIR}

clean:
	rm -rf ${BASEDIR}/site

all: build upload
