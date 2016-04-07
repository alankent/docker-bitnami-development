# Docker Bitnami Developer

WARNING: These files may get out of date with the latest GoDaddy builds.
There is no formal process where I test these scripts every time GoDaddy
releases a new base image.

Docker support for M2 development with Bitnami VM image used for production.
(You do need to be careful to use a compatible version of this docker
container with production. Ideally these scripts should sense the version
of the Bitnami image and adapt accordingly.)

To create the docker instance

    docker run -d --name bitnami \
       -p 8000:80 -p 135:135 -p 139:139 -p 445:445 \
       -e "MAGENTO_PROD_SSH_USER=myusername" \
       -e "MAGENTO_PROD_SSH_HOST=192.169.168.55" \
       -e "MAGENTO_PROD_SSH_EMAIL=myemail@example.com" \
       -e "MAGENTO_REPO_PUBLIC_KEY=57777777777777777777777777777777" \
       -e "MAGENTO_REPO_PRIVATE_KEY=9d777777777777777777777777777777" \
       -e "SAMBA_START=1" \
       alankent/bitnami-development

Connect to the docker container

    docker exec -it bitnami bash

Pull code from production to the local container. This takes a while to
complete as it also downloads all composer dependencies.

    m2-pull

After making local file changes, push to production. This takes the store
out of production for a period of time during database schema upgrades etc.

    m2-push

To ssh onto the production server.

    m2-ssh
