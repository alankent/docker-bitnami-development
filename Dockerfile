FROM alankent/m2dev
MAINTAINER Alan Kent <alan.james.kent@gmail.com>

# Add local shell scripts.
ADD bin/* /usr/local/bin/
ADD entrypoint.sh /entrypoint.sh
RUN chown magento:magento /usr/local/bin/m2* \
 && chmod +rx /usr/local/bin/m2* \
 && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
