import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { SessionState } from '@prisma/client';

@Injectable()
export class MembersService {
  constructor(private prisma: PrismaService) {}

  // ─── WORKOUT LOG ─────────────────────────────────────────────────
  async saveWorkoutLog(userId: string, tenantId: string, dto: any) {
    const memberProfile = await this.prisma.memberProfile.findUnique({
      where: { user_id: userId },
    });

    if (!memberProfile) {
      throw new NotFoundException('Perfil de miembro no encontrado.');
    }

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

  // ─── BÚSQUEDA DE MIEMBROS ─────────────────────────────────────────
  async searchMembers(tenantId: string, query: string) {
    if (!query) return [];

    const queryLower = query.toLowerCase().trim();
    const words = queryLower.split(/\s+/).filter(Boolean);

    const users = await this.prisma.user.findMany({
      where: {
        tenant_id: tenantId,
        rol: { in: ['MEMBER', 'TRAINER', 'CAJA'] },
        OR: [
          { dni: { contains: queryLower, mode: 'insensitive' } },
          { nombre_completo: { contains: queryLower, mode: 'insensitive' } },
          { email: { contains: queryLower, mode: 'insensitive' } },
          { celular: { contains: queryLower, mode: 'insensitive' } },
        ],
      },
      include: {
        memberships: { orderBy: { fecha_vencimiento: 'desc' } },
        points_balance: true,
      },
      take: 50,
    });

    const scoredUsers = users.map((user) => {
      let score = 0;
      const dni = (user.dni || '').toLowerCase();
      const nombre = (user.nombre_completo || '').toLowerCase();
      const email = (user.email || '').toLowerCase();
      const celular = (user.celular || '').toLowerCase();

      if (dni === queryLower) score += 10000;
      else if (dni.startsWith(queryLower)) score += 5000;
      else if (dni.includes(queryLower)) score += 2500;

      if (words.length > 1) {
        const matchingWords = words.filter((w) => nombre.includes(w)).length;
        if (matchingWords === words.length) score += 3000;
        else if (matchingWords >= 2) score += 2000;
        else if (matchingWords > 0) score += 800;
      }

      if (nombre.startsWith(queryLower)) score += 500;
      else if (nombre.includes(queryLower)) score += 300;

      if (email.startsWith(queryLower)) score += 100;
      else if (email.includes(queryLower)) score += 50;

      if (celular.startsWith(queryLower)) score += 100;
      else if (celular.includes(queryLower)) score += 50;

      return { user, score };
    });

    scoredUsers.sort((a, b) => b.score - a.score);
    return scoredUsers.slice(0, 20).map((item) => item.user);
  }

  // ─── MIEMBROS ASIGNADOS AL TRAINER ───────────────────────────────
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
        memberships: { orderBy: { fecha_vencimiento: 'desc' }, take: 1 },
      },
      orderBy: { nombre_completo: 'asc' },
    });

    if (members.length > 0) return members;

    return this.prisma.user.findMany({
      where: { tenant_id: tenantId, rol: 'MEMBER' },
      include: {
        member_profile: true,
        memberships: { orderBy: { fecha_vencimiento: 'desc' }, take: 1 },
      },
      orderBy: { nombre_completo: 'asc' },
      take: 20,
    });
  }

  // ─── LISTADO DE MIEMBROS PAGINADO POR CURSOR ──────────────────────
  async findAll(tenantId: string, limit = 20, cursor?: string) {
    const take = Math.min(limit, 100);
    return this.prisma.user.findMany({
      take,
      skip: cursor ? 1 : 0,
      cursor: cursor ? { id: cursor } : undefined,
      where: {
        tenant_id: tenantId,
        rol: 'MEMBER',
      },
      orderBy: { id: 'asc' },
      include: {
        memberships: { orderBy: { fecha_vencimiento: 'desc' }, take: 1 },
      },
    });
  }

  // ─── CONGELAMIENTO DE MEMBRESÍA ───────────────────────────────────

  /**
   * Congela la membresía activa de un miembro.
   * Registra en MembershipFreeze para auditoría y marca `congelada=true`.
   */
  async freezeMembership(
    membershipId: string,
    tenantId: string,
    dto: { razon: string; fecha_fin?: string },
  ) {
    const membership = await this.prisma.membership.findFirst({
      where: { id: membershipId, tenant_id: tenantId },
    });

    if (!membership) {
      throw new NotFoundException('Membresía no encontrada.');
    }
    if (membership.congelada) {
      throw new BadRequestException('La membresía ya está congelada.');
    }

    const fechaDescongelacion = dto.fecha_fin
      ? new Date(dto.fecha_fin)
      : undefined;

    return this.prisma.$transaction(async (tx) => {
      const freeze = await tx.membershipFreeze.create({
        data: {
          membership_id: membershipId,
          fecha_congelacion: new Date(),
          fecha_descongelacion: fechaDescongelacion ?? null,
          razon: dto.razon.trim(),
        },
      });

      const updated = await tx.membership.update({
        where: { id: membershipId },
        data: { congelada: true },
        include: { freezes: { orderBy: { created_at: 'desc' }, take: 1 } },
      });

      return {
        success: true,
        message: 'Membresía congelada correctamente.',
        freeze,
        membership: updated,
      };
    });
  }

  /**
   * Descongela una membresía previamente congelada.
   * Extiende la fecha de vencimiento por los días que estuvo congelada.
   */
  async unfreezeMembership(membershipId: string, tenantId: string) {
    const membership = await this.prisma.membership.findFirst({
      where: { id: membershipId, tenant_id: tenantId },
      include: {
        freezes: {
          where: { fecha_descongelacion: null },
          orderBy: { created_at: 'desc' },
          take: 1,
        },
      },
    });

    if (!membership) {
      throw new NotFoundException('Membresía no encontrada.');
    }
    if (!membership.congelada) {
      throw new BadRequestException('La membresía no está congelada.');
    }

    const activeFreeze = membership.freezes[0];
    if (!activeFreeze) {
      throw new BadRequestException(
        'No se encontró registro de congelamiento activo.',
      );
    }

    const now = new Date();
    const frozenDays = Math.ceil(
      (now.getTime() - activeFreeze.fecha_congelacion.getTime()) /
        (1000 * 60 * 60 * 24),
    );

    // Extender la fecha de vencimiento por los días congelados
    const newExpiryDate = membership.fecha_vencimiento
      ? new Date(
          membership.fecha_vencimiento.getTime() +
            frozenDays * 24 * 60 * 60 * 1000,
        )
      : undefined;

    return this.prisma.$transaction(async (tx) => {
      await tx.membershipFreeze.update({
        where: { id: activeFreeze.id },
        data: { fecha_descongelacion: now },
      });

      const updated = await tx.membership.update({
        where: { id: membershipId },
        data: {
          congelada: false,
          ...(newExpiryDate ? { fecha_vencimiento: newExpiryDate } : {}),
        },
        include: { freezes: { orderBy: { created_at: 'desc' }, take: 3 } },
      });

      return {
        success: true,
        message: `Membresía descongelada. Se extendió ${frozenDays} día(s).`,
        diasExtendidos: frozenDays,
        nuevaFechaVencimiento: newExpiryDate,
        membership: updated,
      };
    });
  }

  /**
   * Historial de congelamientos de una membresía.
   */
  async freezeHistory(membershipId: string, tenantId: string) {
    const membership = await this.prisma.membership.findFirst({
      where: { id: membershipId, tenant_id: tenantId },
      include: {
        freezes: { orderBy: { created_at: 'desc' } },
      },
    });

    if (!membership) {
      throw new NotFoundException('Membresía no encontrada.');
    }

    return {
      membershipId,
      congelada: membership.congelada,
      totalCongelamientos: membership.freezes.length,
      historial: membership.freezes,
    };
  }
}
