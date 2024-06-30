#!/bin/bash

# On MacOS the following utilities are needed.
# brew install --with-default-names jq gnu-sed coreutils
# BOXES=(`find output -type f -name "*.box"`)
# parallel -j 4 --xapply res/scripts/direct.sh {1} ::: "${BOXES[@]}"

# Handle self referencing, sourcing etc.
if [[ $0 != "${BASH_SOURCE[0]}" ]]; then
  export CMD="${BASH_SOURCE[0]}"
else
  export CMD=$0
fi

# Ensure a consistent working directory so relative paths work.
pushd "$(dirname "$CMD")" > /dev/null
BASE=$(pwd -P)
popd > /dev/null

# This logic allows us to force colorized output regardless of what 
# TERM and/or tput indicate. Activate forced color mode if COLORTERM is set 
# to any value, or if USE_ANSI_COLORS is set to 1, yes, or simply y. 
test -t 1 && {
  
  # Use ANSI escape sequences.
  case "$USE_ANSI_COLORS" in
    y|yes|Y|YES) USE_ANSI_COLORS=1 ;;
  esac
  test -n "${COLORTERM+set}" && : ${USE_ANSI_COLORS="1"}
  if test 1 = "$USE_ANSI_COLORS"; then
    
    # Modifiers
    T_BOLD="\e[0;1m" 
    T_ULINE="\e[0;4m"
    T_RESET="\e[0;0m"

    # Text Colors
    T_BLK="\e[0;30m" 
    T_RED="\e[0;31m" 
    T_GRN="\e[0;32m" 
    T_YEL="\e[0;33m" 
    T_BLU="\e[0;34m" 
    T_MAG="\e[0;35m" 
    T_CYN="\e[0;36m" 
    T_WHT="\e[0;37m" 

    # Text Colors (With Bold)
    T_BBLK="\e[1;30m"
    T_BRED="\e[1;31m"
    T_BGRN="\e[1;32m"
    T_BYEL="\e[1;33m"
    T_BBLU="\e[1;34m"
    T_BMAG="\e[1;35m"
    T_BCYN="\e[1;36m"
    T_BWHT="\e[1;37m"

  # Let tput decide.
  else
    test -n "$(tput sgr0 2>/dev/null)" && {
      
      # Modifiers
      T_RESET=$(tput sgr0)
      test -n "$(tput bold 2>/dev/null)" && T_BOLD=$(tput bold)
      test -n "$(tput sgr 0 1 2>/dev/null)" && T_ULINE=$(tput sgr 0 1)
      
      # Text Colors
      test -n "$(tput setaf 0 2>/dev/null)" && T_BLK=$(tput setaf 0)
      test -n "$(tput setaf 1 2>/dev/null)" && T_RED=$(tput setaf 1)
      test -n "$(tput setaf 2 2>/dev/null)" && T_GRN=$(tput setaf 2)
      test -n "$(tput setaf 3 2>/dev/null)" && T_YEL=$(tput setaf 3)
      test -n "$(tput setaf 4 2>/dev/null)" && T_BLU=$(tput setaf 4)
      test -n "$(tput setaf 5 2>/dev/null)" && T_MAG=$(tput setaf 5)
      test -n "$(tput setaf 6 2>/dev/null)" && T_CYN=$(tput setaf 6)
      test -n "$(tput setaf 7 2>/dev/null)" && T_WHT=$(tput setaf 7)
      
      # Text Colors (With Bold)
      T_BBLK="${T_BOLD}${T_BLK}"
      T_BRED="${T_BOLD}${T_RED}"
      T_BGRN="${T_BOLD}${T_GRN}"
      T_BYEL="${T_BOLD}${T_YEL}"
      T_BBLU="${T_BOLD}${T_BLU}"
      T_BMAG="${T_BOLD}${T_MAG}"
      T_BCYN="${T_BOLD}${T_CYN}"
      T_BWHT="${T_BOLD}${T_WHT}"
    }
  fi
}

