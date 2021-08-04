#!/bin/bash 
set -e
apt-get update && apt-get install -y jq uuid-runtime

ROUTE_1="Denver, CO|Columbus, OH|Atlanta, GA|Nashville, TN|Chicago, IL|Minneapolis, MN"
ROUTE_2="Baltimore, MD|Atlanta, GA|Nashville, TN|Denver, CO"
ROUTE_3="Columbus, OH|Atlanta, GA|Raleigh, NC|Washington, DC|New York, NY|Boston, MA"
#total asset create request  it will generate totak request as MAX_CREATE_REQUEST * No of city in an route
MAX_CREATE_REQUEST=500
# No of concurent shipment create request before starting update
BATCH_COUNT=10 

#Shiping status "Processed" ,"In Transit","Delivered"


# Medical Goods Info
declare -a GOOSInfo=('Medical Face Masks' 'Ventilator for critical Care' 'Anaesthetic Ventilator' 'Flowmeter and oxygen sensors' 'Oxygen concentrator/generator');



CC_NAME="shipment_cc"

if [ -z $1 ]; then
	echo "No transactions per second arg passed, setting to 1 by default"
	TRANSACTIONS_PER_SECOND=1
else
	TRANSACTIONS_PER_SECOND=$1
fi

echo "================= Shipment Tracking ================="


send_txn() {
  local txn="$1"
  local channel="$2"
  peer chaincode invoke -o orderer.example.com:7050  \
              --tls $CORE_PEER_TLS_ENABLED \
              --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem  \
              -C $channel -n $CC_NAME \
              -c "$txn"
}

