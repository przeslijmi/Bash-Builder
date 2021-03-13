#!/bin/bash
#
# Builder bash App by @przeslijmi.
#
# @author  przeslijmi@gmail.com
# @version v2.3.0
#
# # Usage
# After filling up settings in build.sh.config section call in bash:
#
# ```
# bash build.sh -help
# ```
#
# Function to show all help.
function showHelp() {

  echo "";
  echo "=============== Show Help ==> started"
  echo "";

  echo "This is @przeslijmi Bash Builder v2.3.0"
  echo "";

  echo "The following operations can be performed:"
  echo "  -s, --sniff, --sniffs, --sniffing   Start PHP Code Sniffer"
  echo "  -t, --test, --tests, --testing      Start PHP Unit Testing"
  echo "  -m, --sami                          Start PHP Sami Documentation generation"
  echo "  -z, --zip                           ZIP code, sami docs and code coverage"
  echo "  -g, --git                           Send to git repo (and add tags basing on composer.json)"
  echo "  -st, -stm, -stmz, -stmzg            Joined commands from above"
  echo "  -a, --all                           Execute all commands (equal to stmzg)"
  echo "  -h, -v, --help                      Show this screen"
  echo "  --gitInfoExclude \"default\"          Replace git/info/exlude with given contents"
  echo "";

  echo "The following extra params can be used:"
  echo "  --sniffUri    Alternative URI settings for Sniffing"
  echo "  --phputFilter Filter param for PHP Unit Testing"
  echo "  --vendor      Default \"yes\". Set to \"no\" if app is not in vendor."
  echo "";

  echo "<============== Show Help <== finished"
  echo "";
}

# Function to perform code sniffing.
function callPhpCodeSniffing() {

  # Inform.
  echo "";
  echo "=============== PHPCodeSniffing ==> started"
  echo "==";

  ## Find uri.
  if [ "$PARAM_SNIFF_URI" = false ]
  then
    URI="$DIR/tests $DIR/src";
  else
    URI=$DIR/$PARAM_SNIFF_URI;
  fi

  ## Info on command.
  echo "== INFO ON COMMANDS USED";
  echo "cd" $DIR
  echo $PHPCS_PATH --standard=phpcs.xml --report-file=.phpcs.txt $URI;
  echo "== END INFO";
  echo "==";

  # Call PHP code sniffer.
  php $PHPCS_PATH --standard=$DIR/phpcs.xml --report-file=$DIR/.phpcs.txt $URI

  # Check if there were any errors.
  PHPCS_REPORT_SIZE=$(stat -c%s "$DIR/.phpcs.txt")

  # If there were - inform about it.
  if [ $PHPCS_REPORT_SIZE -gt 2 ]
  then
    echo "Errors found in PHPCS ($PHPCS_REPORT_SIZE) "
    cat $DIR/.phpcs.txt
    exit 1
  fi

  # Delete report file.
  unlink $DIR/.phpcs.txt

  # Inform.
  echo "";
  echo "<============== PHPCodeSniffing <== finished"
  echo "";
}

# Function to perform PHP Unit Tests.
function callPhpUnitTesting() {

  # Inform.
  echo "";
  echo "=============== PHPUnit ==> started"
  echo "";

  ## Find filter param.
  if [ "$PARAM_PHPUNIT_FILTER" != "" ]
  then
    EXTRA_PARAMS=" --filter '$PARAM_PHPUNIT_FILTER'";
  fi

  ## Set vendor param to default value (if missing).
  if [ "$PARAM_VENDOR" != "no" ]
  then
    PARAM_VENDOR="yes";
  fi

  ## Info on command.
  echo "== INFO ON COMMANDS USED";

  if [ "$PARAM_VENDOR" = "yes" ]
  then
    echo "cd ../../../"
  fi

  echo "php $PHPUNITPHAR_PATH -c $DIR/phpunit.xml --testSuite TestSuite $EXTRA_PARAMS"
  echo "== END INFO";
  echo "==";

  # Change dir to app top.
  if [ "$PARAM_VENDOR" = "yes" ]
  then
    cd "../../../"
  fi

  # Call PHP Unit.
  php $PHPUNITPHAR_PATH -c "$DIR/phpunit.xml" $EXTRA_PARAMS
  exit 1;

  # Back to working DIR.
  cd $DIR;

  # Show coverage report.
  php -r '$c = file_get_contents(".cc/coverage.txt"); $c = substr($c, strpos($c, "Summary")+8); $c = substr($c, 0, strpos($c, "\\")); echo $c;'

  # Show test list.
  cat $DIR/.cc/testdox.txt

  # Delete cache file.
  unlink $DIR/.phpunit.result.cache

  # Inform.
  echo "";
  echo "<============== PHPUnit <== finished"
  echo "";
}

