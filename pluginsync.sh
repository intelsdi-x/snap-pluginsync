#!/bin/bash

# terminate child processes on exit
trap 'kill $(jobs -pr) > /dev/null 2>&1' SIGINT SIGTERM EXIT

set -e
set -u
set -o pipefail

# NOTE: proxifier inteferes with nc -z port scan so hardcoded for now:
PORT=64321

type -p socat > /dev/null 2>&1 || (echo "socat needs to be installed" && exit 1)
type -p docker > /dev/null 2>&1 || (echo "Docker needs to be installed" && exit 1)
docker version >/dev/null 2>&1 || (echo "Docker needs to be configured/running" && exit 1)

if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
  echo "Please configure ssh-agent and configure github to use ssh keys."
  exit 1
fi

if [[ $(ssh-add -l | grep -c 'no identities') -eq 1 ]]; then
  echo "Please add github private key via command 'ssh-add [/path/to/github_private_key]' and rerun this command"
  exit 1
fi

# NOTE: forward SSH_AUTH_SOCK until docker socket forwarding is resolved:
# https://github.com/docker/for-mac/issues/483
socat TCP-LISTEN:"$PORT",reuseaddr,fork,bind=127.0.0.1 UNIX-CLIENT:"$SSH_AUTH_SOCK" &

docker run --net=host -v "${HOME}":/root -v "$(pwd)":/plugins -e SSH_AUTH_SOCK=/var/run/ssh_agent.sock  -it intelsdi/pluginsync /bin/bash -c "socat UNIX-LISTEN:/var/run/ssh_agent.sock,reuseaddr,fork TCP:192.168.65.1:${PORT} & cd /plugins && echo 'commands do not be prefixed with bundle exec, try: \"rake -T\" or \"travis\" or \"msync\"' && /bin/bash"

exit 0
