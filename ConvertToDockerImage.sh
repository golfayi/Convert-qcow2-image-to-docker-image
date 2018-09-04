#!/bin/bash
#####################
#Script Name : Convert devel or release image to docker image
#Author : Yi Xiaodong ( xiaodong.yi@nokia-sbell.com )
#Using Method : ./ConvertToDockerImage.sh -i http://10.56.118.71/pilivee/RCP/rcp2.0/release/RCP2.0_17.51.0/images/rcp2.0-devel_r23156-171218-054011.qcow2
####################

#================
# Check Permission of current user in /home/image/
#================
function CheckRootPerpermission()  
{  
    check_CurrentUser=`whoami`  
    if [ "$check_CurrentUser" == "root" ]  
    then   
        echo "You are $check_CurrentUser user"  
        echo "You are a super amdin"  
    else  
        echo "You are $check_CurrentUser user"  
        echo "You are a common user"  
    fi  
}

#================
#pre-check image before upload
#  1, if same image exists, abort this operation
#  2, if same image is not existed, continue
#================
function CheckImage()
{
    echo " release/devel image name: $1"
    imageqcow2=$1
    echo " imageqcow2: $imageqcow2"
    shortimagename=${imageqcow2##*/}
    echo " shortimagename: $shortimagename"
    JudgeImage $shortimagename;
}

#================
# Check image exist in /home/image directory
#================
function CheckImageExist()
{
    echo " image short name: $1"
    ls -al
    result=$(ls -al | grep $1)
    if [[ "$result" != "" ]]
    then
        echo "have $1 in image folder, abort this operation"
        exit 0
    else
        echo "Dont have $1 in image folder, continue"
    fi
}
function getImageLink()
{
    [ $# -eq 0 ] #if no input, print the help info

    while getopts "i:" opts
    do
        case $opts in
            i)
                IMAGE_LINK=$OPTARG
                ;;
            *)
                echo "unknown argument $OPTARG"
                ;;
        esac
    done
    echo "wget image :" $IMAGE_LINK
    echo "btscloud" | sudo wget $IMAGE_LINK
}


function ConvertToDockerImage()
{
   imageqcow2=$1
   shortname=${imageqcow2##*/}
   echo " shortname: $shortname"
   namewithoutqcow2=${shortname%.*}
   echo " namewithoutqcow2 : $namewithoutqcow2"
   ls -al
   echo "btscloud" | sudo rm -rf $namewithoutqcow2.raw
   echo "btscloud" | sudo qemu-img convert -f qcow2 -O raw $shortname $namewithoutqcow2.raw
   echo " convert successfully "
   echo "btscloud" | sudo fdisk -lu $namewithoutqcow2.raw
   echo "btscloud" | sudo rm -rf $namewithoutqcow2
   echo "btscloud" | sudo mkdir $namewithoutqcow2
   #MountImage $namewithoutqcow2;
   echo "btscloud" | sudo mount -o loop,rw,offset=1048576 $namewithoutqcow2.raw  /home/image/$namewithoutqcow2
   echo " mount successfully "

   GenerateImage $namewithoutqcow2;
   UnmountImage $namewithoutqcow2;
   UploadToDocker $namewithoutqcow2;
}

function GenerateImage()
{
    echo " namewithoutqcow2: $1 "
    cd /home/image/$1
    ls -al
    pwd
    echo "btscloud" | sudo tar -czf /home/image/$1.tar.gz .
    echo " generate image successfully "
    cd ../
    ls -al
    pwd
}

function UnmountImage()
{
    echo " namewithoutqcow2: $1 "
    echo "btscloud" | sudo umount /home/image/$1
    echo "umount successfully "
}

function UploadToDocker()
{
    echo " namewithoutqcow2: $1 "
    echo "btscloud" | cat /home/image/$1.tar.gz | sudo docker import -c "EXPOSE 22" - $1 
    echo " upload to Docker successfully"
    echo "btscloud" | sudo docker images
    ls -al
    echo "btscloud" | sudo rm -rf *.gz
    echo "btscloud" | sudo rm -rf *.raw
    pwd
    ls -al
}

CheckRootPerpermission
getImageLink $@
ConvertToDockerImage $IMAGE_LINK

