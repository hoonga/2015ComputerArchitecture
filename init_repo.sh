#!/bin/sh
STUDENT="$1"

STUDENTSVN="svn://hyewon.snu.ac.kr/CA2015s/student"

if [ $# -ne 1 ]
then
	echo "Error: Usage: $0 username"
	exit 0
fi

#1 Create Repository
echo "Creating repository for $STUDENT"
svn mkdir $STUDENTSVN/$STUDENT --username $STUDENT

#2 Checking out Repository
svn co $STUDENTSVN/$STUDENT $STUDENT --username $STUDENT
