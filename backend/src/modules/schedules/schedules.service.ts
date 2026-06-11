import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
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
      const myBooking = schedule.bookings.find((booking) => booking.user_id === userId);
      return {
        ...schedule,
        my_booking_status: myBooking?.estado ?? null,
        my_booking_date: myBooking?.fecha ?? null,
      };
    });
  }

  async book(userId: string, tenantId: string, scheduleId: string, fecha?: string) {
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
      (booking) => booking.fecha.toISOString().slice(0, 10) === bookingDate.toISOString().slice(0, 10),
    );
    const existing = sameDayBookings.find((booking) => booking.user_id === userId);
    if (existing && existing.estado !== 'CANCELLED') {
      return existing;
    }

    const activeBookings = sameDayBookings.filter((booking) => booking.estado !== 'CANCELLED').length;
    const nextState = activeBookings >= schedule.cupo_maximo ? 'WAITLIST' : 'CONFIRMED';

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

  async cancel(userId: string, tenantId: string, scheduleId: string, fecha?: string) {
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
          lt: new Date(new Date(bookingDate.toISOString().slice(0, 10)).getTime() + 24 * 60 * 60 * 1000),
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
}
