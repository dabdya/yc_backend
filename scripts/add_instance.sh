if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` instance-name | instance-id"
  exit 0
fi

# Import variables from config.cfg file
source <(cat config.env | sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")

# Exists instance from `yc compute instance list`
INSTANCE_ID=$1

# Subnet for specified instance. 
# Important: all target subnets in the target group must be from the same folder network
INSTANCE_SUBNET_ID=$(yc compute instance get $INSTANCE_ID | grep subnet | awk '{split($0,a,": "); print a[2]}')

# Internal address in subnet. Required for load balancer
INTERNAL_ADDRESS=$(yc compute instance get $INSTANCE_ID | grep address | awk '{split($0,a,": "); print a[2]} ' | awk 'NR==3')

yc load-balancer target-group add \
    --name $TARGET_GROUP \
    --target subnet-id=$INSTANCE_SUBNET_ID,address=$INTERNAL_ADDRESS
