// Imports
// ========================================================
import { QRCode } from 'react-qr-svg';
import proofRequest from '../../proofRequest';

// Config
// ========================================================
// update with your contract address
const DEPLOYED_CONTRACT_ADDRESS = "0x085523dF632FEaAE3Ae232E0EBc31FaC9956ddAb";

/**
 * 
 */
let qrProofRequestJson: any = { ...proofRequest };
qrProofRequestJson.body.transaction_data.contract_address = DEPLOYED_CONTRACT_ADDRESS;
qrProofRequestJson.body.scope[0].rules.query.req = {
  "customNumberAttribute": {
    // NOTE: this value needs to match the erc20ZkpRequest.ts L34 or erc721ZkpRequest.ts L34
    "$gt": 12
  }
};
// NOTE1: if you change this you need to resubmit the erc10|erc721ZKPRequest
// NOTE2: type is case-sensitive
// You can generate new schemas via https://platform-test.polygonid.com
qrProofRequestJson.body.scope[0].rules.query.schema = {
  "url": "https://s3.eu-west-1.amazonaws.com/polygonid-schemas/96c80e89-3c04-4762-8f4a-c39373571506.json-ld",
  "type": "MyCustomSchema"
};

// Main Component
// ========================================================
const App = () => {

  return (
    <div className="App p-10">
      <QRCode
        level="Q"
        style={{ width: 256 }}
        value={JSON.stringify(qrProofRequestJson)}
      />
    </div>
  )
};

// Exports
// ========================================================
export default App;
