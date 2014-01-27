return_statement ()
{
echo " please provide action requested "
echo "--list_open_virt_interfaces:
        requires: null
        produces all host with active virtual interface."
echo " --server_host: 
        requires instance id
        produces server instance is hosted on"
echo " --instance_detail:
        requires instance id
        produces detailed instance meta data"
echo "--boot_instance:
        requires:
                flavor number. get a list -> <nova-manage flavor list>
                image number. get a list -> <nova list>
                instance name. <whatever you want to name it>
        boots an instance "
echo "--delete_all_instances:
        requires: nothing
        deletes and removes all instances."

}
instance_id_list ()
{
        nova list | awk '{ if (NF > 1)  print "instance: "$2, "instance_name: "$4}'  | grep -v ID
}

case "$1" in

--list_open_virt_interfaces)
        mysql nova -e "select task_state, power_state, vm_state, user_id, uuid, instances.hostname, CONCAT('instance-000000', HEX(instances.id)) as virsh_id ,instances.host, address  from fixed_ips, instances where fixed_ips.virtual_interface_id > 1 and fixed_ips.instance_id = instances.id  order by host"

;;

--server_host)
        if [ $2 ]
                then
                        mysql nova -e "select launched_on from instances where uuid='$2'"
        else
                echo " Please provide the instance id:"
                echo "  Select from the following:"
                instance_id_list
        fi
        ;;

--delete_all_instances)
        echo "::::WARNING, THIS COMMAND WILL DELETE ALL YOUR INSTANCES, ARE YOU SURE YOU WANT TO GO FORWARD?::::"
        echo "Please input yes to move forward deleting instances:"
        read input
        if [ $input = "yes" ]
                then
                        for i in `nova list | awk '{print $2}'  | grep [\-]` ; do nova delete  $i ; done
                        echo "::::YOUR INSTANCES HAVE BEEN WIPED::::"
                else
                        echo "You must type the word \"yes\" to delete all your instances:"
        fi
        ;;

--instance_detail)
        if [ $2 ]
                then
                        mysql nova -e "select *  from instances where uuid='$2'\G"
        else
                echo " please provide the instance id."
                instance_id_list
        fi
        ;;
--boot_instance)
        if [ ! $2 ];
                then
                        echo " Select and append a number from the list below"
                        mysql nova -e "select flavorid, name from instance_types" | grep m1   | sort | awk '{print $1 " " $2}'
        elif [ ! $3 ];
                then
                        echo ""
                        echo " Select an image id and append from the following list:"
                        echo ""
                        nova image-list  | egrep -v "initrd|kernel|ramdisk"
        elif [ ! $4 ];
                then
                        echo "please provide the security group:"       
                        nova secgroup-list
        elif [ ! $5 ];
                then
                        echo "please provide image name:"       
        else
                echo " executing 'nova boot --flavor $2 --image $3 $4'"
                sleep 2
                nova boot --flavor $2 --image $3 --security_groups $4 $5
                nova list
        fi
        ;;


*)
        return_statement
        ;;
esac

