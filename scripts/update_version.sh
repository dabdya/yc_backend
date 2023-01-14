if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` [version-name] [version-value]"
  exit 0
fi

# Import variables from config.cfg file
source <(cat config.env | sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")

# Required yandex registry format
FULL_IMAGE_NAME="cr.yandex/$REGISTRY_ID/$IMAGE_NAME"

# If exists extract else set empty value
LAST_VERSION=$(docker images | grep $FULL_IMAGE_NAME | grep -Po '(?<=v)\d' | sort -n | tail -1)

# Generate version name is not specified
VERSION_NAME=${1:-$(cat /dev/urandom | tr -dc 'a-z' | fold -w 10 | head -n 1)}

# Set new version. Default is equal last increased by one
NEW_VERSION=${2:-$(($LAST_VERSION+1))}


NEW_IMAGE_NAME="$FULL_IMAGE_NAME:$NEW_VERSION"
# Configure authtorize in container registry service
yc container registry configure-docker
# Upload to repository. Important: docker should run without sudo
docker build -t $NEW_IMAGE_NAME ..
docker push $NEW_IMAGE_NAME

# Generate new docker-compose file with changed version
python3 docker/generate_compose.py -i $NEW_IMAGE_NAME -v $NEW_VERSION -n $VERSION_NAME

# Get all subnets and addresses from specified target group
SUBNETS=$(yc load-balancer target-group get $TARGET_GROUP | grep -Po '(?<=subnet_id: ).+')
ADDRESSES=$(yc load-balancer target-group get $TARGET_GROUP | grep -Po '(?<=address: ).+')

# Get infromation about folder, updated instance should belongs to exists folder
FOLDER_ID=$(yc load-balancer target-group describe $TARGET_GROUP | grep -Po '(?<=folder_id: ).+')
FOLDER_NAME=$(yc resource-manager folder get $FOLDER_ID | grep -Po '(?<=name: ).+')

# Get number of instances in target group, create counter
TARGET_GROUP_SIZE=$(yc load-balancer target-group describe $TARGET_GROUP | grep address | wc -l)
N=$(($TARGET_GROUP_SIZE + 1))

for (( i=1; i< $N; i++))
do
    python3 -c 'print("-" * 80)'
    echo "Processing $i/$TARGET_GROUP_SIZE instances"

    # Get subnet and address for i-th instance
    subnet=$(echo $SUBNETS | cut -d' ' -f$i)
    address=$(echo $ADDRESSES | cut -d' ' -f$i)

    # Asynchronous removing instance from target group
    yc load-balancer target-group remove-targets $TARGET_GROUP --target address=$address,subnet-id=$subnet --async
    # Remove instance from compute cloud service synchronously, because instance name repeated
    INSTANCE_NAME=$(yc compute instance list | grep $address | awk '{split($0,a," | "); print a[4]}')
    yc compute instance delete --name $INSTANCE_NAME
    # Create and add new instance to target group with updated backend version
    ./create_then_add.sh $FOLDER_NAME $INSTANCE_NAME $TARGET_GROUP
    echo "Instance $INSTANCE_NAME updated"
done

python3 -c 'print("-" * 80)'
echo "Update was successful. Wait a couple of minutes for the containers to start"
