import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';

@WebSocketGateway({ cors: { origin: '*' } })
export class SaasGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private readonly jwtService: JwtService) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth?.token || client.handshake.query?.token as string;
      if (!token) {
        console.log(`Cliente WebSocket sin token desconectado: ${client.id}`);
        client.disconnect();
        return;
      }

      const payload = await this.jwtService.verifyAsync(token, {
        secret: process.env.JWT_SECRET || 'gymsmart_secure_jwt_secret_key_2026',
      });

      client.data.user = payload;
      console.log(`Cliente WebSocket autenticado: ${client.id} (Usuario: ${payload.email}, Tenant: ${payload.tenantId})`);
    } catch (e) {
      console.log(`Cliente WebSocket con token inválido desconectado: ${client.id}`);
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
      console.log(`Cliente ${client.id} se unió a la sala del tenant: ${user.tenantId}`);
    }
  }

  emitTenantSuspended(tenantId: string) {
    if (this.server) {
      this.server.to(tenantId).emit('tenant_suspended');
      console.log(`Emitido evento de suspensión para el tenant: ${tenantId}`);
    }
  }
}
