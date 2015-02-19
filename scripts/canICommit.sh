#!/bin/bash
# init ######################################
CURRENTPATH=$(pwd)
CARTRIDGENAME=$2
EXPECTED_ARGS=2
RECEIVED_ARGS=$#
#############################################
function CHECK_PARAMETERS (){
    if [ $RECEIVED_ARGS -ne $EXPECTED_ARGS ]
    then
          echo "!! incorrect number of parameters: expected $EXPECTED_ARGS got $RECEIVED_ARGS!!";
      USAGE
      return 1
    else if [ -z $CARTRIDGENAME ] ; then 
                echo "!! please set a CartridgeName !!"
                USAGE
                return 1
             fi
    fi
    return 0
}
#############################################
function MAKE_MAKEFILE (){
    echo "### make makefile ### $CARTRIDGENAME"
    cd $EPAGES_CARTRIDGES/DE_EPAGES/$CARTRIDGENAME
    $PERL Makefile.PL
    echo "ok"
}
#############################################
function MAKE_MODUL_TEST (){
    echo "### Modultests for Cartridge: $CARTRIDGENAME ###"
    $PERL $EPAGES_CARTRIDGES/DE_EPAGES/Installer/Scripts/runTests.pl -storename Store -cartridge DE_EPAGES::$CARTRIDGENAME
    echo "ok"

}
#############################################
function MAKE_REGRESSION_TEST (){
    echo "### Regressionstests (for Store) ###"
    cd $EPAGES_CARTRIDGES/DE_EPAGES/Test/
    $PERL Makefile.PL
    make test STORE=Store
    echo "ok"
}
#############################################
function MAKE_PERL_CRITIC (){
    echo "### Perl::Critic for $CARTRIDGENAME ###"
    CRITICMODE=$1
    PERLCRITICCONF="perlcritic.conf"
    if [ $CRITICMODE == "hard" ] ; then
        PERLCRITICCONF="perlcritic_hard.conf"  
    fi
    $PERL $EPAGES_CARTRIDGES/DE_EPAGES/Core/Scripts/critic.pl -profile $EPAGES_CARTRIDGES/DE_EPAGES/Core/Scripts/$PERLCRITICCONF $EPAGES_CARTRIDGES/DE_EPAGES/$CARTRIDGENAME
}
#############################################
function CHECK_FOR_UNUSED_FILES (){
    echo "Check for unused files in $CARTRIDGENAME"
    CHECK_FOR_UNUSED_FILES_REGEX='^(ok |1\.\.)'
    $PERL $EPAGES_CARTRIDGES/DE_EPAGES/Presentation/Scripts/checkUnusedFiles.pl -storename Store | grep -v -E "$CHECK_FOR_UNUSED_FILES_REGEX"
    echo "ok"
}
#############################################
function USAGE (){

    echo "normal critc . canICommit -tucr CartridgeName "
    echo "hard critc -> . canICommit -tuhr CartridgeName "
    echo "-t = make test"
    echo "-u = unusedFiles"
    echo "-c = critc normal"
    echo "-h = critc hard"
    echo "-r = QA regression tests"
    echo "****************************************"
    echo " hint: write result this to epages/eproot/Shared/Log/CartridgeName_canICommit.log "
}
############################################
function processTests () {
   unset optname
  while getopts "tuchr:" optname
    do
      case "$optname" in
        "t")
          MAKE_MODUL_TEST
          ;;
        "u")
          CHECK_FOR_UNUSED_FILES
          ;;
        "c")
          MAKE_PERL_CRITIC "normal"
          ;;
        "h")
          MAKE_PERL_CRITIC "hard"
          ;;
        "r")
          MAKE_REGRESSION_TEST
          ;;
        "?")
          USAGE
          ;;
        ":")
          USAGE
          ;;
        *)
        # Should not occur
          echo "Unknown error while processing options"
          ;;
      esac
    done
  return $OPTIND
}

exec > >(tee $EPAGES_LOG"/"$CARTRIDGENAME"_canICommit.log")
exec 2>&1
# start #####################################
    CHECK_PARAMETERS
    retval=$?
    if [ $retval == 1 ]
    then
        return 1
    fi
    MAKE_MAKEFILE
    processTests "$@"
# clean up ######################################
OPTIND=1
echo "go back to: $CURRENTPATH" 
cd $CURRENTPATH
echo done