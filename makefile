#########################################################################
# 								Variables 								#
#########################################################################
DETACH_MODE=false#true - add "-d" flag on docker-compose up
NETWORK_NAME=#vps_docker_network - bridge, standart network

HOST=# root@192.168.88.55
PORT=22# 22
# HOST= PORT= make test
DOCKER_PROJECTS_FOLDER=docker-vps-project# docker-vps-project !!WARNING!! - this folder will be deleted at the beginning of the installation 
# HOST= PORT= DOCKER_PROJECTS_FOLDER= make install_nginx

SITE_NAME=# local.example.com

EMAIL_SSL=# example@gmail.com
STAGING=0# 0 - production letsencrypt 1 - test letsencrypt
# HOST= PORT= DOCKER_PROJECTS_FOLDER= SITE_NAME= EMAIL_SSL= STAGING=  make configurate-nginx_register-ssl
# HOST= PORT= DOCKER_PROJECTS_FOLDER= SITE_NAME= make configurate-nginx_test-site

CONTAINER_NAME=# my-site
PORT_CONTAINER=# 3000
# HOST= PORT= DOCKER_PROJECTS_FOLDER= SITE_NAME= CONTAINER_NAME= PORT_CONTAINER= make configurate-nginx_containered-web-site

REGISTRY_USER=registry-docker-user#registry-user 
REGISTRY_PASSWORD=#Jq981Hhq81hs9 
# HOST= PORT= SITE_NAME= CONTAINER_NAME=  make configurate-nginx_registry-hub

REDIRECT_URL=192.168.88.254#192.168.88.254
REDIRECT_PORT=80# 3000
# HOST= PORT= DOCKER_PROJECTS_FOLDER= SITE_NAME= CONTAINER_NAME= PORT_CONTAINER= make configurate-nginx_containered-web-site

# HOST= PORT= DOCKER_PROJECTS_FOLDER= SITE_NAME= make create_registry_hub

ifeq (${DETACH_MODE}, true)
DETACH=-d
else
DETACH=
endif

test:
ifdef HOST
ifdef PORT
	ssh ${HOST} -p ${PORT} 'sudo apt-get update'
else
	echo "PORT not defined"
endif	
else
	echo "HOST not defined"	
endif


#########################################################################
# 								Nginx	 								#
#########################################################################


# HOST= PORT= DOCKER_PROJECTS_FOLDER= make install_nginx
install_nginx:
ifdef HOST
ifdef PORT
ifdef DOCKER_PROJECTS_FOLDER
ifdef NETWORK_NAME
	ssh ${HOST} -p ${PORT} 'sudo rm -Rfv ${DOCKER_PROJECTS_FOLDER}'
	ssh ${HOST} -p ${PORT} 'mkdir ${DOCKER_PROJECTS_FOLDER}'
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER} && mkdir gateway'
	scp custom-docker-compose/gateway/docker-compose.yml ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway/docker-compose.yml
	scp custom-docker-compose/gateway/docker-compose.prod.yml ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway/docker-compose.prod.yml
	scp custom-docker-compose/gateway/.env ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway/.env
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && echo "NETWORK_NAME=${NETWORK_NAME}" >> .env'
	scp -r custom-docker-compose/gateway/upload/data ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway
	ssh ${HOST} -p ${PORT} 'sudo apt-get install dos2unix -y'
	ssh ${HOST} -p ${PORT} 'docker network create -d bridge ${NETWORK_NAME}'
else
	echo "NETWORK_NAME not defined"
endif
else
	echo "DOCKER_PROJECTS_FOLDER not defined"
endif	
else
	echo "PORT not defined"
endif	
else
	echo "HOST not defined"
endif

# HOST= PORT= SITE_NAME= EMAIL_SSL= STAGING= make configurate-nginx_register-ssl
configurate-nginx_register-ssl:
ifdef HOST
ifdef PORT
ifdef DOCKER_PROJECTS_FOLDER
ifdef SITE_NAME
ifdef EMAIL_SSL
ifdef STAGING
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose down --remove-orphans'
	scp custom-docker-compose/gateway/init-letsencrypt.sh ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway/init-letsencrypt.sh
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && sed -i 's/%sitename%/${SITE_NAME}/g' init-letsencrypt.sh'
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && sed -i 's/%emailssl%/${EMAIL_SSL}/g' init-letsencrypt.sh'
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && sed -i 's/%staging%/${STAGING}/g' init-letsencrypt.sh'
	
	scp custom-docker-compose/gateway/custom-config.d/preconfig_site.conf ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d/${SITE_NAME}.conf
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d && sed -i 's/%sitename%/${SITE_NAME}/g' ${SITE_NAME}.conf'
	
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && dos2unix init-letsencrypt.sh'
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && chmod +x init-letsencrypt.sh'
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && echo y|sudo ./init-letsencrypt.sh' || true

	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose down --remove-orphans'
	
	scp custom-docker-compose/gateway/custom-config.d/config_test-site.conf ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d/${SITE_NAME}.conf
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d && sed -i 's/%sitename%/${SITE_NAME}/g' ${SITE_NAME}.conf'
	
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build ${DETACH}'
else
	echo "STAGING not defined"
endif	
else
	echo "EMAIL_SSL not defined"
endif	
else
	echo "SITE_NAME not defined"
endif	
else
	echo "DOCKER_PROJECTS_FOLDER not defined"
endif	
else
	echo "PORT not defined"
endif	
else
	echo "HOST not defined"
endif

