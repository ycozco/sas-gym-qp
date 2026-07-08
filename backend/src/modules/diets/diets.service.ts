import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateDietPlanDto, UpdateDietPlanDto } from './dto/diet.dto';

interface DietActor {
  userId: string;
  role: Role;
}

@Injectable()
export class DietsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(tenantId: string, actor: DietActor, dto: CreateDietPlanDto) {
    await this.ensureActorCanManageMember(tenantId, actor, dto.memberId);

    return this.prisma.$transaction(async (tx) => {
      await tx.dietPlan.updateMany({
        where: { member_id: dto.memberId, tenant_id: tenantId, activo: true },
        data: { activo: false },
      });

      return tx.dietPlan.create({
        data: {
          tenant_id: tenantId,
          member_id: dto.memberId,
          trainer_id: actor.role === Role.TRAINER ? actor.userId : null,
          peso_objetivo_kg: dto.pesoObjetivoKg,
          calorias_objetivo: dto.caloriasObjetivo,
          proteinas_g: dto.proteinasG,
          carbohidratos_g: dto.carbohidratosG,
          grasas_g: dto.grasasG,
          comidas: dto.comidas as unknown as Prisma.JsonArray,
          sugerencias: dto.sugerencias,
          activo: true,
        },
      });
    });
  }

  async findAll(tenantId: string, actor: DietActor, memberId?: string) {
    if (memberId) {
      await this.ensureActorCanManageMember(tenantId, actor, memberId);
    }

    return this.prisma.dietPlan.findMany({
      where: {
        tenant_id: tenantId,
        ...(memberId ? { member_id: memberId } : {}),
        ...(actor.role === Role.TRAINER
          ? {
              member: {
                member_profile: {
                  trainer: {
                    user_id: actor.userId,
                  },
                },
              },
            }
          : {}),
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

  async update(
    tenantId: string,
    id: string,
    actor: DietActor,
    dto: UpdateDietPlanDto,
  ) {
    const diet = await this.prisma.dietPlan.findFirst({
      where: {
        id,
        tenant_id: tenantId,
        ...(actor.role === Role.TRAINER
          ? {
              member: {
                member_profile: {
                  trainer: {
                    user_id: actor.userId,
                  },
                },
              },
            }
          : {}),
      },
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
        comidas:
          dto.comidas !== undefined
            ? (dto.comidas as unknown as Prisma.JsonArray)
            : undefined,
        sugerencias: dto.sugerencias,
      },
    });
  }

  async deactivate(tenantId: string, id: string, actor: DietActor) {
    const diet = await this.prisma.dietPlan.findFirst({
      where: {
        id,
        tenant_id: tenantId,
        ...(actor.role === Role.TRAINER
          ? {
              member: {
                member_profile: {
                  trainer: {
                    user_id: actor.userId,
                  },
                },
              },
            }
          : {}),
      },
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

  private async ensureActorCanManageMember(
    tenantId: string,
    actor: DietActor,
    memberId: string,
  ) {
    const member = await this.prisma.user.findFirst({
      where: { id: memberId, tenant_id: tenantId, rol: Role.MEMBER },
      select: {
        id: true,
        member_profile: {
          select: {
            trainer: {
              select: {
                user_id: true,
              },
            },
          },
        },
      },
    });

    if (!member) {
      throw new NotFoundException(
        'El miembro especificado no existe o no pertenece a tu gimnasio.',
      );
    }

    if (
      actor.role === Role.TRAINER &&
      member.member_profile?.trainer?.user_id !== actor.userId
    ) {
      throw new ForbiddenException(
        'Solo puedes gestionar dietas de miembros asignados a tu perfil.',
      );
    }
  }
}
