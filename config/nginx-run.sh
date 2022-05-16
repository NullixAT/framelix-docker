. /opt/bitnami/scripts/liblog.sh
cp /opt/bitnami/nginx/nginx-config-template.conf /opt/bitnami/nginx/conf/server_blocks/default.conf

until [ -f /framelix/MODULE ]; do
  echo "Waiting for phpfpm to create app/MODULE out of app release files"
  sleep 1
done

FRAMELIX_MODULE=$(cat /framelix/MODULE)
info "** Injecting FRAMELIX_MODULE->$FRAMELIX_MODULE into /opt/bitnami/nginx/conf/server_blocks/default.conf **"
sed -i "s/{module}/$FRAMELIX_MODULE/g" /opt/bitnami/nginx/conf/server_blocks/default.conf
info "** Starting NGINX setup **"
/opt/bitnami/scripts/nginx/setup.sh
info "** NGINX setup finished! **"
/opt/bitnami/scripts/nginx/run.sh