shipment_generate() {
  local item_id='ship-'$(uuidgen)
  echo "$1"
  IFS="|" read -a route <<< $1
  echo ${route[*]}
  local ing_good_info=$2
  local pur_id='purchage-'$(uuidgen)
  local sdate=$(date '+%Y/%m/%d %H:%M:%S');
  ing_route_len=${#route[@]}
  echo "$item_id $3 1" >> shipment.txt
  local inRoutinfo="[{\\\"location\\\":\\\"${route[0]}\\\",\\\"arrivalDate\\\":\\\"$sdate\\\"}]"
  #echo $inRoutinfo
  len=$(($ing_route_len - 1))
  local txn1='{"Args":["CreateShipmentAsset","{\"id\":\"'$item_id'\",\"shipmentDate\":\"'$sdate'\",\"sourceId\":\"'${route[0]}'\",\"destinationId\":\"'${route[$len]}'\",\"inRoutinfo\":'$inRoutinfo',\"purchaseOrderId\":\"'$pur_id'\",\"status\":\"Processed\",\"goodsInfo\":\"'$ing_good_info'\"}"]}'
  send_txn "$txn1" "shipmenttraking"
  sleep 5
}

item_move() {
echo "Line to process is : $1"
asset=($1)
echo "Arry is : ${asset[*]}"
  if   [ ${asset[1]} == 0 ]; then
        IFS="|" read -a route <<< $ROUTE_1
        route_len=${#route[@]}
        local r_len=$((${asset[2]} + 1))
      if [ $route_len == $r_len ]; then
        local item_id=${asset[0]}
        local index=${asset[2]}
        local item_location=${route[$index]}
        local item_invoiceid='inv-'$(uuidgen)
        local event_date=$(date '+%Y/%m/%d %H:%M:%S');
        local inRoutinfo="[{\\\"location\\\":\\\"$item_location\\\",\\\"arrivalDate\\\":\\\"$event_date\\\"}]"
        local item_txn='{"Args":["ChangeShipmentAsset","{\"id\":\"'$item_id'\" ,\"inRoutinfo\":'$inRoutinfo',\"paymentInvoiceId\":\"'$item_invoiceid'\",\"status\":\"Delivered\"}"]}'
        send_txn "$item_txn" "shipmenttraking"
        sleep 5
      else 
        local item_id=${asset[0]}
        local index=${asset[2]}
        local item_location=${route[$index]}
        local event_date=$(date '+%Y/%m/%d %H:%M:%S');
        local inRoutinfo="[{\\\"location\\\":\\\"$item_location\\\",\\\"arrivalDate\\\":\\\"$event_date\\\"}]"
        local item_txn='{"Args":["ChangeShipmentAsset","{\"id\":\"'$item_id'\" ,\"inRoutinfo\":'$inRoutinfo',\"status\":\"In-Transit\"}"]}'
        send_txn "$item_txn" "shipmenttraking"
        sleep 5
        index=$(($index + 1))
        echo "$item_id ${asset[1]} $index" >> shipment.txt
    fi
  elif [ ${asset[1]} == 1 ]; then
        IFS="|" read -a route <<< $ROUTE_2
        route_len=${#route[@]}
        local r_len=$((${asset[2]} + 1))
      if [ $route_len == $r_len ]; then
        local item_id=${asset[0]}
        local index=${asset[2]}
        local item_location=${route[$index]}
        local item_invoiceid='inv-'$(uuidgen)
        local event_date=$(date '+%Y/%m/%d %H:%M:%S');
        local inRoutinfo="[{\\\"location\\\":\\\"${route[0]}\\\",\\\"arrivalDate\\\":\\\"$sdate\\\"}]"
        local item_txn='{"Args":["ChangeShipmentAsset","{\"id\":\"'$item_id'\" ,\"inRoutinfo\":'$inRoutinfo',\"paymentInvoiceId\":\"'$item_invoiceid'\",\"status\":\"Delivered\"}"]}'
        send_txn "$item_txn" "shipmenttraking"
        sleep 5
    else 
        local item_id=${asset[0]}
        local index=${asset[2]}
        local item_location=${route[$index]}
        local event_date=$(date '+%Y/%m/%d %H:%M:%S');
       local inRoutinfo="[{\\\"location\\\":\\\"${route[0]}\\\",\\\"arrivalDate\\\":\\\"$sdate\\\"}]"
       local item_txn='{"Args":["ChangeShipmentAsset","{\"id\":\"'$item_id'\" ,\"inRoutinfo\":'$inRoutinfo',\"status\":\"In-Transit\"}"]}'
        send_txn "$item_txn" "shipmenttraking"
        sleep 5
        index=$(($index + 1))
        echo "$item_id ${asset[1]} $index" >> shipment.txt
    fi
  elif [ ${asset[1]} == 2 ]; then
        IFS="|" read -a route <<< $ROUTE_3
        route_len=${#route[@]}
        local r_len=$((${asset[2]} + 1))
      if [ $route_len == $r_len ]; then
        local item_id=${asset[0]}
        local index=${asset[2]}
        local item_location=${route[$index]}
        local item_invoiceid='inv-'$(uuidgen)
        local event_date=$(date '+%Y/%m/%d %H:%M:%S');
        local inRoutinfo="[{\\\"location\\\":\\\"$item_location\\\",\\\"arrivalDate\\\":\\\"$event_date\\\"}]"
        local item_txn='{"Args":["ChangeShipmentAsset","{\"id\":\"'$item_id'\" ,\"inRoutinfo\":'$inRoutinfo',\"paymentInvoiceId\":\"'$item_invoiceid'\",\"status\":\"Delivered\"}"]}'
        send_txn "$item_txn" "shipmenttraking"
        sleep 5
    else 
        local item_id=${asset[0]}
        local index=${asset[2]}
        local item_location=${route[$index]}
        local event_date=$(date '+%Y/%m/%d %H:%M:%S');
        local inRoutinfo="[{\\\"location\\\":\\\"$item_location\\\",\\\"arrivalDate\\\":\\\"$event_date\\\"}]"   
        local item_txn='{"Args":["ChangeShipmentAsset","{\"id\":\"'$item_id'\" ,\"inRoutinfo\":'$inRoutinfo',\"status\":\"In-Transit\"}"]}'
        send_txn "$item_txn" "shipmenttraking"
        sleep 5
        index=$(($index + 1))
        echo "$item_id ${asset[1]} $index" >> shipment.txt
    fi
  fi
}
echo "Press [CTRL+C] to stop.."
create_txn_count=0
process_line=0
rm -rf shipment.txt
while :
do
  if [ $create_txn_count -lt $MAX_CREATE_REQUEST ]; then
        for ((j = 0; j < $BATCH_COUNT; ++j))
        do
	        for (( i = 0; i < $TRANSACTIONS_PER_SECOND; ++i ))
	        do
	  		    create_txn_count=$(($create_txn_count + 1))
                ORG_NAME="visionmedic"
	  		    CORE_PEER_ADDRESS=peer0.visionmedic.example.com:7051
	  		    CORE_PEER_LOCALMSPID=VisionmedicMSP
	  		    CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/visionmedic.example.com/peers/peer0.visionmedic.example.com/tls/server.crt
	  		    CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/visionmedic.example.com/peers/peer0.visionmedic.example.com/tls/server.key
	  		    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/visionmedic.example.com/peers/peer0.visionmedic.example.com/tls/ca.crt
	  		    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/visionmedic.example.com/users/Admin@visionmedic.example.com/msp
	  		    export CORE_PEER_TLS_CLIENTAUTHREQUIRED=true
	  		    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG_NAME.example.com/msp/tlscacerts/tlsca.$ORG_NAME.example.com-cert.pem
	  		    export CORE_PEER_TLS_CLIENTKEY_FILE=$(find /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG_NAME.example.com/tlsca/ -type f -not -path *.pem)
	  		    export CORE_PEER_TLS_CLIENTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$ORG_NAME.example.com/tlsca/tlsca.$ORG_NAME.example.com-cert.pem
      
                goods_info=${GOOSInfo[$((RANDOM % 5))]}
                DIST_ROUTE=$((RANDOM % 3))
                if   [ $DIST_ROUTE == 0 ]; then
                    shipment_generate "${ROUTE_1}" "$goods_info" "$DIST_ROUTE"
                elif [ $DIST_ROUTE == 1 ]; then
                    shipment_generate "${ROUTE_2}" "$goods_info" "$DIST_ROUTE"
                elif [ $DIST_ROUTE == 2 ]; then
                    shipment_generate "${ROUTE_3}" "$goods_info" "$DIST_ROUTE"
                fi

            done
        done
    fi
  sleep 1
  #lines=$( cat shipment.txt )
  mapfile -t lines < shipment.txt
  lines_len=${#lines[@]}
  #if [ $lines_len -eq $process_line ]; then
  #     break
  #fi
 while [ $process_line -lt $lines_len ] 
  do
      item_move "${lines[$process_line]}"
      process_line=$(($process_line + 1))
  done
done