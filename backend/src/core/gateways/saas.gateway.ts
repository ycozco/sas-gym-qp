import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { getCorsOrigins, getJwtSecret } from '../config/env';

@WebSocketGateway({ cors: { origin: getCorsOrigins(), credentials: true } })
export class SaasGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private readonly jwtService: JwtService) {}

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
      console.log(`Cliente WebSocket con token invalido desconectado: ${client.id}`);
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

  emitTenantSuspended(tenantId: string) {
    if (this.server) {
      this.server.to(tenantId).emit('tenant_suspended');
      console.log('Emitido evento de suspension de tenant');
    }
  }
}
