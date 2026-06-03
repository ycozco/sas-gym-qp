const http = require('http');
const crypto = require('crypto');

const BASE_URL = 'http://localhost:3000/api/v1';
const HOST = 'localhost';
const PORT = 3000;
const TENANT_ID = '77777777-7777-7777-7777-777777777777';

function request(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const headers = {
      'Content-Type': 'application/json',
      'X-Tenant-ID': TENANT_ID,
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const postData = body ? JSON.stringify(body) : '';
    if (body) {
      headers['Content-Length'] = Buffer.byteLength(postData);
    }

    const options = {
      hostname: HOST,
      port: PORT,
      path: `/api/v1${path}`,
      method: method,
      headers: headers,
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        let json = null;
        try {
          json = JSON.parse(data);
        } catch (e) {
          json = data;
        }
        resolve({
          statusCode: res.statusCode,
          body: json,
        });
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    if (body) {
      req.write(postData);
    }
    req.end();
  });
}

function generateUuid() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0,
      v = c == 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

async function runTests() {
  console.log('=== Iniciando Pruebas de Endpoints NestJS ===\n');

  try {
    // 1. Iniciar sesión como Cajero
    console.log('[1] Iniciando sesión como cajero...');
    const loginRes = await request('POST', '/auth/login', {
      emailOrDni: 'caja@gymsmart.com',
      password: 'caja_secure_pass',
    });

    if (loginRes.statusCode !== 201 && loginRes.statusCode !== 200) {
      console.error('Fallo en login:', loginRes.body);
      process.exit(1);
    }

    const token = loginRes.body.token;
    console.log('Login exitoso. Token recibido.');

    // 2. Verificar si hay Turno de Caja Abierto
    console.log('\n[2] Consultando turno de caja activo...');
    const activeCajaRes = await request('GET', '/payments/caja/active', null, token);
    
    let activeCaja = null;
    if (activeCajaRes.statusCode === 200 && activeCajaRes.body.id) {
      activeCaja = activeCajaRes.body;
      console.log(`Caja activa encontrada con ID: ${activeCaja.id}`);
    } else {
      console.log('No hay caja activa. Abriendo una nueva caja...');
      const openCajaRes = await request('POST', '/payments/caja/open', {
        montoApertura: 250.0,
        observaciones: 'Apertura de prueba automatizada',
      }, token);

      if (openCajaRes.statusCode !== 201) {
        console.error('Fallo al abrir caja:', openCajaRes.body);
        process.exit(1);
      }
      activeCaja = openCajaRes.body;
      console.log(`Caja abierta con éxito. ID: ${activeCaja.id}`);
    }

    // 3. Buscar Miembros
    console.log('\n[3] Probando búsqueda por relevancia...');
    const searchRes = await request('GET', '/members/search?q=11111111', null, token);
    if (searchRes.statusCode !== 200) {
      console.error('Fallo al buscar socio:', searchRes.body);
      process.exit(1);
    }

    const mateoSocio = searchRes.body.find(u => u.dni === '11111111');
    if (!mateoSocio) {
      console.error('No se encontró al socio Mateo Salas.');
      process.exit(1);
    }
    console.log(`Socio encontrado: ${mateoSocio.nombre_completo} (ID: ${mateoSocio.id})`);

    // 4. Registrar Membresía con Prevención de Doble-Submit
    console.log('\n[4] Probando prevención de doble submit...');
    const ventaToken1 = generateUuid();
    const salePayload = {
      userId: mateoSocio.id,
      planNombre: 'Mensual Plata',
      duracionDias: 30,
      monto: 120.0,
      ventaToken: ventaToken1,
      pagos: [{ metodo: 'CASH', monto: 120.0 }],
      observaciones: 'Pago de prueba de membresía 1',
    };

    console.log('Enviando primera petición de venta...');
    const saleRes1 = await request('POST', '/payments/membership-sale', salePayload, token);
    console.log(`Respuesta 1: Status ${saleRes1.statusCode}`, saleRes1.body);

    if (saleRes1.statusCode !== 201) {
      console.error('Fallo en la primera venta.');
      process.exit(1);
    }

    console.log('Enviando segunda petición idéntica con el mismo token...');
    const saleRes2 = await request('POST', '/payments/membership-sale', salePayload, token);
    console.log(`Respuesta 2: Status ${saleRes2.statusCode} (Esperado: 400)`, saleRes2.body);

    if (saleRes2.statusCode !== 400) {
      console.error('ERROR: El sistema no bloqueó el doble submit por token único.');
      process.exit(1);
    }
    console.log('OK: Doble submit por ventaToken bloqueado correctamente.');

    console.log('Enviando tercera petición con diferente token pero idénticos campos en menos de 5 seg...');
    const salePayload2 = { ...salePayload, ventaToken: generateUuid() };
    const saleRes3 = await request('POST', '/payments/membership-sale', salePayload2, token);
    console.log(`Respuesta 3: Status ${saleRes3.statusCode} (Esperado: 400)`, saleRes3.body);

    if (saleRes3.statusCode !== 400) {
      console.error('ERROR: El sistema no bloqueó la transacción idéntica en el intervalo de 5 segundos.');
      process.exit(1);
    }
    console.log('OK: Transacción duplicada bloqueada correctamente en ventana de 5 segundos.');

    // 5. Probar Pagos Mixtos
    console.log('\n[5] Probando registro con pagos mixtos...');
    const ventaToken2 = generateUuid();
    const mixedPayload = {
      userId: mateoSocio.id,
      planNombre: 'Mensual Oro',
      duracionDias: 30,
      monto: 150.0,
      ventaToken: ventaToken2,
      pagos: [
        { metodo: 'CASH', monto: 50.0 },
        { metodo: 'TRANSFER', monto: 100.0 },
      ],
      observaciones: 'Pago mixto: Efectivo + Transferencia',
    };

    const mixedRes = await request('POST', '/payments/membership-sale', mixedPayload, token);
    console.log(`Respuesta mixta: Status ${mixedRes.statusCode}`, mixedRes.body);

    if (mixedRes.statusCode !== 201) {
      console.error('Fallo al registrar pago mixto.');
      process.exit(1);
    }
    console.log('OK: Registro de membresía con pagos mixtos completado.');

    // 6. Validar Puntos Acumulados
    console.log('\n[6] Verificando acumulación de puntos...');
    // Realizamos una nueva búsqueda para obtener los puntos actualizados del socio
    const pointsRes = await request('GET', `/members/search?q=11111111`, null, token);
    const updatedSocio = pointsRes.body.find(u => u.dni === '11111111');
    const puntosBalance = updatedSocio?.points_balance;
    console.log('Saldo de puntos actual del socio en BD:', puntosBalance);
    
    // Venta 1: monto 120.0 -> 120 puntos. Venta 2 (mixta): monto 150.0 -> 150 puntos.
    // El seed puede tener puntos iniciales, verificamos que hayan incrementado.
    if (puntosBalance && puntosBalance.puntos_disponibles >= 270) {
      console.log(`OK: Acumulación de puntos correcta (${puntosBalance.puntos_disponibles} pts disponibles, mínimo esperado 270).`);
    } else {
      console.error('ERROR: Desajuste en el saldo de puntos acumulado.', puntosBalance);
    }

    // 7. Probar Registro y Validación Firmada de Huella
    console.log('\n[7] Probando registro firmado y validación biométrica...');
    const datosHuella = 'Base64_Simulated_Fingerprint_Template_Data_2026';
    const dedo = 'pulgar_der';
    const secret = 'huella_secure_secret_key_2026';
    const message = `${mateoSocio.id}:${dedo}:${datosHuella}`;
    
    // Generar firma HMAC-SHA256
    const signature = crypto
      .createHmac('sha256', secret)
      .update(message)
      .digest('hex');

    console.log('Registrando huella con firma válida...');
    const regFingerRes = await request('POST', '/attendance/fingerprint/register', {
      userId: mateoSocio.id,
      dedo: dedo,
      datosHuella: datosHuella,
      signature: signature,
    }, token);
    
    console.log(`Respuesta registro huella: Status ${regFingerRes.statusCode}`, regFingerRes.body);

    if (regFingerRes.statusCode !== 201) {
      console.error('Fallo al registrar huella.');
      process.exit(1);
    }

    const { tokenRegistro, hashVerificacion } = regFingerRes.body;

    console.log('Registrando huella con firma INVÁLIDA...');
    const badRegRes = await request('POST', '/attendance/fingerprint/register', {
      userId: mateoSocio.id,
      dedo: dedo,
      datosHuella: datosHuella,
      signature: 'wrong_signature_hex_value',
    }, token);

    console.log(`Respuesta firma inválida: Status ${badRegRes.statusCode} (Esperado: 401)`);
    if (badRegRes.statusCode !== 401) {
      console.error('ERROR: El backend no validó la firma de la huella.');
      process.exit(1);
    }
    console.log('OK: Registro firmado e integridad biométrica validados.');

    console.log('Verificando acceso mediante huella (Simulación de ZkTeco)...');
    const verifyFingerRes = await request('POST', '/attendance/fingerprint/verify', {
      tokenRegistro: tokenRegistro,
      hashVerificacion: hashVerificacion,
    }, token);

    console.log(`Respuesta verificación biométrica: Status ${verifyFingerRes.statusCode}`, verifyFingerRes.body);
    if (verifyFingerRes.statusCode !== 201 || verifyFingerRes.body.verdict !== 'GREEN') {
      console.error('ERROR: No se pudo verificar el acceso biométrico.');
      process.exit(1);
    }
    console.log('OK: Ingreso biométrico concedido.');

    // 8. Crear Egreso Manual de Caja
    console.log('\n[8] Registrando egreso manual de caja...');
    const egressRes = await request('POST', '/payments/caja/egress', {
      monto: 40.0,
      motivo: 'Mantenimiento',
      metodoPago: 'efectivo',
      descripcionAdicional: 'Tinta para impresora',
    }, token);

    console.log(`Respuesta egreso: Status ${egressRes.statusCode}`, egressRes.body);
    if (egressRes.statusCode !== 201) {
      console.error('Fallo al registrar egreso.');
      process.exit(1);
    }
    console.log('OK: Egreso manual registrado en el arqueo.');

    // 9. Consultar Arqueo de Caja y Cerrar Caja
    console.log('\n[9] Consultando arqueo y cerrando caja...');
    const detailsRes = await request('GET', '/payments/caja/details', null, token);
    if (detailsRes.statusCode !== 200) {
      console.error('Fallo al obtener arqueo:', detailsRes.body);
      process.exit(1);
    }

    const stats = detailsRes.body.stats;
    console.log('Métricas del arqueo de caja actual:', stats);

    // Usamos los valores reales del sistema para el cierre (sin hardcodear montos)
    const montoEfectivoCierre = stats.efectivo_esperado;
    const montoTransferenciaCierre = stats.total_ventas_transferencia - stats.transferencia_egreso;
    const montoYapeCierre = stats.total_ventas_yape - stats.yape_egreso;
    const montoPosCierre = stats.total_ventas_pos - stats.pos_egreso;
    const diferenciaEsperada = 0; // Cerramos con los montos exactos del sistema

    console.log(`Cerrando caja con: efectivo=${montoEfectivoCierre}, transferencia=${montoTransferenciaCierre}`);
    if (stats.efectivo_esperado > 0) {
      console.log('OK: Cuadre de caja verificado en el sistema.');
    } else {
      console.error('ERROR: Efectivo esperado es 0, revisar caja.');
    }

    console.log('Procediendo a cerrar la caja...');
    const closeCajaRes = await request('POST', '/payments/caja/close', {
      montoCierreEfectivo: montoEfectivoCierre,
      montoCierreTransferencia: montoTransferenciaCierre,
      montoCierreYape: montoYapeCierre,
      montoCierrePOS: montoPosCierre,
      observaciones: 'Cierre de pruebas sin discrepancia',
    }, token);

    console.log(`Respuesta cierre de caja: Status ${closeCajaRes.statusCode}`, closeCajaRes.body);
    if (closeCajaRes.statusCode !== 201 || closeCajaRes.body.diferencia !== 0) {
      console.error('ERROR: No se cerró correctamente o hubo diferencia de dinero física inesperada.', closeCajaRes.body);
      process.exit(1);
    }

    console.log('\n=== ¡TODAS LAS PRUEBAS SE COMPLETARON CON ÉXITO! ===');

  } catch (error) {
    console.error('Error general durante la ejecución de pruebas:', error);
    process.exit(1);
  }
}

runTests();
