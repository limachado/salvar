#!/bin/bash

function showHelp() {
  echo "Sintaxe:"
  echo "  `basename $0` start|stop"
  echo
  echo "Chamada da API:"
  echo "  curl http://localhost:5000/v3"
  exit 1
}

if [ ! $1 ]; then
  showHelp
fi

case $1 in
  "start")
    $0 stop
    ssh -f -nNT -L 5000:172.20.145.231:5000 root@172.20.145.231 # indraosindra
    ;;
  "stop")
    kill -9 `ps -ef | grep -i "ssh -f -nNT -L 5000:172.20.145.231:5000 root@172.20.145.231" | grep -v grep | awk {'print $2'}`
    ;;
  *)
    showHelp
esac
