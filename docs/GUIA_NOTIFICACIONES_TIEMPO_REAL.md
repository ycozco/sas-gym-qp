# Guía Técnica: Notificaciones, Animaciones y Tiempo Real en GymSmart

Este documento proporciona una guía detallada y mejores prácticas para optimizar el rendimiento de la aplicación en Flutter (animaciones y transición de vistas), el manejo de roles en ambos extremos del stack, y una guía paso a paso para configurar las **notificaciones en tiempo real con Google Firebase Cloud Messaging (FCM)** y **WebSockets**.

---

## 1. Optimización de Animaciones entre Pantallas en Flutter

En Flutter, para lograr transiciones de pantalla con un rendimiento similar al reciclaje de memoria de un `RecyclerView` (Android) o `UICollectionView` (iOS), debemos evitar la reconstrucción innecesaria del árbol de widgets (*rebuilds*) y la sobrecarga en el hilo de rasterización.

### 1.1 Custom PageRouteBuilder (Transiciones Optimizadas)
En lugar de utilizar transiciones por defecto que reconstruyen toda la página de golpe, es preferible utilizar un `PageRouteBuilder` personalizado que realice animaciones de entrada/salida eficientes (como deslizamientos lineales o fundidos):

```dart
// core/router/optimized_route.dart
import 'package:flutter/material.dart';

class OptimizedPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  OptimizedPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Evitamos Opacity widgets directos por consumo de GPU.
            // Usamos FadeTransition y SlideTransition que están optimizados a nivel nativo.
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 280),
        );
}
```

### 1.2 Principios de Alto Rendimiento (Estilo "RecyclerView")
1. **Uso de `const` Estricto**: Marcar los widgets estáticos como `const` para que Flutter los compile una sola vez y no los reevalúe en cada renderizado de la animación de transición.
2. **Listas Reciclables con `ListView.builder`**: Al renderizar catálogos de ejercicios, membresías o logs, utilizar siempre `ListView.builder` en lugar de mapear una lista a una columna. Esto asegura que solo los elementos visibles en pantalla ocupen memoria (reciclaje dinámico).
3. **Reproductores de Ejercicios Aislados**: Envolver el reproductor de animaciones (`CachedExercisePlayer`) en un widget `RepaintBoundary`. Esto aísla el renderizado de la animación para que las actualizaciones en la serie o el cronómetro no fuercen la reconstrucción del lienzo de dibujo o del video.

---

## 2. Manejo de Roles y Rutas Protegidas

El sistema maneja un flujo de seguridad de extremo a extremo, validando los permisos tanto en el cliente como en el servidor.

### 2.1 Lógica en el Cliente (Flutter Guards)
La aplicación almacena el rol del usuario en un estado reactivo (`GymState`). Durante la navegación (usando `go_router` o el stack personalizado), el enrutador valida si el rol tiene acceso a la pantalla solicitada:

```dart
// core/router/role_guard.dart
bool canAccessScreen(GymRole userRole, String screenId) {
  final Map<GymRole, List<String>> rolePermissions = {
    GymRole.superAdmin: ['superadmin-dashboard', 'tenants-list'],
    GymRole.admin: ['dashboard', 'members-crud', 'payments-approve', 'settings', 'scan'],
    GymRole.caja: ['dashboard-shift', 'scan', 'pos-charge', 'members-list'],
    GymRole.trainer: ['students-list', 'exercises-library', 'routines-crud'],
    GymRole.member: ['home', 'weekly-agenda', 'assistant', 'qr-code', 'pay-online'],
  };

  return rolePermissions[userRole]?.contains(screenId) ?? false;
}
```

