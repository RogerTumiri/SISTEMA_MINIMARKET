const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
const out = [];
const log = (msg) => { out.push(msg); };

const config = {
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: 'tumiri',
  database: 'postgres',
};

async function setup() {
  const client = new Client(config);
  try {
    await client.connect();
    log('CONNECTED OK');

    const { rows } = await client.query("SELECT 1 FROM pg_database WHERE datname='minimarket_db'");
    if (rows.length === 0) {
      await client.query('CREATE DATABASE minimarket_db');
      log('CREATED DATABASE minimarket_db');
    } else {
      log('DB EXISTS minimarket_db');
    }
    await client.end();
  } catch (err) {
    log('ERROR_CONNECT: ' + err.message);
    fs.writeFileSync('db-result.txt', out.join('\n'));
    process.exit(1);
  }

  const dbClient = new Client({ ...config, database: 'minimarket_db' });
  try {
    await dbClient.connect();
    log('CONNECTED minimarket_db');

    const { rows: existing } = await dbClient.query("SELECT to_regclass('public.roles') as tbl");
    if (existing[0].tbl) {
      log('SCHEMA EXISTS');
      const { rows: adminRows } = await dbClient.query("SELECT username FROM usuarios WHERE username='admin'");
      if (adminRows.length > 0) {
        log('ADMIN USER EXISTS: admin / Admin123!');
      } else {
        log('ADMIN NOT FOUND - inserting');
        await dbClient.query(`INSERT INTO usuarios (rol_id, nombre_completo, email, username, password_hash)
          VALUES (1, 'Administrador del Sistema', 'admin@minimarket.com', 'admin',
                  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LGqvB2pUbJ0ZWZoOa')
          ON CONFLICT (username) DO NOTHING`);
        log('ADMIN CREATED');
      }
    } else {
      log('APPLYING SCHEMA');
      const sqlFile = path.join(__dirname, 'src', 'database', 'migrations', '001_initial_schema.sql');
      const sql = fs.readFileSync(sqlFile, 'utf8');
      await dbClient.query(sql);
      log('SCHEMA APPLIED');
      log('ADMIN USER CREATED: admin / Admin123!');
    }
    await dbClient.end();
  } catch (err) {
    log('ERROR_DB: ' + err.message);
    fs.writeFileSync('db-result.txt', out.join('\n'));
    process.exit(1);
  }

  fs.writeFileSync('db-result.txt', out.join('\n'));
}

setup();
