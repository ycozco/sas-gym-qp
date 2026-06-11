import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
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

  async listExercises(trainerUserId: string, tenantId: string) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { user_id: trainerUserId },
    });

    return this.prisma.exercise.findMany({
      where: {
        tenant_id: tenantId,
        ...(trainer ? { OR: [{ trainer_id: trainer.id }, { activo: true }] } : {}),
      },
      orderBy: [{ grupo_muscular: 'asc' }, { nombre: 'asc' }],
    });
  }

  async createExercise(
    trainerUserId: string,
    tenantId: string,
    dto: {
      nombre: string;
      descripcion?: string;
      grupoMuscular: string;
      imagenUrl?: string;
      animacionUrl?: string;
    },
  ) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { user_id: trainerUserId },
    });
    if (!trainer) {
      throw new NotFoundException('Perfil de entrenador no encontrado.');
    }
    if (!dto.nombre?.trim() || !dto.grupoMuscular?.trim()) {
      throw new BadRequestException('Nombre y grupo muscular son obligatorios.');
    }

    return this.prisma.exercise.create({
      data: {
        tenant_id: tenantId,
        trainer_id: trainer.id,
        nombre: dto.nombre.trim(),
        descripcion: dto.descripcion?.trim() || null,
        grupo_muscular: dto.grupoMuscular.trim(),
        imagen_url: dto.imagenUrl?.trim() || null,
        animacion_url: dto.animacionUrl?.trim() || null,
      },
    });
  }

  async listTemplates(trainerUserId: string, tenantId: string) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { user_id: trainerUserId },
    });

    return this.prisma.routineTemplate.findMany({
      where: {
        tenant_id: tenantId,
        ...(trainer ? { trainer_id: trainer.id } : {}),
      },
      include: {
        ejercicios: {
          include: { exercise: true },
          orderBy: { orden: 'asc' },
        },
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async createTemplate(
    trainerUserId: string,
    tenantId: string,
    dto: {
      nombre: string;
      descripcion?: string;
      ejercicios: Array<{
        exerciseId: string;
        orden?: number;
        series?: number;
        repeticiones?: number;
        pesoSugeridoKg?: number;
        descansoSeg?: number;
      }>;
    },
  ) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { user_id: trainerUserId },
    });
    if (!trainer) {
      throw new NotFoundException('Perfil de entrenador no encontrado.');
    }
    if (!dto.nombre?.trim()) {
      throw new BadRequestException('El nombre de la plantilla es obligatorio.');
    }
    if (!dto.ejercicios?.length) {
      throw new BadRequestException('La plantilla debe incluir al menos un ejercicio.');
    }

    return this.prisma.routineTemplate.create({
      data: {
        tenant_id: tenantId,
        trainer_id: trainer.id,
        nombre: dto.nombre.trim(),
        descripcion: dto.descripcion?.trim() || null,
        ejercicios: {
          create: dto.ejercicios.map((item, index) => ({
            exercise_id: item.exerciseId,
            orden: item.orden ?? index + 1,
            series: item.series ?? 4,
            repeticiones: item.repeticiones ?? 10,
            peso_sugerido_kg: item.pesoSugeridoKg ?? null,
            descanso_seg: item.descansoSeg ?? 60,
          })),
        },
      },
      include: {
        ejercicios: {
          include: { exercise: true },
          orderBy: { orden: 'asc' },
        },
      },
    });
  }

  async assignRoutine(
    trainerUserId: string,
    tenantId: string,
    dto: {
      memberUserId: string;
      templateId: string;
      agendaSemanal?: Record<string, string>;
      publicada?: boolean;
    },
  ) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { user_id: trainerUserId },
    });
    if (!trainer) {
      throw new NotFoundException('Perfil de entrenador no encontrado.');
    }

    const member = await this.prisma.memberProfile.findUnique({
      where: { user_id: dto.memberUserId },
    });
    if (!member) {
      throw new NotFoundException('Perfil de miembro no encontrado.');
    }

    const template = await this.prisma.routineTemplate.findFirst({
      where: { id: dto.templateId, tenant_id: tenantId },
    });
    if (!template) {
      throw new NotFoundException('Plantilla de rutina no encontrada.');
    }

    await this.prisma.routineAssignment.updateMany({
      where: {
        tenant_id: tenantId,
        member_id: member.id,
      },
      data: { publicada: false },
    });

    return this.prisma.routineAssignment.create({
      data: {
        tenant_id: tenantId,
        member_id: member.id,
        trainer_id: trainer.id,
        template_id: template.id,
        agenda_semanal: dto.agendaSemanal ?? {
          LUN: template.id,
          MAR: template.id,
          MIE: template.id,
          JUE: template.id,
          VIE: template.id,
        },
        publicada: dto.publicada ?? true,
      },
      include: {
        template: {
          include: {
            ejercicios: {
              include: { exercise: true },
              orderBy: { orden: 'asc' },
            },
          },
        },
        member: {
          include: {
            user: true,
          },
        },
      },
    });
  }

  async getTrainerProgress(trainerUserId: string, tenantId: string) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { user_id: trainerUserId },
    });
    if (!trainer) {
      return {
        weeklyLoads: [],
        memberSummaries: [],
        totals: { sessions: 0, completedSessions: 0, averageReps: 0 },
      };
    }

    const members = await this.prisma.memberProfile.findMany({
      where: { trainer_id: trainer.id, user: { tenant_id: tenantId } },
      include: {
        user: true,
        workout_sessions: {
          include: { series_log: true },
          orderBy: { fecha: 'desc' },
          take: 30,
        },
      },
    });

    const memberSummaries = members.map((member) => {
      const sessions = member.workout_sessions;
      const completedSessions = sessions.filter((session) => session.estado === 'COMPLETED').length;
      const averageRepsRaw = sessions.flatMap((session) => session.series_log).reduce(
        (sum, log) => sum + (log.reps_reales ?? 0),
        0,
      );
      const totalLogs = sessions.flatMap((session) => session.series_log).length;
      return {
        memberId: member.user_id,
        memberName: member.user.nombre_completo,
        sessions: sessions.length,
        completedSessions,
        averageReps: totalLogs > 0 ? Number((averageRepsRaw / totalLogs).toFixed(1)) : 0,
      };
    });

    const weeklyBucket = new Map<string, number>();
    for (const member of members) {
      for (const session of member.workout_sessions) {
        const key = session.fecha.toISOString().slice(0, 10);
        const volume = session.series_log.reduce((sum, log) => {
          const reps = log.reps_reales ?? 0;
          const weight = log.peso_real_kg ?? 0;
          return sum + reps * weight;
        }, 0);
        weeklyBucket.set(key, (weeklyBucket.get(key) ?? 0) + volume);
      }
    }

    const weeklyLoads = [...weeklyBucket.entries()]
      .sort((a, b) => a[0].localeCompare(b[0]))
      .slice(-8)
      .map(([date, volume]) => ({
        date,
        volume: Number(volume.toFixed(2)),
      }));

    const totalSessions = memberSummaries.reduce((sum, item) => sum + item.sessions, 0);
    const totalCompleted = memberSummaries.reduce((sum, item) => sum + item.completedSessions, 0);
    const averageReps = memberSummaries.length
      ? Number(
          (
            memberSummaries.reduce((sum, item) => sum + item.averageReps, 0) /
            memberSummaries.length
          ).toFixed(1),
        )
      : 0;

    return {
      weeklyLoads,
      memberSummaries,
      totals: {
        sessions: totalSessions,
        completedSessions: totalCompleted,
        averageReps,
      },
    };
  }
}
