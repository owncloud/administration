#!/usr/bin/env bash 

## Print header
 echo -e "Size\tResid.\tShared\tData\t%"
 while [ 1 ]; do
    ## Get the PID of the process name given as argument 1
     pidno=`pgrep $1`
    ## If the process is running, print the memory usage
     if [ -e /proc/$pidno/statm ]; then
     ## Get the memory info
      m=`awk '{OFS="\t";print $1,$2,$3,$6}' /proc/$pidno/statm`
     ## Get the memory percentage
      perc=`top -bd 0.10 -p $pidno -n 1  | grep $pidno | gawk '{print \$10}'`
     ## print the results
      echo -e "$m\t$perc";
      sleep 2
    ## If the process is not running
     else
      echo "$1 is not running";
     fi
 done

