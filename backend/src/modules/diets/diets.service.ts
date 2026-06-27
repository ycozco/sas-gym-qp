import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateDietPlanDto, UpdateDietPlanDto } from './dto/diet.dto';

@Injectable()
export class DietsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    tenantId: string,
    trainerId: string | null,
    dto: CreateDietPlanDto,
  ) {
    // Verificar que el member existe y pertenece al mismo tenant
    const member = await this.prisma.user.findFirst({
      where: { id: dto.memberId, tenant_id: tenantId },
    });
    if (!member) {
      throw new NotFoundException(
        'El miembro especificado no existe o no pertenece a tu gimnasio.',
      );
    }

    // Desactivar dietas anteriores activas para este miembro
    await this.prisma.dietPlan.updateMany({
      where: { member_id: dto.memberId, tenant_id: tenantId, activo: true },
      data: { activo: false },
    });

    // Crear la nueva dieta
    return this.prisma.dietPlan.create({
      data: {
        tenant_id: tenantId,
        member_id: dto.memberId,
        trainer_id: trainerId,
        peso_objetivo_kg: dto.pesoObjetivoKg,
        calorias_objetivo: dto.caloriasObjetivo,
        proteinas_g: dto.proteinasG,
        carbohidratos_g: dto.carbohidratosG,
        grasas_g: dto.grasasG,
        comidas: dto.comidas,
        sugerencias: dto.sugerencias,
        activo: true,
      },
    });
  }

  async findAll(tenantId: string, memberId?: string) {
    return this.prisma.dietPlan.findMany({
      where: {
        tenant_id: tenantId,
        ...(memberId ? { member_id: memberId } : {}),
      },
      orderBy: { created_at: 'desc' },
      include: {
        member: {
          select: {
            id: true,
            nombre_completo: true,
            email: true,
            celular: true,
            dni: true,
          },
        },
        trainer: {
          select: {
            id: true,
            nombre_completo: true,
          },
        },
      },
    });
  }

  async findActiveForMember(memberId: string, tenantId: string) {
    return this.prisma.dietPlan.findFirst({
      where: { member_id: memberId, tenant_id: tenantId, activo: true },
      include: {
        trainer: {
          select: {
            id: true,
            nombre_completo: true,
          },
        },
      },
    });
  }

  async update(tenantId: string, id: string, dto: UpdateDietPlanDto) {
    const diet = await this.prisma.dietPlan.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!diet) {
      throw new NotFoundException(
        'La dieta especificada no existe en tu gimnasio.',
      );
    }

    return this.prisma.dietPlan.update({
      where: { id },
      data: {
        peso_objetivo_kg: dto.pesoObjetivoKg,
        calorias_objetivo: dto.caloriasObjetivo,
        proteinas_g: dto.proteinasG,
        carbohidratos_g: dto.carbohidratosG,
        grasas_g: dto.grasasG,
        comidas: dto.comidas !== undefined ? dto.comidas : undefined,
        sugerencias: dto.sugerencias,
      },
    });
  }

  async deactivate(tenantId: string, id: string) {
    const diet = await this.prisma.dietPlan.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!diet) {
      throw new NotFoundException(
        'La dieta especificada no existe en tu gimnasio.',
      );
    }

    return this.prisma.dietPlan.update({
      where: { id },
      data: { activo: false },
    });
  }
}
