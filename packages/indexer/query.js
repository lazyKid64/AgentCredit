const https = require('https');

const query = JSON.stringify({
  query: '{ agentCreditScores(first: 5) { id computedScore totalPayments totalVolume lastUpdated } agentPayments(first: 5, orderBy: timestamp, orderDirection: desc) { id agent amount timestamp blockNumber } }'
});

const options = {
  hostname: 'api.studio.thegraph.com',
  path: '/query/1755606/agentcredit/0.0.1',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(query),
  },
};

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    console.log(JSON.stringify(JSON.parse(data), null, 2));
  });
});

req.on('error', (e) => { console.error('Error:', e.message); });
req.write(query);
req.end();
