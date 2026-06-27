import { Test, TestingModule } from '@nestjs/testing';
import { SaasGateway } from './saas.gateway';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { Socket } from 'socket.io';
import { BiometricHandshakeDto } from '../../modules/biometric/biometric-handshake.dto';

describe('SaasGateway — biometric-handshake', () => {
  let gateway: SaasGateway;
  let prisma: jest.Mocked<PrismaService>;
  let jwtService: jest.Mocked<JwtService>;
  let mockSocket: any;
  let mockServer: any;

  const mockDto: BiometricHandshakeDto = {
    dispositivoId: 'zkteco-01',
    datosHuella: 'YmFzZTY0X2ZpbmdlcnByaW50X3RlbXBsYXRl',
    hashVerificacion:
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    tokenRegistro: 'd3b07384-d113-4a11-a5c1-e0e0a51c4a01',
  };

  const mockUser = {
    id: 'user-001',
    tenant_id: 'tenant-001',
    nombre_completo: 'Juan Perez',
    dni: '77777777',
    rol: 'MEMBER',
    memberships: [
      {
        id: 'mem-001',
        estado: 'ACTIVE',
        fecha_vencimiento: new Date(),
      },
    ],
  };

  const mockFingerprint = {
    id: 'fp-001',
    usuario_id: 'user-001',
    dedo: 'pulgar_der',
    datos_huella: 'YmFzZTY0X2ZpbmdlcnByaW50X3RlbXBsYXRl',
    hash_verificacion:
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    token_registro: 'd3b07384-d113-4a11-a5c1-e0e0a51c4a01',
    usuario: mockUser,
  };

  beforeEach(async () => {
    jwtService = {
      verifyAsync: jest.fn(),
    } as any;

    const txMock = {
      fingerprintAttendance: {
        create: jest.fn().mockResolvedValue({}),
      },
      attendance: {
        create: jest.fn().mockResolvedValue({}),
      },
    };

    prisma = {
      fingerprint: {
        findUnique: jest.fn(),
      },
      $transaction: jest.fn().mockImplementation((fn) => fn(txMock)),
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SaasGateway,
        { provide: JwtService, useValue: jwtService },
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    gateway = module.get<SaasGateway>(SaasGateway);

    mockSocket = {
      id: 'socket-client-123',
      emit: jest.fn(),
      disconnect: jest.fn(),
      handshake: {
        address: '192.168.10.15',
        auth: { token: 'valid-token' },
      },
    };

    mockServer = {
      to: jest.fn().mockReturnValue({
        emit: jest.fn(),
      }),
    };

    gateway.server = mockServer;
  });

  it('debe rechazar el acceso si la huella no está registrada', async () => {
    (prisma.fingerprint.findUnique as jest.Mock).mockResolvedValue(null);

    const result = await gateway.handleBiometricHandshake(mockSocket, mockDto);

    expect(result.success).toBe(false);
    expect(result.reason).toBe('Huella digital no registrada.');
    expect(mockSocket.emit).toHaveBeenCalledWith('biometric-rejected', {
      reason: 'Huella digital no registrada.',
    });
  });

  it('debe rechazar el acceso si la integridad del hash de la huella falla', async () => {
    (prisma.fingerprint.findUnique as jest.Mock).mockResolvedValue({
      ...mockFingerprint,
      hash_verificacion: 'different-hash', // Diferente de mockDto.hashVerificacion
    });

    const result = await gateway.handleBiometricHandshake(mockSocket, mockDto);

    expect(result.success).toBe(false);
    expect(result.reason).toBe('Firma de huella inválida.');
    expect(mockSocket.emit).toHaveBeenCalledWith('biometric-rejected', {
      reason: 'Error de integridad en los datos biométricos.',
    });
  });

  it('debe rechazar el acceso y emitir RED al administrador si la membresía está vencida', async () => {
    const expiredUser = {
      ...mockUser,
      memberships: [
        {
          id: 'mem-001',
          estado: 'EXPIRED',
          fecha_vencimiento: new Date(),
        },
      ],
    };

    (prisma.fingerprint.findUnique as jest.Mock).mockResolvedValue({
      ...mockFingerprint,
      usuario: expiredUser,
    });

    const result = await gateway.handleBiometricHandshake(mockSocket, mockDto);

    expect(result.success).toBe(false);
    expect(result.reason).toBe('Membresía inactiva.');
    expect(mockSocket.emit).toHaveBeenCalledWith('biometric-rejected', {
      reason: 'Membresía no activa.',
    });
    expect(mockServer.to).toHaveBeenCalledWith('tenant-001');
  });

  it('debe autorizar el acceso, registrar asistencias y abrir la puerta si la membresía está activa', async () => {
    (prisma.fingerprint.findUnique as jest.Mock).mockResolvedValue(
      mockFingerprint,
    );

    const result = await gateway.handleBiometricHandshake(mockSocket, mockDto);

    expect(result.success).toBe(true);
    expect(mockSocket.emit).toHaveBeenCalledWith(
      'OPEN_GATE',
      expect.any(Object),
    );
    expect(mockServer.to).toHaveBeenCalledWith('tenant-001');
    expect(prisma.$transaction).toHaveBeenCalled();
  });
});
