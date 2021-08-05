# fabricloggerapp
Demo app to use Fabric logger with Smart Contract

This Repo is using Splunk Fabric Logger  **vaccine-demo** as base to develop a demo to track  and trace Medical Equipment Shiping from Supplyer to Buyers.
It is using Splunk Dashboard to show overall prformance of the network.
To run this demo
From `fabricloggerapp/shipment/` you can simply run `./start.sh` in this directory which will spin up all the necessary containers in your local docker environment. Splunk App for Hyperledger Fabric will be installed in Splunk and all the required channels will be created.

Once the channels are set up and transactions are flowing, you can log into Splunk which will be installed and accessible at `http://localhost:8000`. The username and password will be `admin / changeme`. Splunk may take up to a minute to start up because it requires downloading the Hyperledger App, you can watch the progress using `docker logs -f splunk.example.com`.

In order to submit transactions to the Hyperledger Fabric network, run the following command.

```
./start-txns.sh
```

In order to shutdown the environment, run `./stop.sh`.

Once logged into Splunk, you can view the Hyperledger Fabric dashboards inside the Hyperledger Splunk application.
