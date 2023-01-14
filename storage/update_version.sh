if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` version [bucket-name]"
  exit 0
fi

VERSION=$1
BUCKET_NAME=${2:-"cringebook"}

s3cmd sync --add-header="X-Amz-Meta-Version:${VERSION}" --recursive . s3://$BUCKET_NAME/;s3cmd modify --add-header="X-Amz-Meta-Version:${VERSION}" --recursive s3://$BUCKET_NAME/;
