#!/bin/sh
LAB="lab"
LAB_VERSION="$1"


if [ $# -ne 1 ]
then
    echo "Usage: $0 [lab version 0 ~ 7]"
    exit 0
fi

LAB="$LAB$1"

#submit
svn commit $LAB

if [ $? -ne 0 ]
then
	echo "Invalid parameter $1"
	exit 0
fi

