import { Test, TestingModule } from '@nestjs/testing';
import { DietsController } from './diets.controller';
import { DietsService } from './diets.service';
import { Role } from '@prisma/client';
import { CreateDietPlanDto, UpdateDietPlanDto } from './dto/diet.dto';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';

describe('DietsController', () => {
  let controller: DietsController;
  let service: jest.Mocked<DietsService>;

  const mockUser = {
    sub: 'trainer-uuid',
    tenantId: 'tenant-uuid',
    rol: Role.TRAINER,
  };

  const mockMemberUser = {
    sub: 'member-uuid',
    tenantId: 'tenant-uuid',
    rol: Role.MEMBER,
  };

  const mockDietPlan = {
    id: 'diet-uuid',
    tenant_id: 'tenant-uuid',
    member_id: 'member-uuid',
    trainer_id: 'trainer-uuid',
    peso_objetivo_kg: 75.5,
    calorias_objetivo: 2500,
    proteinas_g: 150,
    carbohidratos_g: 250,
    grasas_g: 70,
    comidas: [
      {
        hora: '08:00',
        nombre: 'Desayuno',
        alimentos: 'Avena y huevos',
        calorias: 500,
      },
    ],
    sugerencias: 'Beber agua',
    activo: true,
    created_at: new Date(),
    updated_at: new Date(),
  };

  beforeEach(async () => {
    const mockDietsService = {
      create: jest.fn(),
      findAll: jest.fn(),
      findActiveForMember: jest.fn(),
      update: jest.fn(),
      deactivate: jest.fn(),
    };

    const mockJwtService = {
      verify: jest.fn(),
      sign: jest.fn(),
    };

    const mockPrismaService = {};

    const module: TestingModule = await Test.createTestingModule({
      controllers: [DietsController],
      providers: [
        { provide: DietsService, useValue: mockDietsService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    controller = module.get<DietsController>(DietsController);
    service = module.get(DietsService);
  });

  it('debe estar definido', () => {
    expect(controller).toBeDefined();
  });

  describe('create', () => {
    it('debe invocar al servicio con el tenant_id e id de entrenador', async () => {
      const dto: CreateDietPlanDto = {
        memberId: 'member-uuid',
        pesoObjetivoKg: 75.5,
        caloriasObjetivo: 2500,
        comidas: [],
      };
      service.create.mockResolvedValue(mockDietPlan as any);

      const result = await controller.create({ user: mockUser }, dto);

      expect(service.create).toHaveBeenCalledWith(
        'tenant-uuid',
        'trainer-uuid',
        dto,
      );
      expect(result).toEqual(mockDietPlan);
    });
  });

  describe('list', () => {
    it('debe listar todas las dietas del tenant', async () => {
      service.findAll.mockResolvedValue([mockDietPlan] as any);

      const result = await controller.list({ user: mockUser });

      expect(service.findAll).toHaveBeenCalledWith('tenant-uuid', undefined);
      expect(result).toEqual([mockDietPlan]);
    });

    it('debe filtrar por miembro si se provee el query param', async () => {
      service.findAll.mockResolvedValue([mockDietPlan] as any);

      const result = await controller.list({ user: mockUser }, 'member-uuid');

      expect(service.findAll).toHaveBeenCalledWith(
        'tenant-uuid',
        'member-uuid',
      );
      expect(result).toEqual([mockDietPlan]);
    });
  });

  describe('getMyDiet', () => {
    it('debe retornar la dieta activa del socio logueado', async () => {
      service.findActiveForMember.mockResolvedValue(mockDietPlan as any);

      const result = await controller.getMyDiet({ user: mockMemberUser });

      expect(service.findActiveForMember).toHaveBeenCalledWith(
        'member-uuid',
        'tenant-uuid',
      );
      expect(result).toEqual(mockDietPlan);
    });
  });

  describe('update', () => {
    it('debe actualizar la dieta especificada', async () => {
      const dto: UpdateDietPlanDto = { caloriasObjetivo: 2800 };
      service.update.mockResolvedValue({
        ...mockDietPlan,
        calorias_objetivo: 2800,
      } as any);

      const result = await controller.update(
        { user: mockUser },
        'diet-uuid',
        dto,
      );

      expect(service.update).toHaveBeenCalledWith(
        'tenant-uuid',
        'diet-uuid',
        dto,
      );
      expect(result.calorias_objetivo).toBe(2800);
    });
  });

  describe('deactivate', () => {
    it('debe inhabilitar/desactivar la dieta', async () => {
      service.deactivate.mockResolvedValue({
        ...mockDietPlan,
        activo: false,
      } as any);

      const result = await controller.deactivate(
        { user: mockUser },
        'diet-uuid',
      );

      expect(service.deactivate).toHaveBeenCalledWith(
        'tenant-uuid',
        'diet-uuid',
      );
      expect(result.activo).toBe(false);
    });
  });
});