# Function to perform generation of SAMI documentation.
function callSamiGeneration() {

  # Start SAMI.
  echo "";
  echo "=============== SAMI ==> started"
  echo "";

  # Change to dir in which sami has to be generated.
  mkdir $DIR/.sami/
  cd $DIR/.sami/
  php $SAMIPHAR_PATH update ../sami.php

  # Inform.
  echo "";
  echo "<============== SAMI <== finished"
  echo "";
}

# Function to perform GIT commit, tags and push operation.
function callGitPush() {

  # Start SAMI.
  echo "";
  echo "=============== GIT ==> started"
  echo "";
  echo "with version: " $VERSION;
  echo "";

  # Check version.
  if [ $(git tag -l "$VERSION") ]; then

    # Inform.
    echo "This version has already ben put to GIT."

    # Inform.
    echo "";
    echo "<============== GIT === ABORTED !!!!"
    echo ""

    return 1;
  fi

  # Call git operations.
  git add .
  git commit -m "$VERSION"
  git push
  git tag -a $VERSION -m "$VERSION"
  git push --tags
  git status

  # Inform.
  echo "";
  echo "<============== GIT <== finished"
  echo ""
}

# Function to ZIP files into archives.
function callZipping() {

  # Start SAMI.
  echo "";
  echo "=============== ZIT ==> started"
  echo "";

  # Lvd.
  ZIP_CODE_PATH="${DOCS_PATH}${VENDOR}-${APP}-${VERSION}-code.zip"
  ZIP_SAMI_PATH="${DOCS_PATH}${VENDOR}-${APP}-${VERSION}-sami.zip"
  ZIP_CODECOV_PATH="${DOCS_PATH}${VENDOR}-${APP}-${VERSION}-codecov.zip"

  # Pack code.
  echo "Creating code archive at" $ZIP_CODE_PATH
  printf "${COLOR_GREEN}"
  cd $DIR
  "$ZIP_PACKER_PATH" "a" "$ZIP_CODE_PATH" "*" "-x!.git/" "-x!.cc/" "-x!.sami/" "-x!build.sh" "-x!.phpunit.txt" "-x!phpcs.txt" "-x!.phpunit.result.cache"
  printf "${COLOR_NONE}\n\n"

  # Pack sami.
  echo "Creating sami archive at " $ZIP_CODE_PATH

  printf "${COLOR_GREEN}"
  cd $DIR/.sami/build/
  "$ZIP_PACKER_PATH"  "a" "$ZIP_SAMI_PATH" "*"
  printf "${COLOR_NONE}\n\n"

  # Delete sami sources.
  rm -r $DIR/.sami/

  # Pack code coverage.
  echo "Creating codecov archive at " $ZIP_CODE_PATH
  printf "${COLOR_GREEN}"
  cd $DIR/.cc/
  "$ZIP_PACKER_PATH" "a" "$ZIP_CODECOV_PATH" "*"
  printf "${COLOR_NONE}\n\n"

  # Delete sami sources.
  rm -r $DIR/.cc/

  # Back to working DIR.
  cd $DIR

  # Inform.
  echo "";
  echo "<============== ZIP <== finished"
  echo ""
}

# Function that overwrites git/info/exlude file
function callOverwriteFileGitInfo() {

  # Start OVERWRITE.
  echo "";
  echo "=============== OVERWRITE GIT/INFO/EXCLUDE ==> started"
  echo "";

  # Lvd.
  SOURCE_FILE_PATH="${THISDIR}/resources/git-info-exclude.${PARAM_GIT_INFO_EXCLUDE}.txt"
  DESTINATION_FILE_PATH="${DIR}/.git/info/exclude"

  # Inform.
  echo "SOURCE_FILE_PATH: ${SOURCE_FILE_PATH}";
  echo "DESTINATION_FILE_PATH: ${DESTINATION_FILE_PATH}";

  # Copy.
  cp -R "$SOURCE_FILE_PATH" "$DESTINATION_FILE_PATH"

  # Inform.
  echo "";
  echo "<============== OVERWRITE GIT/INFO/EXCLUDE <== finished"
  echo ""
}

