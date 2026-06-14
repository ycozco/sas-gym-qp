import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { getCorsOrigins, getJwtSecret } from '../config/env';
import { PrismaService } from '../../prisma/prisma.service';
import { BiometricHandshakeDto } from '../../modules/biometric/biometric-handshake.dto';
import { UsePipes, ValidationPipe } from '@nestjs/common';

@WebSocketGateway({ cors: { origin: getCorsOrigins(), credentials: true } })
export class SaasGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth?.token as string | undefined;
      if (!token) {
        console.log(`Cliente WebSocket sin token desconectado: ${client.id}`);
        client.disconnect();
        return;
      }

      const payload = await this.jwtService.verifyAsync(token, {
        secret: getJwtSecret(),
      });

      client.data.user = payload;
      console.log(`Cliente WebSocket autenticado: ${client.id}`);
    } catch {
      console.log(
        `Cliente WebSocket con token invalido desconectado: ${client.id}`,
      );
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    console.log(`Cliente WebSocket desconectado: ${client.id}`);
  }

  @SubscribeMessage('join')
  handleJoinRoom(client: Socket) {
    const user = client.data.user;
    if (user && user.tenantId) {
      client.join(user.tenantId);
      console.log(`Cliente WebSocket unido a sala tenant: ${client.id}`);
    }
  }

  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  @SubscribeMessage('biometric-handshake')
  async handleBiometricHandshake(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: BiometricHandshakeDto,
  ) {
    const fingerprint = await this.prisma.fingerprint.findUnique({
      where: { token_registro: dto.tokenRegistro },
      include: {
        usuario: {
          include: {
            memberships: {
              orderBy: { fecha_vencimiento: 'desc' },
              take: 1,
            },
          },
        },
      },
    });

    if (!fingerprint) {
      client.emit('biometric-rejected', { reason: 'Huella digital no registrada.' });
      return { success: false, reason: 'Huella digital no registrada.' };
    }

    // Verificar integridad del hash
    if (fingerprint.hash_verificacion !== dto.hashVerificacion) {
      client.emit('biometric-rejected', { reason: 'Error de integridad en los datos biométricos.' });
      return { success: false, reason: 'Firma de huella inválida.' };
    }

    const user = fingerprint.usuario;

    // Verificar si el usuario tiene membresía activa o en periodo de gracia
    const activeMembership = user.memberships[0];
    const isApproved =
      activeMembership &&
      (activeMembership.estado === 'ACTIVE' || activeMembership.estado === 'GRACE');

    if (!isApproved) {
      // Registrar intento fallido
      client.emit('biometric-rejected', { reason: 'Membresía no activa.' });

      // Emitir al panel del admin en tiempo real (si está en la sala)
      this.server.to(user.tenant_id).emit('attendance_registered', {
        user: {
          nombre_completo: user.nombre_completo,
          dni: user.dni,
          rol: user.rol,
        },
        verdict: 'RED',
        reason: 'Intento de ingreso con membresía inactiva/vencida.',
      });

      return { success: false, reason: 'Membresía inactiva.' };
    }

    // Registrar asistencia biométrica
    const ip = client.handshake.address || client.conn.remoteAddress || 'unknown';
    await this.prisma.$transaction(async (tx) => {
      await tx.fingerprintAttendance.create({
        data: {
          usuario_id: user.id,
          huella_id: fingerprint.id,
          dispositivo_id: dto.dispositivoId,
          ip_origen: ip,
        },
      });

      // Crear entrada de asistencia general
      await tx.attendance.create({
        data: {
          tenant_id: user.tenant_id,
          user_id: user.id,
          metodo_acceso: 'QR_AUTONOMOUS', // Usamos este método autónomo para el torniquete
        },
      });
    });

    // Emitir señal de apertura al dispositivo físico (OPEN_GATE)
    client.emit('OPEN_GATE', {
      authorized: true,
      userName: user.nombre_completo,
      timestamp: new Date(),
    });

    // Emitir confirmación en tiempo real al panel del administrador del gimnasio
    this.server.to(user.tenant_id).emit('attendance_registered', {
      user: {
        nombre_completo: user.nombre_completo,
        dni: user.dni,
        rol: user.rol,
      },
      verdict: activeMembership.estado === 'GRACE' ? 'AMBER' : 'GREEN',
      reason: activeMembership.estado === 'GRACE'
        ? 'Ingreso autorizado en día de gracia.'
        : 'Ingreso autorizado.',
    });

    return { success: true, message: 'Acceso autorizado y puerta abierta.' };
  }

  emitTenantSuspended(tenantId: string) {
    if (this.server) {
      this.server.to(tenantId).emit('tenant_suspended');
      console.log('Emitido evento de suspension de tenant');
    }
  }
}
