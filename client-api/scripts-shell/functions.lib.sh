# functions.lib.sh

# mapping the project name to database name
# The project name is used as a directory name to output data and as a workspace on GeoServer
getDBName(){
  PROJECT_NAME=$1

  case $PROJECT_NAME in "deter-amz") echo "DETER-B";;
  "deter-cerrado") echo "deter_cerrado";;
  "deter-cerrado-nb") echo "deter_cerrado_nb";;
  "dashboard-fires") echo "fires_dashboard";;
  "deter-terrama-mt") echo "deter_terrama_mt";;
  "deter-nf") echo "deter_amazonia_nf";;
  "deter-pantanal") echo "deter_pantanal_nb";;
  esac
}

# mapping the project name to production database name
# it's used to keep the project name as identifier on routines
getProductionDBName(){
  PROJECT_NAME=$1

  case $PROJECT_NAME in "deter-nf") echo "DeterAM_NF";;
  "deter-pantanal") echo "DeterPantanal_2023";;
  esac
}