// Fix admin password hash in database
const { Client } = require('pg');
const bcrypt = require('bcrypt');
const fs = require('fs');

async function fix() {
  const client = new Client({
    host: 'localhost', port: 5432, user: 'postgres',
    password: 'tumiri', database: 'minimarket_db'
  });
  
  await client.connect();
  
  // Generate correct hash for Admin123!
  const hash = await bcrypt.hash('Admin123!', 12);
  
  // Update admin user
  const result = await client.query(
    `UPDATE usuarios SET password_hash = $1 WHERE username = 'admin' RETURNING username, email`,
    [hash]
  );
  
  // Also reset any lockout
  await client.query(
    `UPDATE usuarios SET intentos_fallidos = 0, bloqueado_hasta = NULL WHERE username = 'admin'`
  );
  
  await client.end();
  
  fs.writeFileSync('fix-result.txt',
    `Updated: ${JSON.stringify(result.rows)}\nNew hash: ${hash}\nPassword: Admin123!`
  );
}

fix().catch(e => {
  require('fs').writeFileSync('fix-result.txt', 'ERROR: ' + e.message);
});
