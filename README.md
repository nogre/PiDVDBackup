# Pi DVD Backup System

An automated system to backup to DVD media.

    Ummm, why don't you just back up to the cloud?

The cloud, or Other People's Computers, has the virtue of letting one believe that their data is safe in someone else's hands. Insofar as fees are paid, the company is professional and honorable, and disaster doesn't strike them, Other People's Computers is [a good backup solution](https://tarsnap.com).

To mitigate any potential breakdown in the cloud solution, to prevent it from being a single point of failure, a secondary backup is needed, namely a local backup.

Dedicated redundant local backups can cost [hundreds of dollars](https://www.crowdsupply.com/gnubee/personal-cloud-1) to [many thousands](https://www.ixsystems.com/). For my comparably tiny amounts of critical data, these systems are overkill (and out of my price range). A cobbled together version, using an old case, drives, etc., would probably work, but that could still run hundreds of dollars and fail because of the dodgy old hardware.

Instead, I decided to go small: A Raspberry Pi Zero W with DVD-R. 

Every day the Pi rsync's data from a server, and then burns that data to a DVD-R. Note that this is not a DVD+RW: the media is write-once. So, even if the Pi gets corrupted, my servers get cryptolocked, and the cloud solution disappears, the DVD data is immutable. It is my "paper-backup" in this cloudy world.

I'm reminded of the old saying, 

> Never underestimate the bandwidth of a station wagon full of tapes hurtling down the highway. –[Andrew Tanenbaum, 1981](https://what-if.xkcd.com/31/)

Just as storage density has gone up, costs for media have come down. Current prices are about $16 USD for 100 4.7GB DVD-R. Rounding off, that's 4 cents per gig, while allowing for arbitrary amounts of redundancy. I could not find a way to achieve this redundancy or cost effectiveness by other means.

## Hardware & Media

Microcenter prices listed for Pi and power supply; Ebay for the cable, DVD writer and media (August 2019).

Raspberry Pi Zero W : $5

Power Supply: $4

On The Go Cable: $3

USB DVD+RW: $15

DVD-R media: $16

Grand total for the basic hardware is less that $30, plus $16 for 100 DVD-R. I had a Pi Zero W, power supply, and on the go cable from other projects already. A secondary or tertiary DVD+RW could easily be added to the system for not much more. A powered usb hub, or independently powered DVD+RWs, are also recommended to prevent power drops to the Pi when burning disks.

## Software

[DietPi](https://dietpi.com) operating system for the Pi, which is a very lightweight, well-featured Debian OS for many single board computers. [growisofs](https://linux.die.net/man/1/growisofs) controls the DVD burning. See the script for details.

Load DietPi on the Pi. Install growisofs and its few dependencies. Create cron jobs to download your data and then burn the DVD using the shell script provided here (customize as needed). 
