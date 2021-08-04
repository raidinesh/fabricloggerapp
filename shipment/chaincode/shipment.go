/*
SPDX-License-Identifier: Apache-2.0
This Smart contrcat will provide a snapshot of B2B Shipment between
Medical Equipment manufacture  to Hospital Chain spreed across USA.
It also provide info about attached invoice paymet Info after delivery.
*/
package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

//FuncTemplate : This Function is Tamplate for all function to Blockchain
type FuncTemplate func(stub shim.ChaincodeStubInterface, args []string) pb.Response

const (
	shipmetAsset string = "ShipmentAsset"
	cSA          string = "CreateShipmentAsset"
	qSA          string = "QueryShipmentAsset"
	qASA         string = "QueryAllShipmentAssets"
	uSA          string = "ChangeShipmentAsset"
)

var logger = shim.NewLogger("Shipment")

// Shipment contract  provides functions for managing B2B Shipment
type Shipment struct {
	funcMap      map[string]FuncTemplate
	restartcheck bool
}

//This function will create a  map that will get initialized at chaincode init
func (inv *Shipment) initfunMap() {
	inv.funcMap = make(map[string]FuncTemplate)
	inv.funcMap[cSA] = CreateShipmentAsset
	inv.funcMap[qSA] = QueryShipmentAsset
	inv.funcMap[qASA] = QueryAllShipmentAssets
	inv.funcMap[uSA] = ChangeShipmentAsset
}

// Init initialize data in Chaincode
func (inv *Shipment) Init(stub shim.ChaincodeStubInterface) pb.Response {

	logger.Infof("Init ChaininCode Shipment")
	inv.initfunMap()
	inv.restartcheck = true
	return shim.Success(nil)
}

// Invoke : Chaincode Invoke Function
func (inv *Shipment) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	logger.Infof("Invoke ChaininCode Shipment")
	funname, args := stub.GetFunctionAndParameters()
	if funname == "" {
		logger.Infof("Function Name is not passed correctly while invoking ChainCode")
	}

	if inv.restartcheck == false {
		inv.initfunMap()
		inv.restartcheck = true
		logger.Infof("%+v", inv)
	}
	exefun, ok := inv.funcMap[funname]
	logger.Infof("Invoke ChaininCode Shipment for Function Name: %s", funname)
	if ok {
		return exefun(stub, args)
	}
	logger.Errorf("Function Name:= %s is not defined in ChaininCode", funname)
	return shim.Error(fmt.Sprintf("Invalid Function Name: %s", funname))
}

// RoutingInfo describes  details about B2B Shipment location information
type RoutingInfo struct {
	Location    string `json:"location"`
	ArrivalDate string `json:"arrivalDate"`
}

// ShipmentAsset describes  details about B2B Shipment information
type ShipmentAsset struct {
	DocType          string        `json:"docType"`
	ShipmentID       string        `json:"id"`
	ShipmentDate     string        `json:"shipmentDate"`
	ReceivedDate     string        `json:"receivedDate"`
	SourceID         string        `json:"sourceId"`
	DestinationID    string        `json:"destinationId"`
	InRoutInfo       []RoutingInfo `json:"inRoutinfo"`
	PurchaseOrderID  string        `json:"purchaseOrderId"`
	Status           string        `json:"status"`
	PaymentInvoiceID string        `json:"paymentInvoiceId"`
	GoodsInfo        string        `json:"goodsInfo"`
}

func JsontoShipmentAsset(data []byte) (ShipmentAsset, error) {
	obj := ShipmentAsset{}
	if data == nil {
		return obj, fmt.Errorf("Input data  for json to ShipmentAsset is missing")
	}

	err := json.Unmarshal(data, &obj)
	if err != nil {
		return obj, err
	}
	return obj, nil
}

//ShipmentAssettoJson Convert ShipmentAsset Asset object to Json Message
func ShipmentAssettoJson(obj ShipmentAsset) ([]byte, error) {

	data, err := json.Marshal(obj)
	if err != nil {
		return nil, err
	}
	return data, err
}

// QueryResult structure used for handling result of query
type QueryResult struct {
	Key    string `json:"Key"`
	Record *ShipmentAsset
}

// CreateShipmentAsset adds a new ShipmentAsset to the world state with given details
func CreateShipmentAsset(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var key []string
	asset := ShipmentAsset{}
	if len(args) < 1 {
		logger.Errorf("CreateShipmentAsset : Incorrect number of arguments.")
		return shim.Error("CreateShipmentAsset : Incorrect number of arguments.")
	}

	// Convert the arg to a CreateShipmentAsset Object
	logger.Infof("CreateShipmentAsset: Arguments for ledgerapi %s : ", args[0])
	err := json.Unmarshal([]byte(args[0]), &asset)
	if err != nil {
		logger.Errorf("CreateShipmentAsset : Error parsing  from Json  %s", err)
		return shim.Error(fmt.Sprintf("CreateShipmentAsset :  Error parsing  from Json  %s", err))

	}
	asset.DocType = shipmetAsset
	ShipmentAssetAsBytes, _ := json.Marshal(asset)
	key = append(key, asset.ShipmentID)
	err = CreateAsset(stub, shipmetAsset, key, ShipmentAssetAsBytes)

	if err != nil {
		logger.Errorf("CreateShipmentAsset : Error inserting Object into LedgerState %s", err)
		return shim.Error(fmt.Sprintf("CreateShipmentAsset : ShipmentAsset object create failed %s", err))

	}

	return shim.Success([]byte(ShipmentAssetAsBytes))
}

