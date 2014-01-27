admin_token=`openssl rand -hex 10`
curr_dir=`pwd`
post_config_token=`cat /etc/keystone/keystone.conf | grep admin_token  | awk '{print $3}'`
end_point="http://localhost:35357/v2.0"


check_return ()
 {
   if [ $? -ne "0" ]
      then
        echo "$1 failed" 
        exit
   fi
 }

create_keystone_db_auth () 
 {
   mysql -u root -e "CREATE DATABASE keystone"  || echo "failed to create database keystone" ; exit
   mysql -u root -e "GRANT ALL ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'usendit1'"  || echo "failed to grant keystone privileges" ; exit
   mysql -u root -e "GRANT ALL ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'usendit1'"  || echo "failed to grant keystone privileges" ; exit
 }

create_auth_exports ()
  {
    > $curr_dir/scripts
    echo "export OS_SERVICE_ENDPOINT=http://localhost:35357/v2.0" >> $curr_dir/scripts
    echo "export OS_SERVICE_TOKEN=$admin_token " >> $curr_dir/scripts
   }

set_nova_conf () 
  {
    cd /etc/keystone/
    cat ./keystone.conf | grep admin_token | grep "#"
    if [ $? -ne "0" ]
      then
         perl -pi -w -e "s/admin_token = .*/admin_token = $admin_token/g;" keystone.conf
    else
         perl -pi -w -e "s/^#admin_token = .*/admin_token = $admin_token/g;" keystone.conf
    fi
    create_auth_exports
  }

create_keystone_admin () 
 {
  # Check to see if htops tenant exist if so do nothing , if not create htops tenant.
  keystone --os-token $post_config_token --os-endpoint $end_point tenant-list | grep $2  1> /dev/null ||
  keystone --os-token $post_config_token --os-endpoint $end_point tenant-create --name  $2 \
  --description "Hightail Operations"
  check_return "creating htops tenant"

 # get the htops tenant id to assign the admin user to. 
  htops_tenant_id=`keystone --os-token $post_config_token --os-endpoint $end_point tenant-list | grep $2  | awk '{print $2}'` ;
  check_return "tenant id assignment"


  # Check if admin user exists , if not create admin and assign to htops tenant. 
  keystone --os-token $post_config_token --os-endpoint $end_point  user-list | grep $1 1> /dev/null\
  || \
  keystone --os-token $post_config_token --os-endpoint $end_point user-create --name $1 --tenant_id $htops_tenant_id --pass usendit1
  check_return "creating admin user"

  # get the htops tenant id to assign the admin user to 
  admin_user_id=`keystone --os-token $post_config_token --os-endpoint $end_point user-list | grep $1  | awk '{print $2}'` ;
  check_return "creating admin user id"


  # Check if admin role exists , if not create admin role 
  keystone --os-token $post_config_token --os-endpoint $end_point role-list | grep $1 1> /dev/null ||
  keystone --os-token $post_config_token --os-endpoint $end_point role-create --name $1
  check_return "creating admin role"


  # get the admin role id. 
  admin_user_role=`keystone --os-token $post_config_token --os-endpoint $end_point role-list | grep $1  | awk '{print $2}'`
  check_return "creating admin role id"


  keystone user-role-list --user-id $1 --tenant-id $2  | grep $1 1> /dev/null  ||
  keystone --os-token $post_config_token --os-endpoint $end_point user-role-add --user $admin_user_id --role $admin_user_role --tenant_id $htops_tenant_id
  check_return "assigning admin role to admin user in htops tenant"


  service_tenant=`keystone --os-token $post_config_token --os-endpoint $end_point tenant-list  | grep service  | awk '{print $2}' 2> /dev/null`
  if [ $? -ne "0" ]
    then
        service_tenant=`keystone --os-token $post_config_token --os-endpoint $end_point tenant-create --name service --description "Service Tenant" | grep id  | awk '{print $4}' `
  fi
  check_return "service tenant creation"


  for i in glance nova cinder ec2 swift
    do
      service_user_create $i  $service_tenant $admin_user_role
      check_return "$i service and user creation"
    done

 }

service_user_create () 
 {
   keystone --os-token $post_config_token --os-endpoint $end_point user-list | grep $1 1> /dev/null
   if [ $? -ne "0" ]
     then
     service01=`keystone user-create --tenant_id $2 --name $1 --pass $1 | grep id | awk '{print $4}'`
     keystone user-role-add --user $service01 --role $3 --tenant_id $2 1> /dev/null
   fi
 }


return_statement () 
  {
    echo "usage: [ --create_keystone_auth][--create_auth_exports][--set_nova_conf][--create_keystone_admin]"
  }


case "$1" in

  --create_keystone_auth)
      create_keystone_auth
  ;;

  --create_auth_exports)
     create_auth_exports
  ;;

  --set_nova_conf)
     set_nova_conf
  ;;

  --create_keystone_admin)
     # args = 1 user name  2 tenant to assign user name to 
     create_keystone_admin admin htops
  ;;

  *)
      return_statement
  ;;

esac
