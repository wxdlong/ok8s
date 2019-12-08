#!/bin/bash

set -e

NodeName=ok8s


function preflight(){
    
}

function initK8s(){
    kubeadm init --node-name=${NodeName} --v=7

}