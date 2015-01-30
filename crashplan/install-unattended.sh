#!/bin/bash

#############################################################
# Linux Client Installer Script
#############################################################

# variables defined in install.defaults
# APP_BASENAME = human-readable application name
# DIR_BASENAME = dir name
# JRE_X64_DOWNLOAD_URL = url to the 64-bit jre
# JRE_I586_DOWNLOAD_URL = url to the 32-bit jre

SCRIPT_DIR=`dirname ${0}`
if [ ! -f "${SCRIPT_DIR}/install.defaults" ] ; then
	echo "${SCRIPT_DIR}/install.defaults MISSING!"
	exit 1
fi

. ${SCRIPT_DIR}/install.defaults

REQDBINS="grep sed cpio gzip cut head tail who"
OKJAVA="1.5 1.6 1.7"

PARENT_DIR=/usr/local
TARGETDIR=${PARENT_DIR}/${DIR_BASENAME}
BINSDIR=${PARENT_DIR}/bin
MANIFESTDIR=${PARENT_DIR}/var/${DIR_BASENAME}
INITDIR=/etc/init.d
RUNLEVEL=`who -r | sed -e 's/^.*\(run-level [0-9]\).*$/\1/' | cut -d \  -f 2`
RUNLVLDIR=/etc/rc${RUNLEVEL}.d

SRC_USER=${SUDO_USER}
if [ "x${SRC_USER}" == "x" ] ; then
	SRC_USER=${USER}
fi

USERNAME="`id -un`"

prepdir() {
	if [ ! -d "${1}" ] ; then
		echo -n "${1} does not exist.  Create $1? (y/n) [y] "
	#	read YN_PD
	#	if [ "x${YN_PD}" == "x" ] ; then
			YN_PD=y
	#	fi
		if [ "${YN_PD}" == "y" ] ; then
			mkdir -p "${1}"
			if [ $? -ne 0 ] ; then
				echo "Failed to create ${1}.  Please check your configuration."
				return 1
			fi
		else
			echo "Please check your configuration."
			return 1
		fi
	fi
	return 0
}

# welcome- avoid printing duplicate messages if we're recalling ourself
if [ "${1}" != "recall" ] ; then
	echo ""
	echo "Welcome to the ${APP_BASENAME} Installer."
	echo ""
	echo -n "Press enter to continue with installation. "
	#read ENTER
	
	# Basic requirements - 
	echo ""
	echo "Validating environment..."
fi

# Basic requirements
if [ "${USERNAME}" != "root" ] ; then
	echo ""
	echo "NOTE: You are apparently not installing as root. While it is recommended to"
	echo "install as root it is not required. If you continue to install as ${USERNAME}"
	echo "then ${APP_BASENAME} will only be able to back up files readable by ${USERNAME}."
	echo ""
	echo -n "Would you like to switch users and install as root? (y/n) [y] "
	#read YN
	#if [ "x${YN}" == "x" ] ; then
		YN=y
	#fi
	
	if [ "${YN}" == "y" ] ; then
		echo "  switching to root"
		sudo ${0} recall
		exit 0
	else
		echo "  installing as current user"
		
		PARENT_DIR=${HOME}
		TARGETDIR=${PARENT_DIR}/${DIR_BASENAME}
		BINSDIR=
		MANIFESTDIR=${TARGETDIR}/manifest
		INITDIR=
		RUNLVLDIR=
	fi
else
	echo "  detected root permissions"
fi

# ===============================================================================
# Validate the environment by verifying that all necessary binaries are present
# ===============================================================================
for BIN in $REQDBINS ; do

	BIN_PATH=`which $BIN 2> /dev/null`
	if [[ $? != 0 ]]; then
		echo "ERROR: $BIN not found and is required for install. Exiting"
		exit 1
	fi
done
#echo ""

# ===============================================================================
# Continue validation by verifying the existence of a supported Java VM
# ===============================================================================
JAVACOMMON="DOWNLOAD"

# Setup ARCHIVE var to point to the cpio archive.  This will be used here to extract what we need
# to execute the Java comparison below and will be used later by the script to 
# actually extract everything.
ARCHIVE=`ls ./*_*.cpi`

