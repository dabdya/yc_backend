import argparse

COMPOSE_FILE = \
"""
version: "3.4"

services:
  backendapp:
    container_name: "yc-backend-container"
    image: "{image_name}"
    environment:
      - VERSION={version_value}
      - NAME={version_name}
    ports:
      - "8080:8080"
    restart: always
"""

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i", "--image", type=str, required = True, help = "Full image name")
    parser.add_argument(
        "-v", "--version_value", type=str, required = True, help = "Version value")
    parser.add_argument(
        "-n", "--version_name", type=str, required = True, help = "Version name")
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args()
    with open("docker/docker-compose.yaml", "w") as file:
        file.write(COMPOSE_FILE.format(
            image_name = args.image,
            version_value = args.version_value,
            version_name = args.version_name
          )
        )