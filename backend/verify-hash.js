// Verify and regenerate bcrypt hash for Admin123!
const bcrypt = require('bcrypt');
const fs = require('fs');

async function run() {
  const password = 'Admin123!';
  const existingHash = '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LGqvB2pUbJ0ZWZoOa';
  
  const matches = await bcrypt.compare(password, existingHash);
  const newHash = await bcrypt.hash(password, 12);
  
  fs.writeFileSync('hash-result.txt', 
    `Password: ${password}\nExisting hash matches: ${matches}\nNew hash: ${newHash}`
  );
}
run().catch(e => fs.writeFileSync('hash-result.txt', 'ERROR: ' + e.message));