echo ""
echo "You must review and agree to the EULA before installation."
echo ""
echo -n "Press enter to read the EULA. "
#read ENTER

# EULA Time
#more ./EULA.txt

#agreed=0
agreed=1
while [ "${agreed}" == "0" ] ; do
	echo ""
	echo -n "Do you accept and agree to be bound by the EULA? (yes/no) "
	read reply
	case ${reply} in
		[yY] | [yY][eE][sS])
			agreed=1
			;;
		[nN] | [nN][oO])
			echo "If you do not agree to the license then ${APP_BASENAME} may not be installed. Exiting.";
			exit 1
			;;
	esac
done


INTERVIEW=0
while [ ${INTERVIEW} == 0 ] ; do

	INTERVIEWSUB=0
	while [ ${INTERVIEWSUB} == 0 ] ; do
		echo ""
		echo -n "What parent directory do you wish to install ${APP_BASENAME} into? [${PARENT_DIR}] "
		#read PARENT_DIR_X		
		if [ "x${PARENT_DIR_X}" != "x" ] ; then
			# remove trailing slash from PARENT_DIR
			PARENT_DIR_X=`echo ${PARENT_DIR_X} | sed '{s/\/$//g}'`

			## Make sure to append "crashplan" to the directory they entered. Many enter the parent directory and assume
			## we install into a subdirectory. So if they enter /usr then we don't want to install directly into /usr
			## as that becomes a problem when they later run the uninstall script and it blows away all of /usr.
			TARGETDIR=${PARENT_DIR_X}/${DIR_BASENAME}
			MANIFESTDIR=${TARGETDIR}/manifest
		fi
		
		prepdir "${TARGETDIR}"
		if [ $? == 0 ] ; then
			INTERVIEWSUB=1
		fi
	done
		

	if [ "${USERNAME}" == "root" ] ; then
		INTERVIEWSUB=0
		while [ ${INTERVIEWSUB} == 0 ] ; do
			echo ""
			echo -n "What directory do you wish to link the ${APP_BASENAME} executable to? [${BINSDIR}] "
		#	read BINSDIR_X
			if [ "x${BINSDIR_X}" != "x" ] ; then
				BINSDIR=${BINSDIR_X}
			fi
			prepdir ${BINSDIR}
			if [ $? == 0 ] ; then
				INTERVIEWSUB=1
			fi
		done
	fi

	INTERVIEWSUB=0
	while [ ${INTERVIEWSUB} == 0 ] ; do
		echo ""
		echo -n "What directory do you wish to store backups in? [${MANIFESTDIR}] "
		#read MANIFESTDIR_X
		if [ "x${MANIFESTDIR_X}" != "x" ] ; then
			MANIFESTDIR=${MANIFESTDIR_X}
		fi
		prepdir ${MANIFESTDIR}
		if [ $? == 0 ] ; then
			INTERVIEWSUB=1
		fi
	done

	if [ "${USERNAME}" == "root" ] ; then
		INTERVIEWSUB=0
		while [ ${INTERVIEWSUB} == 0 ] ; do
			echo ""
			echo -n "What directory contains your SYSV init scripts? [${INITDIR}] "
		#	read INITDIR_X
			if [ "x${INITDIR_X}" != "x" ] ; then
				INITDIR=${INITDIR_X}
			fi
			prepdir ${INITDIR}
			if [ $? == 0 ] ; then
				INTERVIEWSUB=1
			fi
		done

		INTERVIEWSUB=0
		while [ ${INTERVIEWSUB} == 0 ] ; do
			echo ""
			echo -n "What directory contains your runlevel init links? [${RUNLVLDIR}] "
		#	read RUNLVLDIR_X
			if [ "x${RUNLVLDIR_X}" != "x" ] ; then
				RUNLVLDIR=${RUNLVLDIR_X}
			fi
			prepdir ${RUNLVLDIR}
			if [ $? == 0 ] ; then
				INTERVIEWSUB=1
			fi
		done
	fi
	echo ""
	echo "Your selections:"
	echo ${APP_BASENAME} will install to: ${TARGETDIR}
	if [ "${USERNAME}" == "root" ] ; then
		echo And put links to binaries in: ${BINSDIR}
	fi
	echo And store datas in: ${MANIFESTDIR}
	if [ "${USERNAME}" == "root" ] ; then
		echo Your init.d dir is: ${INITDIR}
		echo Your current runlevel directory is: ${RUNLVLDIR}
	fi
	echo ""
	echo -n "Is this correct? (y/n) [y] "
	#read YN
	#if [ "x${YN}" == "x" ] ; then
		YN=y
