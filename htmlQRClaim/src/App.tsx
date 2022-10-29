// Imports
// ========================================================
import { QRCode } from 'react-qr-svg';
import proofRequest from '../../proofRequest';

// Config
// ========================================================
// update with your contract address
const DEPLOYED_CONTRACT_ADDRESS = "0xb1e86C4c687B85520eF4fd2a0d14e81970a15aFB";

/**
 * 
 */
let qrProofRequestJson: any = { ...proofRequest };
qrProofRequestJson.body.transaction_data.contract_address = DEPLOYED_CONTRACT_ADDRESS;
qrProofRequestJson.body.scope[0].rules.query.req = {
  // NOTE: this value needs to match the Attribute name in https://platform-test.polygonid.com
  "Date": {
    // NOTE: this value needs to match the erc20ZkpRequest.ts L34 or erc721ZkpRequest.ts L34
    // - $tl = operator 2 erc20ZkpRequest.ts L38
    // - 20020101 = value erc20ZkpRequest.ts L41
    "$lt": 20020101
  }
};
// NOTE1: if you change this you need to resubmit the erc10|erc721ZKPRequest
// NOTE2: type is case-sensitive
// You can generate new schemas via https://platform-test.polygonid.com
qrProofRequestJson.body.scope[0].rules.query.schema = {
  "url": "https://s3.eu-west-1.amazonaws.com/polygonid-schemas/c79191fc-c84e-4203-bb72-4d354839cfb7.json-ld",
  "type": "KYCagecredential"
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