# Internal variables.
PARAM_SHOW_HELP=false
PARAM_CALL_SNIFFING=false
PARAM_CALL_TESTS=false
PARAM_CALL_SAMI=false
PARAM_CALL_ZIP=false
PARAM_CALL_GIT=false
PARAM_GIT_INFO_EXCLUDE=false
PARAM_SNIFF_URI=false
PARAM_PHPUNIT_FILTER=""

# Find params.
while [ "$1" != "" ]; do
  case $1 in
    -s | --sniff | --sniffs | --sniffing ) shift
                                           PARAM_CALL_SNIFFING=true
                                           ;;
    -t | --test | --tests | --testing )    PARAM_CALL_TESTS=true
                                           ;;
    -m | --sami )                          PARAM_CALL_SAMI=true
                                           ;;
    -z | --zip )                           PARAM_CALL_ZIP=true
                                           ;;
    -g | --git )                           PARAM_CALL_GIT=true
                                           ;;
    -st )                                  PARAM_CALL_SNIFFING=true
                                           PARAM_CALL_TESTS=true
                                           ;;
    -stm )                                 PARAM_CALL_SNIFFING=true
                                           PARAM_CALL_TESTS=true
                                           PARAM_CALL_SAMI=true
                                           ;;
    -stmz )                                PARAM_CALL_SNIFFING=true
                                           PARAM_CALL_TESTS=true
                                           PARAM_CALL_SAMI=true
                                           PARAM_CALL_ZIP=true
                                           ;;
    -a | --all | -stmzg )                  PARAM_CALL_SNIFFING=true
                                           PARAM_CALL_TESTS=true
                                           PARAM_CALL_SAMI=true
                                           PARAM_CALL_ZIP=true
                                           PARAM_CALL_GIT=true
                                           ;;
    --gitInfoExclude )                     PARAM_GIT_INFO_EXCLUDE=$2
                                           ;;
    --sniffUri )                           PARAM_SNIFF_URI=$2
                                           ;;
    --phputFilter )                        PARAM_PHPUNIT_FILTER=$2
                                           ;;
    --vendor )                             PARAM_VENDOR=$2
                                           ;;
    * )                                    PARAM_SHOW_HELP=true
                                           ;;
  esac
  shift
done

# If none parameters given.
if [ "$PARAM_CALL_SNIFFING" = false ] && [ "$PARAM_CALL_TESTS" = false ] && [ "$PARAM_CALL_SAMI" = false ] && [ "$PARAM_CALL_ZIP" = false ] && [ "$PARAM_CALL_GIT" = false ] && [ "$PARAM_GIT_INFO_EXCLUDE" = false ] ; then
  PARAM_SHOW_HELP=true
else
  PARAM_SHOW_HELP=false
fi

# Find other variables.
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DIR=$PWD
VENDOR=$(basename $(dirname $DIR))
APP=$(basename $DIR)
VERSION=`php -r 'echo json_decode(file_get_contents("composer.json"))->version;'`
COLOR_GREEN='\033[0;32m'
COLOR_NONE='\033[0m'

# Include configs
. ${THISDIR}/build.sh.config

# Make sure to move to dir in which this bash is located
cd $DIR

# Call apps.
if [ "$PARAM_SHOW_HELP" = true ] ; then
  showHelp
fi
if [ "$PARAM_CALL_SNIFFING" = true ] ; then
  callPhpCodeSniffing
fi
if [ "$PARAM_CALL_TESTS" = true ] ; then
  callPhpUnitTesting
fi
if [ "$PARAM_CALL_SAMI" = true ] ; then
  callSamiGeneration
fi
if [ "$PARAM_CALL_ZIP" = true ] ; then
  callZipping
fi
if [ "$PARAM_CALL_GIT" = true ] ; then
  callGitPush
fi
if [ "$PARAM_GIT_INFO_EXCLUDE" != false ] ; then
  callOverwriteFileGitInfo
fi
