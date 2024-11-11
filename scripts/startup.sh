#!/bin/bash

bash -c "/root/.scripts/merge-kubeconfigs.sh"

if [[ -n "$DO_TOKEN" ]] ; then
  echo "token: $DO_TOKEN"
  doctl auth init -t "$DO_TOKEN"
fi

#bash -c "/root/.scripts/merge-kubeconfigs.sh && bash"