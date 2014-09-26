#!/bin/bash


#Tim Cook 
#tim.cook@hightail.com



auth="--os-username admin --os-password yo_mama --os-tenant-name admin --os-auth-url http://10.0.0.1:5000/v2.0/"
export PATH=/usr/bin:/bin


nova_chef_virt=`nova $auth list | grep kvm_chef  | awk '{print $2}' `
nova_mrepo_virt=`nova $auth list | grep kvm_mrepo  | awk '{print $2}'`


nova_chef_snap=`nova $auth image-list | grep kvm_chef | awk '{print $2}' `
nova_mrepo_snap=`nova $auth image-list | grep kvm_mrepo | awk '{print $2}' `

if [ $1 ] ; then
   debug="yes"
else
   debug="no"
fi

create_new_image () 

{
        # if you want to see the output without running the command , for troubleshooting , 
        # just pass any arg and the cammands that will run will be echoed to the screen without actually running. 
        snap_name="kvm_$1_snap"
        nova $auth image-list | grep kvm_$1 | awk '{print $4}'  | grep 02
           if [ $? -ne "0" ]; then
             if [ $4 == "yes" ]; then
               echo "nova $auth image-create $2 $snap_name"02"" || exit
               echo "nova $auth image-delete $3"
             else
               nova $auth image-create $2 $snap_name"02" || exit
               nova $auth image-delete $3
             fi
           else
             if [ $4 == "yes" ]; then
               echo "nova $auth image-create $2 $snap_name"01"" || exit
               echo "nova $auth image-delete $3"
             else
               nova $auth image-create $2 $snap_name"01" || exit
               nova $auth image-delete $3
             fi
           fi
}


create_new_image chef $nova_chef_virt  $nova_chef_snap $debug
create_new_image mrepo $nova_mrepo_virt  $nova_mrepo_snap  $debug
