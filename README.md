## DETER-B sync data

The services implemented here are automate the aquisition and transformation tasks over data from remote database, the production DETER-B database located at INPE/CRA, and export this data to files in JSON and Shapefile formats and provide them to webapp clients. It's compound by one PHP client, named here by deter-b-sync-data-client, described in the [README file](https://github.com/Terrabrasilis/terrabrasilis-deter-sync-amz/tree/master/client-api/php-client), loading data from an API service running into a server at INPE/CRA. The intersections between raw data and locals of interest are processed in server where [service API](https://gitlab.dpi.inpe.br/andre.carvalho/deterb_amz_api/) is running.

For copy and make the intersection of the DETER Cerrado data to new database version of Postgresql inside the Docker cluster, we use one service based in an exist Docker Image and just change the configuration file to access the new SGDB. To change database configurations we create a new directory in the docker manager file system, copy the config files from oldest version of service and change the db.cfg file. The Docker Image cited above is based in code implemented in python-microservices/cerrado-deter and python-microservices/cerrado-deter-env inside in this repository.

Another component, named here by Scripts, is implemented with some shell scripts to reading layers configured in one GeoServer. Basicaly, this scripts call the WFS service via CURL, for each layer, downloading the output file in JSON format. The GeoServer provided layers was configured using the SQL View resources and providing that layers over WFS protocol. One those scripts, named generateSHP.sh, use the pgsql2shp tool to do directly access the Postgresql databases and export the main tables to Shapefiles.

## When it's runs

The default configuration runs daily, synchronized as follows:

- At 06:30 the deter-b-sync-data-client runs get data from source API;
- At 07:00 the deter-b-sync-data-client runs the status check and send result over email;
- At 07:00 changes release date to publish data, every friday.
- At 07:10 the Scripts export JSON files and Shapefiles;

## To change the synchronization time

Both the client API and Scripts allow configuration for cron jobs using a file named daily.cron. To change the synchronization time, edit the daily.cron and regenerate a Docker Image, [push it to the docker hub](https://gitlab.dpi.inpe.br/terrabrasilis/terrabrasilis/wikis/how-to-setup-docker-on-ubuntu#up-the-image-to-docker-hub) and do update in Portainer.

## Another configurations

This services reads parameters from the Docker Secrets to access controlled resources such as Postgresql and Geoserver. See that secrets in the stack yaml file.

## Deploy

These services runs into a Docker Swarm cluster and the configurations are described in [the yaml file for the stack](https://github.com/Terrabrasilis/docker-stacks/blob/master/deter-sync/data-service-auth.yaml).
