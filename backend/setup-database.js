// ============================================================
// Script de configuración inicial de la base de datos
// Ejecutar: node setup-database.js
// ============================================================
const { Client } = require('pg');
const bcrypt = require('bcrypt');

const DB_CONFIG = {
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: 'tumiri',
  database: 'postgres', // conectar a db por defecto primero
};

async function setup() {
  console.log('🚀 Configurando base de datos MiniMarket...\n');

  // 1. Crear base de datos si no existe
  const adminClient = new Client(DB_CONFIG);
  await adminClient.connect();

  const dbExists = await adminClient.query(
    "SELECT 1 FROM pg_database WHERE datname = 'minimarket_db'"
  );

  if (dbExists.rows.length === 0) {
    console.log('📦 Creando base de datos minimarket_db...');
    await adminClient.query('CREATE DATABASE minimarket_db');
    console.log('   ✅ Base de datos creada');
  } else {
    console.log('   ✅ Base de datos minimarket_db ya existe');
  }
  await adminClient.end();

  // 2. Conectar a minimarket_db y verificar esquema
  const appClient = new Client({ ...DB_CONFIG, database: 'minimarket_db' });
  await appClient.connect();

  // Habilitar extensiones
  await appClient.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
  await appClient.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');

  // Verificar si la tabla roles existe (indicador de si el schema fue aplicado)
  const tablesExist = await appClient.query(
    "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='roles'"
  );

  if (tablesExist.rows.length === 0) {
    console.log('📋 Aplicando esquema inicial...');
    const fs = require('fs');
    const path = require('path');
    const sqlPath = path.join(__dirname, 'src/database/migrations/001_initial_schema.sql');

    if (fs.existsSync(sqlPath)) {
      const sql = fs.readFileSync(sqlPath, 'utf8');
      await appClient.query(sql);
      console.log('   ✅ Esquema aplicado correctamente');
    } else {
      console.log('   ⚠️  Archivo SQL no encontrado:', sqlPath);
    }
  } else {
    console.log('   ✅ Esquema ya existe en la base de datos');
  }

  // 3. Verificar usuario admin
  console.log('\n👤 Verificando usuario administrador...');
  const adminUser = await appClient.query(
    "SELECT id, username, password_hash, intentos_fallidos, bloqueado_hasta FROM usuarios WHERE username = 'admin'"
  );

  const correctHash = await bcrypt.hash('Admin123!', 12);

  if (adminUser.rows.length === 0) {
    console.log('   Creando usuario admin...');
    // Obtener rol admin
    const rolResult = await appClient.query(
      "SELECT id FROM roles WHERE nombre = 'ADMINISTRADOR' LIMIT 1"
    );
    if (rolResult.rows.length > 0) {
      await appClient.query(
        `INSERT INTO usuarios (rol_id, nombre_completo, email, username, password_hash)
         VALUES ($1, 'Administrador del Sistema', 'admin@minimarket.com', 'admin', $2)`,
        [rolResult.rows[0].id, correctHash]
      );
      console.log('   ✅ Usuario admin creado');
    }
  } else {
    // Actualizar password y quitar bloqueos
    await appClient.query(
      `UPDATE usuarios 
       SET password_hash = $1,
           intentos_fallidos = 0,
           bloqueado_hasta = NULL,
           activo = TRUE
       WHERE username = 'admin'`,
      [correctHash]
    );
    console.log('   ✅ Password del admin actualizado y bloqueos removidos');
  }

  await appClient.end();

  console.log('\n================================================================');
  console.log('  ✅ Configuración completada exitosamente!');
  console.log('================================================================');
  console.log('\n  CREDENCIALES DE ACCESO:');
  console.log('  Usuario:   admin');
  console.log('  Password:  Admin123!');
  console.log('  Email:     admin@minimarket.com');
  console.log('\n================================================================\n');
}

setup().catch(err => {
  console.error('\n❌ Error durante la configuración:', err.message);
  console.error(err);
  process.exit(1);
});