#	fi

	if [ "${YN}" == "y" ] ; then
		INTERVIEW=1
	fi
done

# INSTALL TIME ===============================================
echo ""

# is crashplan already there?
if [ -f ${TARGETDIR}/install.vars ]; then
	echo "CrashPlan appears to already be installed in the specified location:"
	echo "  ${TARGETDIR}"
	echo "Please uninstall and then try this install again."
	exit 1
fi

# create a file that has our install vars so we can later uninstall
echo "" > ${TARGETDIR}/install.vars
echo "TARGETDIR=${TARGETDIR}" >> ${TARGETDIR}/install.vars
echo "BINSDIR=${BINSDIR}" >> ${TARGETDIR}/install.vars
echo "MANIFESTDIR=${MANIFESTDIR}" >> ${TARGETDIR}/install.vars
echo "INITDIR=${INITDIR}" >> ${TARGETDIR}/install.vars
echo "RUNLVLDIR=${RUNLVLDIR}" >> ${TARGETDIR}/install.vars
NOW=`date +%Y%m%d`
echo "INSTALLDATE=$NOW" >> ${TARGETDIR}/install.vars
cat ${SCRIPT_DIR}/install.defaults >> ${TARGETDIR}/install.vars

# keep track of the processor architecture
PARCH=`uname -m`
	
#download java
if [[ $JAVACOMMON == "DOWNLOAD" ]]; then
	if [[ $PARCH == "x86_64" ]]; then
		JVMURL="${JRE_X64_DOWNLOAD_URL}"
	else
		JVMURL="${JRE_I586_DOWNLOAD_URL}"
	fi
	JVMFILE=`basename ${JVMURL}`
	if [[ -f ${JVMFILE} ]]; then
		echo ""
		echo "Download of the JVM found. We'll try to use it, but if it's only a partial"
		echo "copy of the file then this will fail. If that happens please remove the file"
		echo "and try again."
		echo "JRE Archive: ${JVMFILE}"
		echo ""
	else
	
	    # Start by looking for wget
	    WGET_PATH=`which wget 2> /dev/null`
	    if [[ $? == 0 ]]; then
			echo "    downloading the JRE using wget"
			$WGET_PATH $JVMURL
			if [[ $? != 0 ]]; then
				echo "Unable to download JRE; please check network connection"
				exit 1
			fi
	    else

			CURL_PATH=`which curl 2> /dev/null`
			if [[ $? == 0 ]]; then
		    	echo "    downloading the JRE using curl"
		    	$CURL_PATH -L $JVMURL -o `basename $JVMURL`
				if [[ $? != 0 ]]; then
					echo "Unable to download JRE; please check network connection"
					exit 1
				fi
			else
		    	echo "Could not find wget or curl.  You must install one of these utilities"
		    	echo "in order to download a JVM"
		    	exit 1
			fi
	    fi
	fi

	HERE=`pwd`
	cd ${TARGETDIR}
	# Extract into ./jre
	tar -xzf "${HERE}/${JVMFILE}"
	cd "${HERE}"
	JAVACOMMON="${TARGETDIR}/jre/bin/java"
	echo "Java Installed."
fi
echo "" >> ${TARGETDIR}/install.vars
echo "JAVACOMMON=${JAVACOMMON}" >> ${TARGETDIR}/install.vars

