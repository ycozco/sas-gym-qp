import { Test, TestingModule } from '@nestjs/testing';
import { MembersService } from './members.service';
import { PrismaService } from '../../prisma/prisma.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';

describe('MembersService — freeze/unfreeze', () => {
  let service: MembersService;
  let prisma: jest.Mocked<PrismaService>;

  const mockMembership = {
    id: 'mem-001',
    tenant_id: 'tenant-001',
    congelada: false,
    fecha_vencimiento: new Date('2026-07-30T00:00:00.000Z'),
    freezes: [],
    user_id: 'user-001',
    plan_id: null,
    plan_nombre: 'Mensual',
    duracion_dias: 30,
    monto: 100,
    estado: 'ACTIVE',
    fecha_inicio: new Date(),
    payments: [],
    created_at: new Date(),
    updated_at: new Date(),
    descuento_porcentaje: 0,
    descuento_monto: 0,
    precio_pagado: 100,
    monto_pendiente: 0,
    pago_completo: true,
    fecha_traspaso: null,
    razon_traspaso: null,
    usuario_original_id: null,
    traspasada_a_id: null,
  };

  const mockFreeze = {
    id: 'freeze-001',
    membership_id: 'mem-001',
    fecha_congelacion: new Date('2026-06-10T00:00:00.000Z'),
    fecha_descongelacion: null,
    razon: 'Viaje al exterior',
    created_at: new Date(),
  };

  beforeEach(async () => {
    const txMock = {
      membershipFreeze: {
        create: jest.fn().mockResolvedValue(mockFreeze),
        update: jest.fn().mockResolvedValue({ ...mockFreeze, fecha_descongelacion: new Date() }),
      },
      membership: {
        update: jest.fn().mockResolvedValue({ ...mockMembership, congelada: true, freezes: [mockFreeze] }),
      },
    };

    const prismaMock = {
      membership: {
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      user: {
        findMany: jest.fn(),
      },
      $transaction: jest.fn().mockImplementation((fn) => fn(txMock)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MembersService,
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    service = module.get<MembersService>(MembersService);
    prisma = module.get(PrismaService);
  });

  // ─── freezeMembership ──────────────────────────────────────────────
  describe('freezeMembership', () => {
    it('should freeze an active membership successfully', async () => {
      (prisma.membership.findFirst as jest.Mock).mockResolvedValue(mockMembership);

      const result = await service.freezeMembership('mem-001', 'tenant-001', {
        razon: 'Viaje al exterior',
      });

      expect(result.success).toBe(true);
      expect(result.freeze.razon).toBe('Viaje al exterior');
    });

    it('should throw NotFoundException if membership not found', async () => {
      (prisma.membership.findFirst as jest.Mock).mockResolvedValue(null);

      await expect(
        service.freezeMembership('mem-999', 'tenant-001', { razon: 'Test' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException if already frozen', async () => {
      (prisma.membership.findFirst as jest.Mock).mockResolvedValue({
        ...mockMembership,
        congelada: true,
      });

      await expect(
        service.freezeMembership('mem-001', 'tenant-001', { razon: 'Test' }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ─── unfreezeMembership ────────────────────────────────────────────
  describe('unfreezeMembership', () => {
    it('should throw BadRequestException if membership is not frozen', async () => {
      (prisma.membership.findFirst as jest.Mock).mockResolvedValue({
        ...mockMembership,
        congelada: false,
        freezes: [],
      });

      await expect(
        service.unfreezeMembership('mem-001', 'tenant-001'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw NotFoundException if membership not found', async () => {
      (prisma.membership.findFirst as jest.Mock).mockResolvedValue(null);

      await expect(
        service.unfreezeMembership('mem-999', 'tenant-001'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ─── findAll ───────────────────────────────────────────────────────
  describe('findAll', () => {
    it('should query members using prisma.user.findMany with pagination filters', async () => {
      const mockUsers = [{ id: 'user-1' }, { id: 'user-2' }];
      (prisma.user as any).findMany.mockResolvedValue(mockUsers);

      const result = await service.findAll('tenant-123', 10, 'user-0');

      expect((prisma.user as any).findMany).toHaveBeenCalledWith({
        take: 10,
        skip: 1,
        cursor: { id: 'user-0' },
        where: {
          tenant_id: 'tenant-123',
          rol: 'MEMBER',
        },
        orderBy: { id: 'asc' },
        include: {
          memberships: { orderBy: { fecha_vencimiento: 'desc' }, take: 1 },
        },
      });
      expect(result).toEqual(mockUsers);
    });
  });
});