# HOST= PORT=22 SITE_NAME= make configurate-nginx_test-site
configurate-nginx_test-site:
ifdef HOST
ifdef PORT
ifdef DOCKER_PROJECTS_FOLDER
ifdef SITE_NAME
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose down --remove-orphans'
	
	scp custom-docker-compose/gateway/custom-config.d/config_test-site.conf ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d/${SITE_NAME}.conf
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d && sed -i 's/%sitename%/${SITE_NAME}/g' ${SITE_NAME}.conf'
	
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build ${DETACH}'
else
	echo "SITE_NAME not defined"
endif
else
	echo "DOCKER_PROJECTS_FOLDER not defined"
endif
else
	echo "PORT not defined"
endif
else
	echo "HOST not defined"
endif

# HOST= PORT=22 SITE_NAME= CONTAINER_NAME= PORT_CONTAINER= make configurate-nginx_redirect-web-site
configurate-nginx_redirect-web-site:
ifdef HOST
ifdef PORT
ifdef DOCKER_PROJECTS_FOLDER
ifdef SITE_NAME
ifdef CONTAINER_NAME
ifdef PORT_CONTAINER
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose down --remove-orphans'
	
	scp custom-docker-compose/gateway/custom-config.d/config_redirect.conf ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d/${SITE_NAME}.conf
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d && sed -i 's/%sitename%/${SITE_NAME}/g' ${SITE_NAME}.conf'
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d && sed -i 's/%redirecturl%/${REDIRECT_URL}/g' ${SITE_NAME}.conf'
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d && sed -i 's/%redirectport%/${REDIRECT_PORT}/g' ${SITE_NAME}.conf'
	
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build ${DETACH}'
else
	echo "PORT_CONTAINER not defined"
endif
else
	echo "CONTAINER_NAME not defined"
endif
else
	echo "SITE_NAME not defined"
endif
else
	echo "DOCKER_PROJECTS_FOLDER not defined"
endif
else
	echo "PORT not defined"
endif
else
	echo "HOST not defined"
endif

# HOST= PORT=22 SITE_NAME= CONTAINER_NAME= PORT_CONTAINER= make configurate-nginx_containered-web-site
configurate-nginx_containered-web-site:
ifdef HOST
ifdef PORT
ifdef DOCKER_PROJECTS_FOLDER
ifdef SITE_NAME
ifdef CONTAINER_NAME
ifdef PORT_CONTAINER
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose down --remove-orphans'
	
	scp custom-docker-compose/gateway/custom-config.d/config_site.conf ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d/${SITE_NAME}.conf
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d && sed -i 's/%sitename%/${SITE_NAME}/g' ${SITE_NAME}.conf'
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d && sed -i 's/%containername%/${CONTAINER_NAME}/g' ${SITE_NAME}.conf'
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d && sed -i 's/%portcontainer%/${PORT_CONTAINER}/g' ${SITE_NAME}.conf'
	
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build ${DETACH}'
else
	echo "PORT_CONTAINER not defined"
endif
else
	echo "CONTAINER_NAME not defined"
endif
else
	echo "SITE_NAME not defined"
endif
else
	echo "DOCKER_PROJECTS_FOLDER not defined"
endif
else
	echo "PORT not defined"
endif
else
	echo "HOST not defined"
endif

# HOST= PORT= SITE_NAME= CONTAINER_NAME= REGISTRY_USER= REGISTRY_PASSWORD= make configurate-nginx_registry-hub
configurate-nginx_registry-hub:
ifdef HOST
ifdef PORT
ifdef DOCKER_PROJECTS_FOLDER
ifdef SITE_NAME
ifdef REGISTRY_USER
ifdef REGISTRY_PASSWORD
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose down --remove-orphans'
	
	scp custom-docker-compose/gateway/custom-config.d/config_registry.conf ${HOST}:~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d/${SITE_NAME}.conf
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d && sed -i 's/%sitename%/${SITE_NAME}/g' ${SITE_NAME}.conf'
	
	ssh ${HOST} -p ${PORT} 'sudo apt-get install apache2-utils' || true
	ssh ${HOST} -p ${PORT} 'htpasswd -Bbn ${REGISTRY_USER} ${REGISTRY_PASSWORD} > ~/${DOCKER_PROJECTS_FOLDER}/gateway/data/conf.d/registry.htpasswd'

	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/gateway && docker-compose -f docker-compose.yml -f docker-compose.prod.yml up --build ${DETACH}'
else
	echo "REGISTRY_PASSWORD not defined"
endif
else
	echo "REGISTRY_USER not defined"
endif
else
	echo "SITE_NAME not defined"
endif
else
	echo "DOCKER_PROJECTS_FOLDER not defined"
endif
else
	echo "PORT not defined"
endif
else
	echo "HOST not defined"
endif

#########################################################################
# 							Registry hub 								#
#########################################################################

# HOST= PORT= DOCKER_PROJECTS_FOLDER= SITE_NAME= make create_registry_hub
create_registry_hub:
ifdef HOST
ifdef PORT	
ifdef DOCKER_PROJECTS_FOLDER
ifdef REGISTRY_USER
ifdef REGISTRY_PASSWORD
ifdef NETWORK_NAME
ifdef SITE_NAME
	scp -r custom-docker-compose/registry ${HOST}:~/${DOCKER_PROJECTS_FOLDER}
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/registry && echo "NETWORK_NAME=${NETWORK_NAME}" >> .env'
	ssh ${HOST} -p ${PORT} 'cd ~/${DOCKER_PROJECTS_FOLDER}/registry && docker-compose up --build ${DETACH}'
	docker login -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${SITE_NAME}
else
	echo "SITE_NAME not defined"
endif
else
	echo "NETWORK_NAME not defined"
endif
else
	echo "REGISTRY_PASSWORD not defined"
endif
else
	echo "REGISTRY_USER not defined"
endif
else
	echo "DOCKER_PROJECTS_FOLDER not defined"
endif
else
	echo "PORT not defined"
endif
else
	echo "HOST not defined"
endif	