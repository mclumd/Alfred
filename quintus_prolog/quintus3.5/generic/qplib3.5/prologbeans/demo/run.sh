#!/bin/sh
# The user can set the environment variable PBJARDIR to override the
# location of prologbeans.jar

: ${PBJARDIR="../../../../java3.5"}

echo Starting Java client
echo You need to start Prolog server separately using something like:
echo prolog +l evaluate_run

java -classpath "$PBJARDIR/prologbeans.jar:." EvaluateGUI
