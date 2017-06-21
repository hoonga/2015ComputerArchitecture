#!/bin/sh
STUDENTSVN="svn://hyewon.snu.ac.kr/CA2015s/student"

LAB="lab"
LAB_VERSION="$1"

if [ $# -ne 1 ] 
then
    echo "Usage: $0 [lab version]"
    exit 0
fi

if [ "$1" -lt 0 -o "$1" -gt 7 ]
then
    echo "Invalid parameter $1"
    echo "lab version should be between 0 and 7"
    exit 0
fi

LAB="$LAB$1"

STUDENT=$(echo $PWD | cut -d- -f4 | cut -d/ -f4)
#echo $student

rm -rf $LAB
svn update
