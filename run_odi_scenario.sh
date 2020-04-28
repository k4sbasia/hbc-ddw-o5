# Vimal Purohit 07/24/2014 -- to runs jobs for ODI
export ODI_JAVA_HOME=/home/cognos/software/jdk1.6.0_38-64bit
export ODI_HOME=/oracle/Middleware/Oracle_ODI1/oracledi/agent
SCENARIO_NAME=$1
SCENARIO_VER=$2
CONTEXT=$3
ODIAGENT=$4

if [ "$1" == "" ] 
then
  echo "Scenario Name is not provided..."
  echo "Syntext : Parameter list <scenario Name> <Scenario Version> <context> <odiagent> "
  exit 1
fi 

if [ "$2" == "" ] 
then
  echo "Scenario Version is not provided.."
  echo "Syntext : Parameter list <scenario Name> <Scenario Version> <context> <odiagent> "
  exit 1
fi 


if [ "$3" == "" ] 
then
   echo "Default CONTEXT value is being used PROD  "
   CONTEXT=PROD
fi 

if [ "$4" == "" ] 
then
   echo "Default AGENT value is being used SDW  "
   ODIAGENT=http://sd1pdw01vl.SAKSDIRECT.COM:20915/oraclediagent
fi 
#/oracle/Middleware/Oracle_ODI1/oracledi/agent/bin/startscen.sh $SCENARIO_NAME $SCENARIO_VER $CONTEXT 5 -SESSION_NAME=$SCENARIO_NAME -NAME=$ODIAGENT
/oracle/Middleware/Oracle_ODI1/oracledi/agent/bin/startscen.sh $SCENARIO_NAME $SCENARIO_VER $CONTEXT 5 -SESSION_NAME=$SCENARIO_NAME -AGENT_URL=$ODIAGENT

exit $?