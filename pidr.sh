#!/bin/bash

# Copyright 2019 Noah Greenstein. MIT License.

# Software installed
# Dietpi.com for Raspberry Pi
# apt install genisoimage growisofs lsscsi

# Create a loop or copy this script with different device data for a mirror.
#  lsscsi is used to find the USB scsi device ID, needed below.
#  Assume '/dev/sr0' for the DVD+RW drive

# Detect disk
#  https://www.linuxquestions.org/questions/linux-general-1/how-can-i-detect-a-blank-dvd-473904/#post2380233
unset NODISK
NODISK=$(/usr/bin/isoinfo -d -i /dev/sr0 2>&1 | grep 'No such file')
if [[ -z "NODISK" ]]; then
  echo "There is no disk in the drive"
  # set no disk warning
  
  exit 1
fi

# Disk in drive

# put files to burn into temporary archive
tarchive="/path/to/temporary/archive.tgz"
tar -czf $tarchive /path/to/backup/files

# check if archiving was successful
if [ ! -e $tarchive ]; then
  echo "Archive not found!"
  # set no archive warning
  exit 1
fi

# Check if files are writable to DVD using growisofs
#   https://linux.die.net/man/1/growisofs
unset TESTRUN
TESTRUN=$(growisofs -dry-run -Z /dev/sr0 $tarchive 2>&1)
if [[ $TESTRUN =~ 'unable to open64' ]]; then 
  # can't open DVD+RW, can't find sr0
  echo "unable to find DVD+RW"
  # set no drive warning
elif [[ $TESTRUN =~ 'media is not recognized' ]]; then 
  # not recognized if CD, DVD is finalized
  echo "media not recognized" > $statusFile
  # set not recognized warning
elif [[ $TESTRUN =~ 'No such file' ]]; then 
  # no file to wr
  echo "no data file to burn"
  # set no file to write warning
elif [[ $TESTRUN =~ 'is larger than' ]]; then 
  # file is too large to write
  echo "file is too large"
  # set file is too large warning
elif [[ $TESTRUN =~ 'session would cross' ]]; then 
  # out of space
  echo "out of space"
  # set out of space warning
elif [[ $TESTRUN =~ 'to be written!' ]]; then 
  # not enough space left to write data
  echo "not enough space left on disk"
  # set not enough space warning
  
  # Finalize DVD?
  # growisofs -M /dev/sr0=/dev/zero
elif [[ $TESTRUN =~ 'aborting..' ]]; then
  echo "generic abort"
  # set generic fail warning
else
  # No errors, burn!

  #  Check if disk is empty; different flag needed for initial burn
  if [[ $TESTRUN =~ 'already carries isofs' ]]; then
    echo "The disk is not empty"

    growisofs -M /dev/sr0 -R -J -use-the-force-luke=notray $tarchive
    # remove warning if exists
  else
    # The disk is  empty
    echo "The disk is empty"
    growisofs -Z /dev/sr0 -R -J -use-the-force-luke=notray $tarchive

  fi
  
  # Disk media needs to be fully reloaded after it is modified. Normal reloads 
  # are triggered when the media is inserted. growisofs will attempt to eject
  # and reclose the tray after a burn to get the system to do the reload. As 
  # external DVD writers have spring loaded trays that do not automatically
  # close, this needs to be worked around: note the "notray" option above,
  # which prevents the automatic tray opening and closing. Instead reload the
  # disk by turning the media device off and back on (sic), as the media is
  # also loaded on start up.
  # Get the device ID via `lsscsi -v`. https://stackoverflow.com/a/56427483
  #    don't unplug immediately: not sure the DVD writer is actually finished
  sleep 30s
  echo "0:0:0:0" > /sys/bus/scsi/drivers/sr/unbind
  sleep 15s
  echo "0:0:0:0" > /sys/bus/scsi/drivers/sr/bind

  # Check if getting close to capacity of media 
 
  # Make temp sparse file of n times size of archive
  #   https://unix.stackexchange.com/a/16645
  count=5
  testFile="sizeTest.img"
  file_size_mb=`du -m "$tarchive" | cut -f1`
  truncate -s $[$count*$file_size_mb]M $testFile
  # Test burn
  unset TESTRUN2
  TESTRUN2=$(growisofs -dry-run -M /dev/sr0 $testFile 2>&1)
  if [[ $TESTRUN2 =~ 'to be written!' || $TESTRUN2 =~ 'aborting..' ]]; then 
    echo "fewer than $count writes left!"
    # set running out of space warning
  fi
  # remove testFile
  rm $testFile

fi  

# remove temporary archive
rm $tarchive
