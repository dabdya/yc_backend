if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` [network-folder] [instance-name]"
  exit 0
fi

# Import variables from config.cfg file
source <(cat config.env | sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")

# Default folder is `default`. Check `yc resource-manager folder list`
NETWORK_FOLDER=${1:-"default"}

# Generate instance name if not specified
INSTANCE_NAME=${2:-$(cat /dev/urandom | tr -dc 'a-z' | fold -w 10 | head -n 1)}

./create_instance.sh $NETWORK_FOLDER $INSTANCE_NAME
./add_instance.sh $INSTANCE_NAME