### 2.2 Lógica en el Backend (NestJS Guards)
En el servidor, los controladores están protegidos mediante decoradores que declaran los roles autorizados. El [RolesGuard](file:///d:/proyectos/sas_gym/backend/src/core/guards/roles.guard.ts) se encarga de interceptar la petición y validar el rol contenido en el JWT:

```typescript
// NestJS Controller Example
@Post('verify')
@Roles(Role.ADMIN, Role.CAJA)
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
async verifyAttendance(...) { ... }
```

---

## 3. Consumo de API en Tiempo Real (WebSockets)

Para actualizaciones críticas (suspensión de gimnasio, confirmación inmediata de pago de membresía o alertas de ingreso denegado), GymSmart utiliza **WebSockets** a través de Socket.io.

### 3.1 Integración en Flutter (Cliente)
```dart
// core/network/websocket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  late IO.Socket socket;

  void initialize(String token, String tenantId, Function onSuspended) {
    socket = IO.io('https://api.gymsmart.com', IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .build());

    socket.onConnect((_) {
      // Unirse al cuarto del Tenant específico para recibir alertas aisladas
      socket.emit('join');
    });

    socket.on('tenant_suspended', (_) {
      onSuspended(); // Bloqueo inmediato de la UI
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
```

---

## 4. Guía Detallada: Configurar Notificaciones Push con Google (FCM)

A continuación, se detalla la configuración paso a paso para integrar las notificaciones en segundo plano e instantáneas usando **Firebase Cloud Messaging (FCM)** en Flutter y NestJS.

---

### Paso 1: Configuración en la Consola de Firebase
1. Ingresa a [Firebase Console](https://console.firebase.google.com/).
2. Crea un proyecto llamado `GymSmart`.
3. Registra tu aplicación móvil:
   - **Android**: Agrega el paquete `com.gymsmart.app` y descarga el archivo `google-services.json`.
   - **iOS**: Agrega el Bundle ID `com.gymsmart.app`, registra la app y descarga `GoogleService-Info.plist`.
4. Ve a la configuración del proyecto (icono de engranaje) -> **Cuentas de Servicio**.
5. Haz clic en **Generar nueva clave privada**. Esto descargará un archivo JSON (ej. `firebase-adminsdk.json`). Guárdalo de forma segura; será usado por el servidor NestJS.

---

### Paso 2: Configuración del Cliente (Flutter)

#### 1. Agregar Dependencias en `pubspec.yaml`
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.1.0
```

#### 2. Colocar Archivos de Credenciales
- Coloca `google-services.json` dentro de `mobile_app/android/app/`.
- Coloca `GoogleService-Info.plist` en `mobile_app/ios/Runner/` a través de Xcode.

#### 3. Inicializar en `main.dart`
```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// Handler de fondo (debe ser una función top-level fuera de clases)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Mensaje recibido en segundo plano: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Registrar el handler de segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const SasGymApp());
}
```

#### 4. Solicitar Permisos y Obtener FCM Token
```dart
// lib/core/notifications/push_notifications.dart
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationsService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Solicitar permisos (Crítico en iOS y Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permiso de notificaciones concedido.');

      // 2. Obtener Token del Dispositivo (FCM Token)
      // Este token debe enviarse al backend en el login para guardarse en la DB
      String? token = await _fcm.getToken();
      print("FCM DEVICE TOKEN: $token");

      // 3. Listener para el primer plano (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Mensaje recibido en primer plano: ${message.notification?.title}");
        // Aquí puedes usar flutter_local_notifications para pintar un banner personalizado.
      });
    } else {
      print('Permiso denegado por el usuario.');
    }
  }
}
```

---

### Paso 3: Configuración del Servidor (NestJS)

#### 1. Instalar Firebase Admin SDK
En el directorio `backend`:
```bash
npm install firebase-admin
```

#### 2. Configurar Variable de Entorno
Copia el archivo JSON de credenciales descargado en el Paso 1 dentro de `backend/src/config/` (o una ruta segura externa) y añade su dirección al archivo `.env`:
```env
FIREBASE_CREDENTIALS_PATH=./src/config/firebase-adminsdk.json
```

#### 3. Crear el Servicio de Notificaciones
```typescript
// backend/src/modules/notifications/notifications.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as path from 'path';

@Injectable()
export class NotificationsService implements OnModuleInit {
  onModuleInit() {
    // Inicializar el SDK de Google Firebase con la cuenta de servicio
    const certPath = path.resolve(process.env.FIREBASE_CREDENTIALS_PATH);
    admin.initializeApp({
      credential: admin.credential.cert(certPath),
    });
    console.log('FCM Firebase Admin SDK inicializado.');
  }

  // Enviar mensaje a un dispositivo específico mediante su Token
  async sendPushNotification(deviceToken: string, title: string, body: string, data?: any) {
    const payload: admin.messaging.Message = {
      token: deviceToken,
      notification: {
        title: title,
        body: body,
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log('Notificación push enviada con éxito:', response);
      return response;
    } catch (error) {
      console.error('Error enviando notificación push de FCM:', error);
      throw error;
    }
  }

  // Enviar mensaje masivo a todos los socios suscritos a un tópico (ej. Anuncios)
  async sendTopicNotification(topic: string, title: string, body: string, data?: any) {
    const payload: admin.messaging.Message = {
      topic: topic,
      notification: {
        title: title,
        body: body,
      },
      data: data || {},
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log(`Mensaje enviado al tópico ${topic} con éxito:`, response);
      return response;
    } catch (error) {
      console.error(`Error enviando notificación a tópico ${topic}:`, error);
      throw error;
    }
  }
}
```

---

## 5. Resumen del Flujo de una Notificación de Vencimiento

Para ilustrar cómo convive todo el sistema de datos, tiempo real y notificaciones:

```
┌──────────────┐           ┌──────────────┐           ┌──────────────┐
│  NestJS Cron │ ────────> │  FCM Server  │ ────────> │  App Socio   │
│ (Evaluación) │           │   (Google)   │           │ (Background) │
└──────────────┘           └──────────────┘           └──────┬───────┘
       │                                                     │
       ▼ (Si hay conexión por socket activa)                 ▼
┌──────────────┐                                      ┌──────────────┐
│ WebSocket    │ ───────────────────────────────────> │ Banner en App│
│ (Real-time)  │                                      │ (Foreground) │
└──────────────┘                                      └──────────────┘
```

1. **Cron Job Diario (NestJS)**: Corre un proceso a medianoche verificando qué membresías vencen en exactamente 7 días.
2. **Consulta a BD**: Identifica los `deviceToken` asociados a los usuarios con membresía por expirar.
3. **Despacho del Push (FCM)**: Llama a `sendPushNotification` con los tokens. Google despacha el mensaje y despierta la app del socio en segundo plano mostrando el banner.
4. **Respaldo en Tiempo Real (WebSocket)**: Si el usuario está entrenando activamente en la app en primer plano, el canal WebSocket transmite directamente el evento, y la app dibuja dinámicamente el banner superior de advertencia `--warning-color` sin interrumpir su rutina actual.
