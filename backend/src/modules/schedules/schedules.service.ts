import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Role } from '@prisma/client';

@Injectable()
export class SchedulesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(tenantId: string, userId?: string, role?: Role) {
    const rows = await this.prisma.schedule.findMany({
      where: { tenant_id: tenantId, activo: true },
      include: {
        bookings: true,
      },
      orderBy: [{ hora_inicio: 'asc' }, { nombre_clase: 'asc' }],
    });

    if (role !== Role.MEMBER || !userId) {
      return rows;
    }

    return rows.map((schedule) => {
      const myBooking = schedule.bookings.find(
        (booking) => booking.user_id === userId,
      );
      return {
        ...schedule,
        my_booking_status: myBooking?.estado ?? null,
        my_booking_date: myBooking?.fecha ?? null,
      };
    });
  }

  async book(
    userId: string,
    tenantId: string,
    scheduleId: string,
    fecha?: string,
  ) {
    const schedule = await this.prisma.schedule.findFirst({
      where: { id: scheduleId, tenant_id: tenantId, activo: true },
      include: { bookings: true },
    });
    if (!schedule) {
      throw new NotFoundException('Clase no encontrada.');
    }

    const bookingDate = fecha ? new Date(fecha) : new Date();
    if (Number.isNaN(bookingDate.getTime())) {
      throw new BadRequestException('La fecha de reserva no es válida.');
    }

    const sameDayBookings = schedule.bookings.filter(
      (booking) =>
        booking.fecha.toISOString().slice(0, 10) ===
        bookingDate.toISOString().slice(0, 10),
    );
    const existing = sameDayBookings.find(
      (booking) => booking.user_id === userId,
    );
    if (existing && existing.estado !== 'CANCELLED') {
      return existing;
    }

    const activeBookings = sameDayBookings.filter(
      (booking) => booking.estado !== 'CANCELLED',
    ).length;
    const nextState =
      activeBookings >= schedule.cupo_maximo ? 'WAITLIST' : 'CONFIRMED';

    if (existing) {
      return this.prisma.booking.update({
        where: { id: existing.id },
        data: { estado: nextState, fecha: bookingDate },
      });
    }

    return this.prisma.booking.create({
      data: {
        schedule_id: schedule.id,
        user_id: userId,
        fecha: bookingDate,
        estado: nextState,
      },
    });
  }

  async cancel(
    userId: string,
    tenantId: string,
    scheduleId: string,
    fecha?: string,
  ) {
    const schedule = await this.prisma.schedule.findFirst({
      where: { id: scheduleId, tenant_id: tenantId, activo: true },
    });
    if (!schedule) {
      throw new NotFoundException('Clase no encontrada.');
    }

    const bookingDate = fecha ? new Date(fecha) : new Date();
    const booking = await this.prisma.booking.findFirst({
      where: {
        schedule_id: scheduleId,
        user_id: userId,
        fecha: {
          gte: new Date(bookingDate.toISOString().slice(0, 10)),
          lt: new Date(
            new Date(bookingDate.toISOString().slice(0, 10)).getTime() +
              24 * 60 * 60 * 1000,
          ),
        },
      },
    });
    if (!booking) {
      throw new NotFoundException('Reserva no encontrada.');
    }

    return this.prisma.booking.update({
      where: { id: booking.id },
      data: { estado: 'CANCELLED' },
    });
  }

  async create(tenantId: string, data: any) {
    return this.prisma.schedule.create({
      data: {
        tenant_id: tenantId,
        trainer_id: data.trainer_id,
        nombre_clase: data.nombre_clase,
        descripcion: data.descripcion || '',
        dia_semana: data.dia_semana || [],
        hora_inicio: data.hora_inicio,
        hora_fin: data.hora_fin,
        cupo_maximo: Number(data.cupo_maximo) || 20,
        activo: true,
      },
    });
  }

  async update(tenantId: string, id: string, data: any) {
    const existing = await this.prisma.schedule.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!existing) {
      throw new NotFoundException('Clase no encontrada.');
    }
    return this.prisma.schedule.update({
      where: { id },
      data: {
        trainer_id:
          data.trainer_id !== undefined ? data.trainer_id : existing.trainer_id,
        nombre_clase:
          data.nombre_clase !== undefined
            ? data.nombre_clase
            : existing.nombre_clase,
        descripcion:
          data.descripcion !== undefined
            ? data.descripcion
            : existing.descripcion,
        dia_semana:
          data.dia_semana !== undefined ? data.dia_semana : existing.dia_semana,
        hora_inicio:
          data.hora_inicio !== undefined
            ? data.hora_inicio
            : existing.hora_inicio,
        hora_fin:
          data.hora_fin !== undefined ? data.hora_fin : existing.hora_fin,
        cupo_maximo:
          data.cupo_maximo !== undefined
            ? Number(data.cupo_maximo)
            : existing.cupo_maximo,
        activo: data.activo !== undefined ? data.activo : existing.activo,
      },
    });
  }

  async delete(tenantId: string, id: string) {
    const existing = await this.prisma.schedule.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!existing) {
      throw new NotFoundException('Clase no encontrada.');
    }
    return this.prisma.schedule.update({
      where: { id },
      data: { activo: false },
    });
  }

  async listTrainers(tenantId: string) {
    return this.prisma.user.findMany({
      where: {
        tenant_id: tenantId,
        rol: Role.TRAINER,
        estado: 'ACTIVE',
      },
      select: {
        id: true,
        nombre_completo: true,
        email: true,
      },
      orderBy: {
        nombre_completo: 'asc',
      },
    });
  }
}
