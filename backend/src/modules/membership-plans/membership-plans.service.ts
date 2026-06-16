import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateMembershipPlanDto,
  UpdateMembershipPlanDto,
} from './dto/membership-plan.dto';

@Injectable()
export class MembershipPlansService {
  constructor(private prisma: PrismaService) {}

  async list(tenantId: string, includeInactive = false) {
    return this.prisma.membershipPlan.findMany({
      where: {
        tenant_id: tenantId,
        ...(includeInactive ? {} : { activo: true }),
      },
      orderBy: [{ orden: 'asc' }, { created_at: 'asc' }],
    });
  }

  async create(tenantId: string, userId: string, dto: CreateMembershipPlanDto) {
    await this.ensureNameAvailable(tenantId, dto.nombre);

    return this.prisma.membershipPlan.create({
      data: {
        tenant_id: tenantId,
        nombre: dto.nombre.trim(),
        descripcion: dto.descripcion?.trim() || null,
        duracion_dias: dto.duracionDias,
        precio: dto.precio,
        color: dto.color ?? null,
        orden: dto.orden ?? 0,
        activo: dto.activo ?? true,
        created_by_id: userId,
      },
    });
  }

  async update(tenantId: string, id: string, dto: UpdateMembershipPlanDto) {
    const existing = await this.findTenantPlan(tenantId, id);

    if (dto.nombre && dto.nombre.trim() !== existing.nombre) {
      await this.ensureNameAvailable(tenantId, dto.nombre, id);
    }

    return this.prisma.membershipPlan.update({
      where: { id },
      data: {
        nombre: dto.nombre?.trim(),
        descripcion:
          dto.descripcion === undefined
            ? undefined
            : dto.descripcion.trim() || null,
        duracion_dias: dto.duracionDias,
        precio: dto.precio,
        color: dto.color === undefined ? undefined : dto.color,
        orden: dto.orden,
        activo: dto.activo,
      },
    });
  }

  async deactivate(tenantId: string, id: string) {
    await this.findTenantPlan(tenantId, id);
    return this.prisma.membershipPlan.update({
      where: { id },
      data: { activo: false },
    });
  }

  async findActiveForSale(tenantId: string, id: string) {
    const plan = await this.prisma.membershipPlan.findFirst({
      where: { id, tenant_id: tenantId, activo: true },
    });
    if (!plan) {
      throw new NotFoundException(
        'Plan de membresia no encontrado o inactivo.',
      );
    }
    return plan;
  }

  private async findTenantPlan(tenantId: string, id: string) {
    const plan = await this.prisma.membershipPlan.findFirst({
      where: { id, tenant_id: tenantId },
    });
    if (!plan) {
      throw new NotFoundException('Plan de membresia no encontrado.');
    }
    return plan;
  }

  private async ensureNameAvailable(
    tenantId: string,
    nombre: string,
    exceptId?: string,
  ) {
    const duplicate = await this.prisma.membershipPlan.findFirst({
      where: {
        tenant_id: tenantId,
        nombre: nombre.trim(),
        ...(exceptId ? { NOT: { id: exceptId } } : {}),
      },
    });
    if (duplicate) {
      throw new BadRequestException('Ya existe un plan con ese nombre.');
    }
  }
}