// QueryShipmentAsset returns the ShipmentAsset stored in the world state with given id
func QueryShipmentAssetData(stub shim.ChaincodeStubInterface, arg string) (*ShipmentAsset, error) {
	var key []string

	key = append(key, arg)
	ShipmentAssetAsBytes, err := QueryAsset(stub, shipmetAsset, key)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if ShipmentAssetAsBytes == nil {
		return nil, fmt.Errorf("%s does not exist", arg)
	}

	asset, _ := JsontoShipmentAsset(ShipmentAssetAsBytes)

	return &asset, nil
}

// QueryShipmentAsset returns the ShipmentAsset stored in the world state with given id
func QueryShipmentAsset(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var key []string

	key = append(key, args[0])
	ShipmentAssetAsBytes, err := QueryAsset(stub, shipmetAsset, key)

	if err != nil {
		logger.Errorf("QueryShipmentAsset : Error inserting Object into LedgerState %s", err)
		return shim.Error(fmt.Sprintf("QueryShipmentAsset : ShipmentAsset object create failed %s", err))

	}

	if ShipmentAssetAsBytes == nil {
		logger.Errorf("QueryShipmentAsset : Error inserting Object into LedgerState %s", err)
		return shim.Error(fmt.Sprintf("QueryShipmentAsset : ShipmentAsset object create failed %s", err))

	}

	return shim.Success([]byte(ShipmentAssetAsBytes))
}

// QueryAllShipmentAssets returns all ShipmentAssets found in world state
func QueryAllShipmentAssets(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	startKey := ""
	endKey := ""

	resultsIterator, err := stub.GetStateByRange(startKey, endKey)

	if err != nil {
		logger.Errorf("QueryAllShipmentAssets : Error inserting Object into LedgerState %s", err)
		return shim.Error(fmt.Sprintf("QueryAllShipmentAssets : ShipmentAsset object create failed %s", err))

	}
	defer resultsIterator.Close()

	results := []QueryResult{}

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()

		if err != nil {
			logger.Errorf("QueryAllShipmentAssets : Error Querying object in LedgerState %s", err)
			return shim.Error(fmt.Sprintf("QueryAllShipmentAssets : ShipmentAsset object Query failed %s", err))

		}
		databyte := queryResponse.GetValue()
		asset, _ := JsontoShipmentAsset(databyte)
		queryResult := QueryResult{Key: queryResponse.Key, Record: &asset}
		results = append(results, queryResult)
	}
	response, _ := json.Marshal(results)

	return shim.Success([]byte(response))
}

// ChangeShipmentAsset updates the owner field of ShipmentAsset with given id in world state Values
func ChangeShipmentAsset(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	var key []string
	if len(args) < 1 {
		logger.Errorf("ChangeShipmentAsset : Incorrect number of arguments.")
		return shim.Error("ChangeShipmentAsset : Incorrect number of arguments.")
	}

	// Convert the arg to a CreateShipmentAsset Object
	logger.Infof("ChangeShipmentAsset: Arguments for ledgerapi %s : ", args[0])

	asset, _ := JsontoShipmentAsset([]byte(args[0]))

	assetread, err := QueryShipmentAssetData(stub, asset.ShipmentID)

	if err != nil {
		logger.Errorf("ChangeShipmentAsset : Error Querying object in LedgerState %s", err)
		return shim.Error(fmt.Sprintf("ChangeShipmentAsset : ShipmentAsset object Query failed %s", err))

	}
	if len(asset.ReceivedDate) != 0 {

		assetread.ReceivedDate = asset.ReceivedDate
	}
	if len(asset.InRoutInfo) != 0 {
		assetread.InRoutInfo = append(assetread.InRoutInfo, asset.InRoutInfo...)

	}
	if len(asset.Status) != 0 {
		assetread.Status = asset.Status
	}
	if len(asset.PaymentInvoiceID) != 0 {
		assetread.PaymentInvoiceID = asset.PaymentInvoiceID
	}

	ShipmentAssetAsBytes, _ := json.Marshal(assetread)
	key = append(key, assetread.ShipmentID)
	err = UpdateAssetWithoutGet(stub, shipmetAsset, key, ShipmentAssetAsBytes)
	if err != nil {
		logger.Errorf("ChangeShipmentAsset : Error Update object in LedgerState %s", err)
		return shim.Error(fmt.Sprintf("ChangeShipmentAsset : ShipmentAsset object Update failed %s", err))
	}
	response, _ := ShipmentAssettoJson(*assetread)
	return shim.Success(response)
}

func main() {
	err := shim.Start(new(Shipment))
	if err != nil {
		fmt.Printf("Error create ShipmentAsset chaincode: %s", err.Error())
		return
	}

}
