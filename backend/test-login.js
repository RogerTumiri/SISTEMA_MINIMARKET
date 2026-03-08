// Test login endpoint
const http = require('http');

const postData = JSON.stringify({ username: 'admin', password: 'Admin123!' });
const options = {
  hostname: 'localhost',
  port: 3001,
  path: '/api/v1/auth/login',
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(postData) },
};

const req = http.request(options, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const fs = require('fs');
    fs.writeFileSync('login-test-result.txt', `STATUS: ${res.statusCode}\n${data}`);
  });
});
req.on('error', err => require('fs').writeFileSync('login-test-result.txt', 'ERROR: ' + err.message));
req.write(postData);
req.end();
