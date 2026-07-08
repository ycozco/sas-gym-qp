import { spawn } from 'node:child_process';

const apiBase = 'http://localhost:3000/api/v1';

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function runCommand(command, args) {
  return new Promise((resolve) => {
    const child = spawn(command, args, { shell: true, stdio: 'inherit' });
    child.on('close', (code) => resolve(code === 0));
  });
}

async function testAuthAndRateLimiting() {
  console.log('=== TEST DE AUTENTICACIÓN Y STRÉSS DE RATE LIMITING ===\n');

  // 1. Probar Login Exitoso (Autenticación)
  console.log('1. Probando Autenticación con credenciales válidas...');
  const loginRes = await fetch(`${apiBase}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      emailOrDni: 'admin1.surco@test.sasgym.com',
      password: 'admin_secure_pass'
    })
  });

  if (!loginRes.ok) {
    console.error(`❌ Falló el login inicial. Status: ${loginRes.status}`);
    process.exit(1);
  }

  const loginData = await loginRes.json();
  const token = loginData.token;
  const tenantId = loginData.tenantId;
  console.log(`✅ Autenticación exitosa! Token recibido: ${token.substring(0, 20)}...`);

  // Probar /auth/me con el token
  console.log('2. Obteniendo datos del perfil (/auth/me)...');
  const meRes = await fetch(`${apiBase}/auth/me`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'X-Tenant-ID': tenantId
    }
  });

  if (!meRes.ok) {
    console.error(`❌ Falló /auth/me. Status: ${meRes.status}`);
    process.exit(1);
  }

  const meData = await meRes.json();
  console.log(`✅ Datos de usuario cargados: ID=${meData.id}, Email=${meData.email}, Rol=${meData.rol}\n`);

  // 2. Probar Rate Limiting (Fuerza bruta)
  console.log('3. Probando Rate Limiting (5 intentos fallidos consecutivos)...');
  const testEmail = 'stress-test@gym.com';

  for (let i = 1; i <= 5; i++) {
    console.log(`Enviando intento fallido #${i}...`);
    const failRes = await fetch(`${apiBase}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        emailOrDni: testEmail,
        password: 'incorrect_password'
      })
    });
    console.log(`   Respuesta #${i}: Status ${failRes.status}`);
  }

  // 3. El 6to intento debe dar 429 (Bloqueo activo)
  console.log('\n4. Enviando 6to intento (esperando bloqueo 429)...');
  const blockedRes = await fetch(`${apiBase}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      emailOrDni: testEmail,
      password: 'any_password'
    })
  });

  console.log(`   Respuesta del 6to intento: Status ${blockedRes.status}`);
  const blockData = await blockedRes.json();
  console.log(`   Mensaje de respuesta: "${blockData.message}"`);

  if (blockedRes.status === 429) {
    console.log('\n🎉 ¡PRUEBA SUPERADA! El sistema bloqueó correctamente tras 5 intentos fallidos.');
  } else {
    console.error('\n❌ FALLÓ LA PRUEBA: El 6to intento no fue bloqueado con status 429.');
  }

  // 4. Limpiar Redis para no dejar el entorno bloqueado
  console.log('\n5. Limpiando contadores y llaves de bloqueo en Redis...');
  await runCommand('docker', ['exec', 'gymsmart-redis', 'redis-cli', 'FLUSHALL']);
  console.log('✅ Redis limpiado con éxito.');
}

testAuthAndRateLimiting().catch((err) => {
  console.error('Error en la prueba:', err);
});
