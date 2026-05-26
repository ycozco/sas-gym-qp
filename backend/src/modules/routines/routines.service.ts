import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class RoutinesService {
  constructor(private prisma: PrismaService) {}

  async getActiveRoutine(userId: string, tenantId: string) {
    // 1. Encontrar el perfil del miembro para obtener member_id
    const memberProfile = await this.prisma.memberProfile.findUnique({
      where: { user_id: userId },
    });

    if (!memberProfile) {
      return null;
    }

    // 2. Encontrar la asignación de rutina activa y publicada para este miembro
    const assignment = await this.prisma.routineAssignment.findFirst({
      where: {
        member_id: memberProfile.id,
        tenant_id: tenantId,
        publicada: true,
      },
      include: {
        template: {
          include: {
            ejercicios: {
              include: {
                exercise: true,
              },
              orderBy: {
                orden: 'asc',
              },
            },
          },
        },
        trainer: {
          include: {
            user: true,
          },
        },
      },
    });

    return assignment;
  }
}
