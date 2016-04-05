# docker-bitnami-developer
Docker support for M2 development with Bitnami VM image used for production


To create the docker instance

    docker run -d --name bitnami -p 8000:80 \
       -e "MAGENTO_PROD_SSH_USER=myusername" \
       -e "MAGENTO_PROD_SSH_HOST=192.169.168.55" \
       -e "MAGENTO_PROD_SSH_EMAIL=myemail@example.com" \
       -e "MAGENTO_REPO_PUBLIC_KEY=57777777777777777777777777777777" \
       -e "MAGENTO_REPO_PRIVATE_KEY=9d777777777777777777777777777777" \
       -e "SAMBA_START=1" \
       bitnami

Connect to the docker container

    docker exec -it bitnami bash

Pull code from production to the local container

    m2-pull-from-production.sh

After making local file changes, push to production

    m2-deploy-to-production.sh