# Definition of ARCHIVE occurred above when we extracted the JAR we need to evaluate Java environment
echo Unpacking ${HERE}/${ARCHIVE} ... 
HERE=`pwd`
cd ${TARGETDIR}
cat "${HERE}/${ARCHIVE}" | gzip -d -c - | cpio -i --no-preserve-owner
cd "${HERE}"

# custom?
if [ -d .Custom ]; then
  echo Copying .Custom to ${TARGETDIR}
  cp -Rp .Custom "${TARGETDIR}"
fi
if [ -d custom ]; then
  echo Copying custom to ${TARGETDIR}
  cp -Rp custom "${TARGETDIR}"
fi
if [ -d Custom ]; then
  echo Copying custom to ${TARGETDIR}
  cp -Rp custom "${TARGETDIR}"
fi

#update the configs for file storage
if grep "<manifestPath>.*</manifestPath>" ${TARGETDIR}/conf/default.service.xml > /dev/null
	then
		sed -i "s|<manifestPath>.*</manifestPath>|<manifestPath>${MANIFESTDIR}</manifestPath>|g" ${TARGETDIR}/conf/default.service.xml
	else
		sed -i "s|<backupConfig>|<backupConfig>\n\t\t\t<manifestPath>${MANIFESTDIR}</manifestPath>|g" ${TARGETDIR}/conf/default.service.xml
fi

# the log dir
LOGDIR=${TARGETDIR}/log
chmod 777 $LOGDIR

# desktop init script
GUISCRIPT=${TARGETDIR}/bin/${APP_BASENAME}Desktop
cp scripts/${APP_BASENAME}Desktop ${GUISCRIPT}
chmod 755 ${GUISCRIPT}
#sed -imod "s|TARGETDIR=.*|TARGETDIR=${TARGETDIR}|" ${GUISCRIPT} && rm -rf ${GUISCRIPT}mod

# link to bin if appropriate
if [ "x${BINSDIR}" != "x" ] ; then
	ln -s ${GUISCRIPT} ${BINSDIR}/${APP_BASENAME}Desktop
fi


# Install the control script for the service
INITSCRIPT=${TARGETDIR}/bin/${APP_BASENAME}Engine
cp scripts/${APP_BASENAME}Engine ${INITSCRIPT}
cp scripts/run.conf ${TARGETDIR}/bin
chmod 755 ${INITSCRIPT}

# Install the init script and modify it by applying variables currently defined in this context
# If the user is not installing as root then we install into the bin directory only.
INIT_INSTALL_DIR=${TARGETDIR}/bin
if [ "x${INITDIR}" != "x" ] ; then
   INIT_INSTALL_DIR=${INITDIR}
fi
   
# Perform substitution on the init script; we need to make the value of INITSCRIPT available
# to what lives in /etc/init.d
SEDEXPRSUB=`echo $INITSCRIPT | sed 's/\//\\\\\//g'`
SEDEXPR="s/<INITSCRIPT>/$SEDEXPRSUB/g"
sed $SEDEXPR scripts/${DIR_BASENAME} > ${INIT_INSTALL_DIR}/${DIR_BASENAME}
chmod 755 ${INIT_INSTALL_DIR}/${DIR_BASENAME}

if [ "x${RUNLVLDIR}" != "x" ] ; then

   # Now that we should have a working init script let's link in the runlevel scripts   
   ln -s ${INIT_INSTALL_DIR}/${DIR_BASENAME} ${RUNLVLDIR}/S99${DIR_BASENAME}
fi


