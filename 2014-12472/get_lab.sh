#!/bin/sh
LAB="lab"
LAB_VERSION="$1"


if [ $# -ne 1 ]
then
    echo "Usage: $0 [lab version 0 ~ 7]"
    exit 0
fi

LAB="$LAB$1"
#1 Create Repository
echo "Getting source codes..."
scp -r archi15@hyewon.snu.ac.kr:/home/svn/CA2015s/source/$LAB ./

if [ $? -ne 0 ]
then
	echo "Lab %1 not found"
	exit 0
fi

#2 Create initial version
echo "Adding initial directories to repository"
svn add $LAB

#3 check in repository
echo "checking in initial repository"
svn ci -m "Student Workspace for $LAB"
