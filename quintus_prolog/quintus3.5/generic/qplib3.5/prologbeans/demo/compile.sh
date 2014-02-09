#!/bin/sh
# The user can set the environment variable PBJARDIR to override
# the location of prologbeans.jar

if test -n $PBJARDIR; then
    PBJARDIR="../../../../java3.5"
fi
javac -classpath "$PBJARDIR/prologbeans.jar:." EvaluateGUI.java
