import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class FinancesService {
  constructor(private readonly prisma: PrismaService) {}

  async listExpenses(tenantId: string) {
    return this.prisma.expense.findMany({
      where: { tenant_id: tenantId },
      orderBy: { fecha: 'desc' },
    });
  }

  async createExpense(tenantId: string, data: any) {
    return this.prisma.expense.create({
      data: {
        tenant_id: tenantId,
        monto: Number(data.monto),
        categoria: data.categoria || 'Gasto',
        descripcion: data.descripcion,
        fecha: data.fecha ? new Date(data.fecha) : new Date(),
        metodo_pago: data.metodo_pago || 'efectivo',
      },
    });
  }

  async listPayroll(tenantId: string) {
    return this.prisma.payroll.findMany({
      where: { tenant_id: tenantId },
      include: {
        trainer: {
          select: {
            nombre_completo: true,
            email: true,
          },
        },
      },
      orderBy: [{ anio: 'desc' }, { mes: 'desc' }],
    });
  }

  async generatePayroll(tenantId: string, data: any) {
    const existing = await this.prisma.payroll.findFirst({
      where: {
        tenant_id: tenantId,
        trainer_id: data.trainer_id,
        mes: Number(data.mes),
        anio: Number(data.anio),
      },
    });

    if (existing) {
      return existing;
    }

    return this.prisma.payroll.create({
      data: {
        tenant_id: tenantId,
        trainer_id: data.trainer_id,
        monto_sueldo: Number(data.monto_sueldo),
        mes: Number(data.mes),
        anio: Number(data.anio),
        estado_pago: 'Pendiente',
      },
    });
  }

  async payPayroll(tenantId: string, id: string) {
    const existing = await this.prisma.payroll.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!existing) {
      throw new NotFoundException('Planilla no encontrada.');
    }

    await this.prisma.expense.create({
      data: {
        tenant_id: tenantId,
        monto: existing.monto_sueldo,
        categoria: 'Sueldo',
        descripcion: `Planilla de Entrenador (Mes ${existing.mes}/${existing.anio})`,
        metodo_pago: 'transferencia',
        fecha: new Date(),
      },
    });

    return this.prisma.payroll.update({
      where: { id },
      data: {
        estado_pago: 'Pagado',
        fecha_pago: new Date(),
      },
    });
  }

  async summary(tenantId: string) {
    const payments = await this.prisma.payment.findMany({
      where: { tenant_id: tenantId },
      select: { monto: true },
    });
    const totalMembershipIncome = payments.reduce((sum, p) => sum + p.monto, 0);

    const productSales = await this.prisma.productSale.findMany({
      where: { tenant_id: tenantId, estado: 'completada' },
      select: { total: true },
    });
    const totalProductIncome = productSales.reduce(
      (sum, s) => sum + s.total,
      0,
    );

    const totalIncome = totalMembershipIncome + totalProductIncome;

    const expenses = await this.prisma.expense.findMany({
      where: { tenant_id: tenantId },
    });
    const totalExpenses = expenses.reduce((sum, e) => sum + e.monto, 0);

    const netBalance = totalIncome - totalExpenses;

    return {
      totalIncome,
      totalMembershipIncome,
      totalProductIncome,
      totalExpenses,
      netBalance,
      expensesCount: expenses.length,
    };
  }
}
