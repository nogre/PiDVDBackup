#!/bin/bash

# Software installed
# Dietpi.com for Raspberry Pi
# apt install genisoimage growisofs lsscsi

# lsscsi is used to find the USB scsi device ID, needed below.
# Assume '/dev/sr0' for the DVD+RW drive

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

# Check if files are writable to DVD using growisofs
#   https://linux.die.net/man/1/growisofs
unset TESTRUN
TESTRUN=$(growisofs -dry-run -Z /dev/sr0 $tarchive 2>&1)
if [[ $TESTRUN =~ 'media is not recognized' ]]; then 
  # not recognized if CD, DVD is finalized
  echo "media not recognized"
  # set not recognized warning
elif [[ $TESTRUN =~ 'No such file' ]]; then 
  # no file to write
  echo "no data file to burn"
  # set no file to write warning
elif [[ $TESTRUN =~ 'is larger than' ]]; then 
  # file is too large to write
  echo "file is too large"
  # set file is too large warning
elif [[ $TESTRUN =~ 'to be written!' ]]; then 
  # not enough space left to write data
  echo "not enough space left on disk"
  # set not enough space warning
  
  # Finalize DVD?
  # growisofs -M /dev/sr0=/dev/zero
elif [[ $TESTRUN =~ ':-\(' ]]; then
  echo "unhappy face"
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
  # Get the device ID via `lsscsi -v`.
  #   https://stackoverflow.com/a/56427483
  echo "0:0:0:0" > /sys/bus/scsi/drivers/sr/unbind
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
  if [[ $TESTRUN2 =~ 'to be written!' ]]; then 
    echo "fewer than $count writes left!"
    # set running out of space warning
  fi
  # remove testFile
  rm $testFile

fi  

# remove temporary archive
rm $tarchive