# copy the desktop launcher into place
if [ -d "/home/${SRC_USER}/Desktop" ] ; then
	DESKTOP_LAUNCHER="/home/${SRC_USER}/Desktop/${APP_BASENAME}.desktop"
	
	# which icon are we using? custom if it exists
	DESKTOP_ICON_PATH=${TARGETDIR}/skin/icon_app_128x128.png
	if [ -f ${TARGETDIR}/skin/custom/icon_app_64x64.png ] ; then
		DESKTOP_ICON_PATH=${TARGETDIR}/skin/custom/icon_app_64x64.png
	fi
	if [ -f ${TARGETDIR}/skin/custom/icon_app_128x128.png ] ; then
		DESKTOP_ICON_PATH=${TARGETDIR}/skin/custom/icon_app_128x128.png
	fi
	
	# use 'su' only if we're operating as root
	if [ "${USERNAME}" == "root" ] ; then
		su ${SRC_USER} -c "cp scripts/${APP_BASENAME}.desktop ${DESKTOP_LAUNCHER}"
		su ${SRC_USER} -c "chmod +x ${DESKTOP_LAUNCHER}"
		su ${SRC_USER} -c "sed -imod \"s|Exec=.*|Exec=${GUISCRIPT}|\" ${DESKTOP_LAUNCHER} && rm -rf ${DESKTOP_LAUNCHER}mod"
		su ${SRC_USER} -c "sed -imod \"s|Icon=.*|Icon=${DESKTOP_ICON_PATH}|\" ${DESKTOP_LAUNCHER} && rm -rf ${DESKTOP_LAUNCHER}mod"
	else
		cp scripts/${APP_BASENAME}.desktop ${DESKTOP_LAUNCHER}
		chmod +x ${DESKTOP_LAUNCHER}
		sed -imod "s|Exec=.*|Exec=${GUISCRIPT}|" ${DESKTOP_LAUNCHER} && rm -rf ${DESKTOP_LAUNCHER}mod
		sed -imod "s|Icon=.*|Icon=${DESKTOP_ICON_PATH}|" ${DESKTOP_LAUNCHER} && rm -rf ${DESKTOP_LAUNCHER}mod
	fi
fi

# Check for max_user_watches and suggest updating if necessary.  Many distros use 8192 by default
# so we use this value as a baseline.
INOTIFY_WATCHES=`cat /proc/sys/fs/inotify/max_user_watches`
if [[ $INOTIFY_WATCHES -le 8192 ]]; then
  echo ""
  echo "Your Linux system is currently configured to watch $INOTIFY_WATCHES files in real time."
  echo "We recommend using a larger value; see the CrashPlan support site for details"
  echo ""
fi

# Start the servce
${INITSCRIPT} start

# call out the "service has been started" by creating a pause
echo ""
echo "${APP_BASENAME} has been installed and the Service has been started automatically."
echo ""
echo -n "Press Enter to complete installation. "
#read ENTER

echo ""
echo "Important directories:"
echo "  Installation:"
echo "    ${TARGETDIR}"
echo "  Logs:"
echo "    ${TARGETDIR}/log"
echo "  Default archive location:"
echo "    ${MANIFESTDIR}"

# if we installed as root make sure they see 'sudo' in front of the Engine start
SUDO_PREFIX="sudo "
if [ "${USERNAME}" != "root" ] ; then
	SUDO_PREFIX=""
fi
echo ""
echo "Start Scripts:"
echo "  ${SUDO_PREFIX}${INITSCRIPT} start|stop"
echo "  ${GUISCRIPT}"

echo ""
echo "You can run the ${APP_BASENAME} Desktop UI locally as your own user or connect"
echo "a remote Desktop UI to this Service via port-forwarding and manage it"
echo "remotely. Instructions for remote management are in the readme files"
echo "placed in your installation directory:"
echo "  ${TARGETDIR}/doc"
echo ""
if [ "x${DISPLAY}" != "x" ] ; then
	echo -n "Would you like to start ${APP_BASENAME}Desktop? (y/n) [y] "
	read reply
	if [ "x${reply}" == "x" ] ; then
		reply=y
	fi
	case ${reply} in
		[yY] | [yY][eE][sS])
			# use 'su' only if we're operating as root
			if [ "${USERNAME}" == "root" ] ; then
				su ${SRC_USER} -c "${GUISCRIPT}"
			else
				${GUISCRIPT}
			fi
			;;
	esac
fi

echo ""
echo "To start the Desktop UI:"
if [ "x${BINSDIR}" != "x" ] ; then
	echo "  ${BINSDIR}/${APP_BASENAME}Desktop"
else
echo "  ${GUISCRIPT}"
fi

echo ""
echo "Installation is complete. Thank you for installing ${APP_BASENAME} for Linux."
echo ""