if [ $# != 1 ] && [ $# != 2 ]; then
  printf "\n  Usage:\n    $0 FILENAME\n\n"
  exit 1
fi

# Make sure the recursion level is numeric.
if [ $# == 2 ] && [ -z "${2##*[!0-9]*}" ]; then
  printf "\n${T_RED}  Invalid recursion level. Exiting.${T_RESET}\n\n"
  exit 1
fi

# Make sure the file exists.
if [ ! -f "$1" ]; then
  printf "\n${T_RED}  The $1 file does not exist. Exiting.${T_RESET}\n\n"
  exit 1
fi

# If a second variable is provided then check to ensure we haven't hit the recursion limit.
if [ $# == 2 ] && [ "$2" -gt "10" ]; then
  printf "\n${T_RED}  The recursion level has been reached. Exiting.${T_RESET}\n\n"
  exit 1
# Otherwise increment the level.
elif [ $# == 2 ]; then
  export RECURSION=$(($2+1))
# If no level is provided set an initial level of 0.
else
  export RECURSION=1
fi

if [ -f /opt/vagrant/embedded/lib64/libssl.so ] && [ -z "$LD_PRELOAD" ]; then
  export LD_PRELOAD="/opt/vagrant/embedded/lib64/libssl.so"
elif [ -f /opt/vagrant/embedded/lib64/libssl.so ]; then
  export LD_PRELOAD="/opt/vagrant/embedded/lib64/libssl.so:$LD_PRELOAD"
fi

if [ -f /opt/vagrant/embedded/lib64/libcrypto.so ] && [ -z "$LD_PRELOAD" ]; then
  export LD_PRELOAD="/opt/vagrant/embedded/lib64/libcrypto.so"
elif [ -f /opt/vagrant/embedded/lib64/libcrypto.so ]; then
  export LD_PRELOAD="/opt/vagrant/embedded/lib64/libcrypto.so:$LD_PRELOAD"
fi

export LD_LIBRARY_PATH="/opt/vagrant/embedded/bin/lib/:/opt/vagrant/embedded/lib64/"

if [[ "$(uname)" == "Darwin" ]]; then
  export CURL_CA_BUNDLE=/opt/vagrant/embedded/cacert.pem
fi

# The jq tool is needed to parse JSON responses.
if [ ! -f /usr/bin/jq ] && [ ! -f /usr/local/bin/jq ]; then
  printf "\n${T_RED}  The 'jq' utility is not installed. Exiting.${T_RESET}\n\n"
  exit 1
fi

# Ensure the credentials file is available.
if [ -f "$BASE/../../.credentialsrc" ]; then
  source "$BASE/../../.credentialsrc"
else
  printf "\n${T_RED}  The credentials file is missing. Exiting.${T_RESET}\n\n"
  exit 2
fi

if [ -z "${VAGRANT_CLOUD_TOKEN}" ]; then
  printf "\n${T_RED}  The vagrant cloud token is missing. Add it to the credentials file. Exiting.${T_RESET}\n\n"
  exit 2
fi

# See if the log directory exists, if not create it.
if [ ! -d "$BASE/../../logs/" ]; then
  mkdir -p "$BASE/../../logs/" || mkdir "$BASE/../../logs"
fi

export UPLOAD_STD_LOGFILE="$BASE/../../logs/direct.txt"
export UPLOAD_ERR_LOGFILE="$BASE/../../logs/direct.errors.txt"

if [ -f /opt/vagrant/embedded/bin/curl ]; then
  export CURL="/opt/vagrant/embedded/bin/curl"
else
  export CURL="curl"
fi

FILENAME="$(basename "$1")"
FILEPATH="$(realpath "$1")"
VAGRANTPATH="app.vagrantup.com"

ORG="$(echo "$FILENAME" | sed "s/\([a-z]*\)[\-]*\([a-z0-9-]*\)-\(hyperv\|vmware\|libvirt\|docker\|parallels\|virtualbox\)-\([a-z0-9-]*\)-\([0-9\.]*\).box/\1/g")"
BOX="$(echo "$FILENAME" | sed "s/\([a-z]*\)[-]*\([a-z0-9-]*\)-\(hyperv\|vmware\|libvirt\|docker\|parallels\|virtualbox\)-\([a-z0-9-]*\)-\([0-9\.]*\).box/\2/g")"
PROVIDER="$(echo "$FILENAME" | sed "s/\([a-z]*\)[-]*\([a-z0-9-]*\)-\(hyperv\|vmware\|libvirt\|docker\|parallels\|virtualbox\)-\([a-z0-9-]*\)-\([0-9\.]*\).box/\3/g")"
ARCH="$(echo "$FILENAME" | sed "s/\([a-z]*\)[-]*\([a-z0-9-]*\)-\(hyperv\|vmware\|libvirt\|docker\|parallels\|virtualbox\)-\([a-z0-9-]*\)-\([0-9\.]*\).box/\4/g")"
VERSION="$(echo "$FILENAME" | sed "s/\([a-z]*\)[-]*\([a-z0-9-]*\)-\(hyperv\|vmware\|libvirt\|docker\|parallels\|virtualbox\)-\([a-z0-9-]*\)-\([0-9\.]*\).box/\5/g")"

DEFAULT_ARCH="false"

# Handle the Lavabit boxes.
if [ "$ORG" == "magma" ]; then
  ORG="lavabit"
  if [ "$BOX" == "" ]; then
    BOX="magma"
  else
    BOX="magma-$BOX"
  fi

  # Specialized magma box name mappings.
  [ "$BOX" == "magma-alpine36" ] && BOX="magma-alpine"
  [ "$BOX" == "magma-freebsd11" ] && BOX="magma-freebsd"
  [ "$BOX" == "magma-openbsd6" ] && BOX="magma-openbsd"

fi

# Handle the Lineage boxes.
if [ "$ORG" == "lineage" ] || [ "$ORG" == "lineageos" ]; then
  if [ "$BOX" == "" ]; then
    BOX="lineage"
  else
    BOX="lineage-$BOX"
  fi
fi

# Handle the Vmware provider type.
if [ "$PROVIDER" == "vmware" ]; then
  PROVIDER="vmware_desktop"
fi

# Handle the arch types.
if [ "$ARCH" == "x64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "amd64" ]; then
  ARCH="amd64"
elif [ "$ARCH" == "x32" ] || [ "$ARCH" == "x86" ] || [ "$ARCH" == "i386" ] || [ "$ARCH" == "i686" ]; then
  ARCH="i386"
elif [ "$ARCH" == "a64" ] || [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ] || [ "$ARCH" == "arm64eb" ]|| [ "$ARCH" == "arm64le" ]; then
  ARCH="arm64"
elif [ "$ARCH" == "a32" ] || [ "$ARCH" == "armv7" ] || [ "$ARCH" == "armv6" ] || [ "$ARCH" == "arm" ] || [ "$ARCH" == "armeb" ] || [ "$ARCH" == "armle" ] || [ "$ARCH" == "armel" ] || [ "$ARCH" == "armhf" ]; then
  ARCH="arm"
elif [ "$ARCH" == "m64" ] || [ "$ARCH" == "mips64le" ] || [ "$ARCH" == "mips64el" ] || [ "$ARCH" == "mips64hfel" ]; then
  ARCH="mips64le"
elif [ "$ARCH" == "mips64" ] || [ "$ARCH" == "mips64hf" ] ; then
  ARCH="mips64"
elif [ "$ARCH" == "m32" ] || [ "$ARCH" == "mips" ] || [ "$ARCH" == "mips32" ] || [ "$ARCH" == "mipsn32" ] || [ "$ARCH" == "mipshf" ] ; then
  ARCH="mips"
elif [ "$ARCH" == "mipsle" ] || [ "$ARCH" == "mipsel" ] || [ "$ARCH" == "mipselhf" ]; then
  ARCH="mipsle"
elif [ "$ARCH" == "p64" ] || [ "$ARCH" == "ppc64le" ]; then
  ARCH="ppc64le"
elif [ "$ARCH" == "ppc64" ] || [ "$ARCH" == "power64" ] || [ "$ARCH" == "powerpc64" ]; then
  ARCH="ppc64"
elif [ "$ARCH" == "p32" ] || [ "$ARCH" == "ppc32" ] || [ "$ARCH" == "power" ] || [ "$ARCH" == "power32" ] || [ "$ARCH" == "powerpc" ] || [ "$ARCH" == "powerpc32" ] || [ "$ARCH" == "powerpcspe" ]; then
  ARCH="ppc"
elif [ "$ARCH" == "r64" ] || [ "$ARCH" == "riscv64" ] || [ "$ARCH" == "riscv64sf" ]; then
  ARCH="riscv64"
elif [ "$ARCH" == "r32" ] || [ "$ARCH" == "riscv" ] || [ "$ARCH" == "riscv32" ]; then
  ARCH="riscv"
else
  printf "\n${T_YEL}  The architecture is unrecognized. Passing it verbatim to the cloud. [ arch = ${ARCH} ]${T_RESET}\n\n"
fi

# Find the box checksum.
if [ -f "$FILEPATH.sha256" ]; then

  # Read the hash in from the checksum file.
  HASH="$(tail -1 "$FILEPATH.sha256" | awk -F' ' '{print $1}')"

else

  # Generate a hash using the box file.
  HASH="$(sha256sum "$FILEPATH" | awk -F' ' '{print $1}')"

fi

# Verify the values have been parsed properly.
if [ "$ORG" == "" ]; then
  printf "\n${T_RED}  The organization couldn't be parsed from the file name. Exiting.${T_RESET}\n\n"
  exit 1
fi

if [ "$BOX" == "" ]; then
  printf "\n${T_RED}  The box name couldn't be parsed from the file name. Exiting.${T_RESET}\n\n"
  exit 1
fi

if [ "$PROVIDER" == "" ]; then
  printf "\n${T_RED}  The provider couldn't be parsed from the file name. Exiting.${T_RESET}\n\n"
  exit 1
fi

if [ "$ARCH" == "" ]; then
  printf "\n${T_RED}  The architecture couldn't be parsed from the file name. Exiting.${T_RESET}\n\n"
  exit 1
fi

if [ "$VERSION" == "" ]; then
  printf "\n${T_RED}  The version couldn't be parsed from the file name. Exiting.${T_RESET}\n\n"
  exit 1
fi

# Generate a hash using the box file if value is invalid.
if [ "$HASH" == "" ] || [ "$(echo "$HASH" | wc -c)" != 65 ]; then
  HASH="$(sha256sum "$FILEPATH" | awk -F' ' '{print $1}')"
fi

# If the hash is still invalid, then we report an error and exit.
if [ "$(echo "$HASH" | wc -c)" != 65 ]; then
  printf "\n${T_RED}  The hash couldn't be calculated properly. Exiting.${T_RESET}\n\n"
  exit 1
fi

retry() {
  local COUNT=1
  local DELAY=0
  local RESULT=0
  while [[ "${COUNT}" -le 10 ]]; do
    [[ "${RESULT}" -ne 0 ]] && {
      # printf "  %s ${T_BYEL}failed.${T_RESET}... retrying ${COUNT} of 10.\n" "${*}"
      printf "${T_BYEL}  Attempt ${COUNT} of 10 failed.${T_RESET}\n"
    }
    "${@}" && { RESULT=0 && break; } || RESULT="${?}"
    COUNT="$((COUNT + 1))"

    # Increase the delay with each iteration.
    DELAY="$((DELAY + 4))"
    sleep $DELAY
  done

  [[ "${COUNT}" -gt 10 ]] && {
    printf "${T_BYEL}  The command failed 10 times.${T_RESET} [ $ORG $BOX $PROVIDER $ARCH $VERSION  / RECURSION = $RECURSION ]${T_RESET}\n"
    sleep 60 ; exec "$0" "$FILEPATH" $RECURSION
    exit $?
  }

  return "${RESULT}"
}

function upload_box() {

  if [[ "${ORG}" =~ ^(generic(-x64)?|roboxes(-x64)?|lavabit|lineage|lineageos)$ ]] && [ "$ARCH" == "amd64" ]; then
    DEFAULT_ARCH="true"
  elif [[ "${ORG}" =~ ^(generic-x32|roboxes-x32)$ ]] && [ "$ARCH" == "i386" ]; then
    DEFAULT_ARCH="true"
  elif [[ "${ORG}" =~ ^(generic-a64|roboxes-a64)$ ]] && [ "$ARCH" == "arm64" ]; then
    DEFAULT_ARCH="true"
  elif [[ "${ORG}" =~ ^(generic-a32|roboxes-a32)$ ]] && [ "$ARCH" == "arm" ]; then
    DEFAULT_ARCH="true"
  elif [[ "${ORG}" =~ ^(generic-p64|roboxes-p64)$ ]] && [ "$ARCH" == "ppc64" ]; then
    DEFAULT_ARCH="true"
  elif [[ "${ORG}" =~ ^(generic-p64|roboxes-p64)$ ]] && [ "$ARCH" == "ppc64le" ]; then
    DEFAULT_ARCH="true"
  elif [[ "${ORG}" =~ ^(generic-m64|roboxes-m64)$ ]] && [ "$ARCH" == "mips64" ]; then
    DEFAULT_ARCH="true"
  elif [[ "${ORG}" =~ ^(generic-m64|roboxes-m64)$ ]] && [ "$ARCH" == "mips64le" ]; then
    DEFAULT_ARCH="true"
  fi

  UPLOAD_FILE_WRITEOUT="\nFILE: $FILENAME\nREPO: $ORG/$BOX\nCODE: %{http_code}\nIP: %{remote_ip}\nBYTES: %{size_upload}\nRATE: %{speed_upload}\nTOTAL TIME: %{time_total}\n%{onerror}ERROR: %{errormsg}\n"
  UPLOAD_CALLBACK_WRITEOUT="%{onerror}FILE: $FILENAME\nREPO: $ORG/$BOX\nCODE: %{http_code}\nIP: %{remote_ip}\nBYTES: %{size_upload}\nRATE: %{speed_upload}\nTOTAL TIME: %{time_total}\nERROR: %{errormsg}\n"
  
  # Detect older versions of cURL and avoid using the unsupported write out macros.
  if [ "$(${CURL} -so /dev/null --write-out "%{onerror}" https://mirrors.lavabit.com 2>&1)" ] || \
   [ "$(${CURL} -so /dev/null --write-out "%{errormsg}" https://mirrors.lavabit.com 2>&1)" ]; then
    UPLOAD_FILE_WRITEOUT="\nFILE: $FILENAME\nREPO: $ORG/$BOX\nCODE: %{http_code}\nIP: %{remote_ip}\nBYTES: %{size_upload}\nRATE: %{speed_upload}\nTOTAL TIME: %{time_total}\n"
    UPLOAD_CALLBACK_WRITEOUT=""
  fi

  # Checks whether the version exists already, and creates it if necessary.
  [ "`${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 180 --request HEAD --head --fail \
    --output /dev/null --write-out "%{http_code}" \
    "https://${VAGRANTPATH}/api/v2/box/$ORG/$BOX/version/$VERSION"`" != "200" ] || \
  [ "`${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 180 --request GET \
    "https://${VAGRANTPATH}/api/v2/box/$ORG/$BOX/version/$VERSION" | \
    jq -e -r ' (.version)? // (.success)? '`" != "$VERSION" ] && \
  { ${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 180 --request POST --fail \
     --output /dev/null --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"version\":{\"version\":\"${VERSION}\",\"description\":\"A build environment for use in cross platform development.\"}}" \
    "https://${VAGRANTPATH}/api/v2/box/$ORG/$BOX/versions" && sleep 4 || \
    { 
      printf "${T_BYEL}  Version creation failed. [ $ORG $BOX $PROVIDER $ARCH $VERSION  / RECURSION = $RECURSION ]${T_RESET}\n"
      sleep 20 ; exec "$0" "$FILEPATH" $RECURSION
      exit $?
    } 
  }

 # This checks whether provider/arch exists for this box, and if so, deletes it. 
  [ "`${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 180 --request HEAD --head --fail \
    --output /dev/null --write-out "%{http_code}" \
    "https://${VAGRANTPATH}/api/v2/box/$ORG/$BOX/version/$VERSION/provider/$PROVIDER/$ARCH"`" == "200" ] || \
  [ "`${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 180 --request GET \
    "https://${VAGRANTPATH}/api/v2/box/$ORG/$BOX/version/$VERSION/provider/$PROVIDER/$ARCH" | \
    jq -e -r ' (.name)? // (.success)? '`" != "false" ] && \
  { retry ${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 180 --request DELETE --fail \
  --output /dev/null --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  "https://${VAGRANTPATH}/api/v2/box/$ORG/$BOX/version/$VERSION/provider/${PROVIDER}/${ARCH}" && sleep 4 || \
    { 
      printf "${T_BYEL}  Provider delete failed. [ $ORG $BOX $PROVIDER $ARCH $VERSION / RECURSION = $RECURSION ]${T_RESET}\n"
      sleep 20 ; exec "$0" "$FILEPATH" $RECURSION
      exit $?
    } 
  }

  # Create the provider/arch.
  retry ${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 180 --request POST --fail \
    --output /dev/null --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"provider\":{ \"name\":\"$PROVIDER\",\"checksum\":\"$HASH\",\"architecture\":\"$ARCH\",\"default_architecture\":\"$DEFAULT_ARCH\",\"checksum_type\":\"SHA256\"}}" \
    "https://${VAGRANTPATH}/api/v2/box/$ORG/$BOX/version/$VERSION/providers" && sleep 4 || \
  { 
    printf "${T_BYEL}  Provider creation failed. [ $ORG $BOX $PROVIDER $ARCH $VERSION / RECURSION = $RECURSION ]${T_RESET}\n"
    sleep 20 ; exec "$0" "$FILEPATH" $RECURSION
    exit $?
  }

  # Request a direct upload URL.
  UPLOAD_RESPONSE=$( ${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 180 -request GET --fail \
    --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    "https://${VAGRANTPATH}/api/v2/box/$ORG/$BOX/version/$VERSION/provider/$PROVIDER/$ARCH/upload/direct" )

  UPLOAD_PATH="$(echo "$UPLOAD_RESPONSE" | jq -r .upload_path)"
  UPLOAD_CALLBACK="$(echo "$UPLOAD_RESPONSE" | jq -r .callback)"

  if [ "$UPLOAD_PATH" == "" ] || [ "$UPLOAD_PATH" == "echo" ] || [ "$UPLOAD_CALLBACK" == "" ] || [ "$UPLOAD_CALLBACK" == "echo" ]; then
    printf "\n${T_BYEL}  The $FILENAME file failed to upload. [ $ORG $BOX $PROVIDER $ARCH $VERSION / RECURSION = $RECURSION ]${T_RESET}\n\n"
    sleep 20 ; exec "$0" "$FILEPATH" $RECURSION
    exit $?
  fi

  # If we move too quickly, the cloud will sometimes return an error. Waiting seems to reduce the error/failure rate.
  sleep 4

  retry ${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 7200 --request PUT --fail \
    --speed-time 60 --speed-limit 1024 --expect100-timeout 7200 \
    --write-out "$UPLOAD_FILE_WRITEOUT" \
    --header "Connection: keep-alive" --upload-file "$FILEPATH" "$UPLOAD_PATH"

  RESULT=$?
  [ "$RESULT" != "0" ] && { 
    printf "\n${T_BYEL}  The $FILENAME file failed to upload. [ $ORG $BOX $PROVIDER $ARCH $VERSION / RECURSION = $RECURSION ]${T_RESET}\n\n" 
    sleep 20 ; exec "$0" "$FILEPATH" $RECURSION
    exit $?
  }
    
  # Sleep before trying the callback URL, so the cloud can finish digestion.
  sleep 4

  # Submit the callback twice. hopefully this will reduce the number of boxes without valid download URLs.
  ${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 180 --request PUT --fail \
    --output "/dev/null" --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    --write-out "$UPLOAD_CALLBACK_WRITEOUT" \
    "$UPLOAD_CALLBACK" || \
  { sleep 16 ; ${CURL} --tlsv1.2 --silent --retry 4 --retry-delay 2 --max-time 180 --request PUT --fail \
    --output "/dev/null" --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    --write-out "$UPLOAD_CALLBACK_WRITEOUT" \
    "$UPLOAD_CALLBACK" ; } || \
  { 
    printf "${T_BYEL}  Upload failed. The callback returned an error. [ $ORG $BOX $PROVIDER $ARCH $VERSION / RECURSION = $RECURSION ]${T_RESET}\n"
    sleep 20 ; exec "$0" "$FILEPATH" $RECURSION
    exit $?
  }
  
#   # # Add a short pause, with the duration determined by the size of the file uploaded.
#   # PAUSE="`du -b $FILEPATH | awk -F' ' '{print $1}'`"
#   # bash -c "usleep $(($PAUSE/20))"

}

upload_box

if [ "$ORG" == "generic" ] && [ "$ARCH" == "amd64" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-x64"
  upload_box
  ORG="generic"
elif [ "$ORG" == "generic" ] && [ "$ARCH" == "i386" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-x32"
  upload_box
  ORG="generic"
elif [ "$ORG" == "generic" ] && [ "$ARCH" == "arm64" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-a64"
  upload_box
  ORG="generic"
elif [ "$ORG" == "generic" ] && [ "$ARCH" == "arm" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-a32"
  upload_box
  ORG="generic"
elif [ "$ORG" == "generic" ] && [ "$ARCH" == "mips64le" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-m64"
  upload_box
  ORG="generic"
elif [ "$ORG" == "generic" ] && [ "$ARCH" == "mips" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-m32"
  upload_box
  ORG="generic"
elif [ "$ORG" == "generic" ] && [ "$ARCH" == "ppc64le" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-p64"
  upload_box
  ORG="generic"
elif [ "$ORG" == "generic" ] && [ "$ARCH" == "ppc" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-p32"
  upload_box
  ORG="generic"
elif [ "$ORG" == "generic" ] && [ "$ARCH" == "riscv64" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-r64"
  upload_box
  ORG="generic"
elif [ "$ORG" == "generic" ] && [ "$ARCH" == "riscv" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-r32"
  upload_box
  ORG="generic"
elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "amd64" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-x64"
  upload_box
  ORG="roboxes"
elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "i386" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-x32"
  upload_box
  ORG="roboxes"
elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "arm64" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-a64"
  upload_box
  ORG="roboxes"
elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "arm" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-a32"
  upload_box
  ORG="roboxes"
elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "mips64le" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-m64"
  upload_box
  ORG="roboxes"
elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "mips" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-m32"
  upload_box
  ORG="roboxes"
elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "ppc64le" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-p64"
  upload_box
  ORG="roboxes"
elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "ppc" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-p32"
  upload_box
  ORG="roboxes"
elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "riscv64" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-r64"
  upload_box
  ORG="roboxes"
elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "riscv" ]; then
  sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-r32"
  upload_box
  ORG="roboxes"
fi

if [ "$PROVIDER" == "libvirt" ]; then
  sleep 8
  PROVIDER="qemu"
  upload_box

  if [ "$ORG" == "generic" ] && [ "$ARCH" == "amd64" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-x64"
    upload_box
  elif [ "$ORG" == "generic" ] && [ "$ARCH" == "i386" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-x32"
    upload_box
  elif [ "$ORG" == "generic" ] && [ "$ARCH" == "arm64" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-a64"
    upload_box
  elif [ "$ORG" == "generic" ] && [ "$ARCH" == "arm" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-a32"
    upload_box
  elif [ "$ORG" == "generic" ] && [ "$ARCH" == "mips64le" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-m64"
    upload_box
  elif [ "$ORG" == "generic" ] && [ "$ARCH" == "mips" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-m32"
    upload_box
  elif [ "$ORG" == "generic" ] && [ "$ARCH" == "ppc64le" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-p64"
    upload_box
  elif [ "$ORG" == "generic" ] && [ "$ARCH" == "ppc" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-p32"
    upload_box
  elif [ "$ORG" == "generic" ] && [ "$ARCH" == "riscv64" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-r64"
    upload_box
  elif [ "$ORG" == "generic" ] && [ "$ARCH" == "riscv" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="generic-r32"
    upload_box
  elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "amd64" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-x64"
    upload_box
  elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "i386" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-x32"
    upload_box
  elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "arm64" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-a64"
    upload_box
  elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "arm" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-a32"
    upload_box
  elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "mips64le" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-m64"
    upload_box
  elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "mips" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-m32"
    upload_box
  elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "ppc64le" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-p64"
    upload_box
  elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "ppc" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-p32"
    upload_box
  elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "riscv64" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-r64"
    upload_box
  elif [ "$ORG" == "roboxes" ] && [ "$ARCH" == "riscv" ]; then
    sleep 8 ; VAGRANTPATH="vagrantcloud.com" ; ORG="roboxes-r32"
    upload_box
  fi
fi

