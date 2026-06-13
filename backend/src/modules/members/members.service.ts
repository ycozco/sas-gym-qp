import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionState } from '@prisma/client';

@Injectable()
export class MembersService {
  constructor(private prisma: PrismaService) {}

  async saveWorkoutLog(userId: string, tenantId: string, dto: any) {
    // 1. Encontrar el perfil del miembro
    const memberProfile = await this.prisma.memberProfile.findUnique({
      where: { user_id: userId },
    });

    if (!memberProfile) {
      throw new NotFoundException('Perfil de miembro no encontrado.');
    }

    // 2. Crear WorkoutSession y sus SeriesLog
    const session = await this.prisma.workoutSession.create({
      data: {
        tenant_id: tenantId,
        member_id: memberProfile.id,
        template_id: dto.templateId,
        fecha: dto.fecha ? new Date(dto.fecha) : new Date(),
        estado:
          dto.estado === 'SKIPPED'
            ? SessionState.SKIPPED
            : SessionState.COMPLETED,
        series_log: {
          create: dto.seriesLog.map((log: any) => ({
            exercise_id: log.exerciseId,
            serie_numero: log.serieNumero,
            peso_real_kg: log.pesoRealKg,
            reps_reales: log.repsReales,
            completada: log.completada ?? true,
          })),
        },
      },
      include: {
        series_log: true,
      },
    });

    return {
      success: true,
      message: 'Sesión de entrenamiento guardada correctamente.',
      session,
    };
  }

  async searchMembers(tenantId: string, query: string) {
    if (!query) return [];

    const queryLower = query.toLowerCase().trim();
    const words = queryLower.split(/\s+/).filter(Boolean);

    // Buscar usuarios del tenant con coincidencia parcial en campos clave
    const users = await this.prisma.user.findMany({
      where: {
        tenant_id: tenantId,
        rol: {
          in: ['MEMBER', 'TRAINER', 'CAJA'],
        },
        OR: [
          { dni: { contains: queryLower, mode: 'insensitive' } },
          { nombre_completo: { contains: queryLower, mode: 'insensitive' } },
          { email: { contains: queryLower, mode: 'insensitive' } },
          { celular: { contains: queryLower, mode: 'insensitive' } },
        ],
      },
      include: {
        memberships: {
          orderBy: { fecha_vencimiento: 'desc' },
        },
        points_balance: true,
      },
      take: 50,
    });

    // Calcular puntuación de relevancia para cada resultado
    const scoredUsers = users.map((user) => {
      let score = 0;
      const dni = (user.dni || '').toLowerCase();
      const nombre = (user.nombre_completo || '').toLowerCase();
      const email = (user.email || '').toLowerCase();
      const celular = (user.celular || '').toLowerCase();

      // 1. Coincidencia exacta/parcial en DNI
      if (dni === queryLower) {
        score += 10000;
      } else if (dni.startsWith(queryLower)) {
        score += 5000;
      } else if (dni.includes(queryLower)) {
        score += 2500;
      }

      // 2. Coincidencia múltiple en nombre_completo
      if (words.length > 1) {
        const matchingWords = words.filter((w) => nombre.includes(w)).length;
        if (matchingWords === words.length) {
          score += 3000;
        } else if (matchingWords >= 2) {
          score += 2000;
        } else if (matchingWords > 0) {
          score += 800;
        }
      }

      // 3. Coincidencia individual de inicio/dentro en nombre_completo
      if (nombre.startsWith(queryLower)) {
        score += 500;
      } else if (nombre.includes(queryLower)) {
        score += 300;
      }

      // 4. Coincidencias en email o celular
      if (email.startsWith(queryLower)) {
        score += 100;
      } else if (email.includes(queryLower)) {
        score += 50;
      }

      if (celular.startsWith(queryLower)) {
        score += 100;
      } else if (celular.includes(queryLower)) {
        score += 50;
      }

      return { user, score };
    });

    // Ordenar descendente por puntuación
    scoredUsers.sort((a, b) => b.score - a.score);

    // Retornar top 20
    return scoredUsers.slice(0, 20).map((item) => item.user);
  }

  async assignedMembers(trainerUserId: string, tenantId: string) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { user_id: trainerUserId },
    });
    if (!trainer) return [];

    const members = await this.prisma.user.findMany({
      where: {
        tenant_id: tenantId,
        rol: 'MEMBER',
        member_profile: { trainer_id: trainer.id },
      },
      include: {
        member_profile: true,
        memberships: {
          orderBy: { fecha_vencimiento: 'desc' },
          take: 1,
        },
      },
      orderBy: { nombre_completo: 'asc' },
    });

    if (members.length > 0) return members;

    return this.prisma.user.findMany({
      where: { tenant_id: tenantId, rol: 'MEMBER' },
      include: {
        member_profile: true,
        memberships: {
          orderBy: { fecha_vencimiento: 'desc' },
          take: 1,
        },
      },
      orderBy: { nombre_completo: 'asc' },
      take: 20,
    });
  }
}
