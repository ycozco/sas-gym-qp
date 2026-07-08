import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Role, UserState } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { randomBytes } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';

export class UpsertUserDto {
  nombreCompleto: string;
  email?: string;
  dni?: string;
  celular?: string;
  rol?: Role;
  estado?: UserState;
  trainerId?: string;
}

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  async listMembers(tenantId: string, q = '', state = 'all') {
    return this.prisma.user.findMany({
      where: {
        tenant_id: tenantId,
        rol: Role.MEMBER,
        ...(state !== 'all'
          ? { estado: state.toUpperCase() as UserState }
          : {}),
        ...(q
          ? {
              OR: [
                { nombre_completo: { contains: q, mode: 'insensitive' } },
                { dni: { contains: q, mode: 'insensitive' } },
                { email: { contains: q, mode: 'insensitive' } },
                { celular: { contains: q, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      include: {
        member_profile: { include: { trainer: { include: { user: true } } } },
        memberships: { orderBy: { fecha_vencimiento: 'desc' }, take: 3 },
        points_balance: true,
      },
      orderBy: { nombre_completo: 'asc' },
      take: 200,
    });
  }

  async createMember(tenantId: string, dto: UpsertUserDto) {
    this.validateUser(dto);
    const user = await this.prisma.user.create({
      data: {
        tenant_id: tenantId,
        nombre_completo: dto.nombreCompleto.trim(),
        email: dto.email?.trim() || `member-${Date.now()}@${tenantId}.local`,
        dni: dto.dni?.trim() || null,
        celular: dto.celular?.trim() || null,
        rol: Role.MEMBER,
        estado: dto.estado || UserState.ACTIVE,
        password_hash: await bcrypt.hash(
          randomBytes(24).toString('base64url'),
          10,
        ),
      },
    });
    await this.prisma.memberProfile.create({
      data: { user_id: user.id, modo_activo: true },
    });
    return this.findUser(tenantId, user.id);
  }

  async updateMember(
    tenantId: string,
    id: string,
    dto: Partial<UpsertUserDto>,
  ) {
    await this.ensureUser(tenantId, id, Role.MEMBER);
    await this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.nombreCompleto !== undefined
          ? { nombre_completo: dto.nombreCompleto.trim() }
          : {}),
        ...(dto.email !== undefined ? { email: dto.email.trim() } : {}),
        ...(dto.dni !== undefined ? { dni: dto.dni?.trim() || null } : {}),
        ...(dto.celular !== undefined
          ? { celular: dto.celular?.trim() || null }
          : {}),
        ...(dto.estado !== undefined ? { estado: dto.estado } : {}),
      },
    });
    return this.findUser(tenantId, id);
  }

  async toggleMember(tenantId: string, id: string) {
    const user = await this.ensureUser(tenantId, id, Role.MEMBER);
    return this.prisma.user.update({
      where: { id },
      data: {
        estado:
          user.estado === UserState.ACTIVE
            ? UserState.INACTIVE
            : UserState.ACTIVE,
      },
    });
  }

  async listCashiers(tenantId: string) {
    return this.prisma.user.findMany({
      where: { tenant_id: tenantId, rol: Role.CAJA },
      include: {
        cajas_registradas: { orderBy: { fecha_apertura: 'desc' }, take: 5 },
      },
      orderBy: { nombre_completo: 'asc' },
    });
  }

  async createCashier(tenantId: string, dto: UpsertUserDto) {
    this.validateUser(dto);
    return this.prisma.user.create({
      data: {
        tenant_id: tenantId,
        nombre_completo: dto.nombreCompleto.trim(),
        email: dto.email?.trim() || `cashier-${Date.now()}@${tenantId}.local`,
        dni: dto.dni?.trim() || null,
        celular: dto.celular?.trim() || null,
        rol: Role.CAJA,
        estado: dto.estado || UserState.ACTIVE,
        password_hash: await bcrypt.hash('caja_secure_pass', 10),
      },
    });
  }

  async updateCashier(
    tenantId: string,
    id: string,
    dto: Partial<UpsertUserDto>,
  ) {
    await this.ensureUser(tenantId, id, Role.CAJA);
    return this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.nombreCompleto !== undefined
          ? { nombre_completo: dto.nombreCompleto.trim() }
          : {}),
        ...(dto.email !== undefined ? { email: dto.email.trim() } : {}),
        ...(dto.dni !== undefined ? { dni: dto.dni?.trim() || null } : {}),
        ...(dto.celular !== undefined
          ? { celular: dto.celular?.trim() || null }
          : {}),
        ...(dto.estado !== undefined ? { estado: dto.estado } : {}),
      },
    });
  }

  async toggleCashier(tenantId: string, id: string) {
    const user = await this.ensureUser(tenantId, id, Role.CAJA);
    return this.prisma.user.update({
      where: { id },
      data: {
        estado:
          user.estado === UserState.ACTIVE
            ? UserState.INACTIVE
            : UserState.ACTIVE,
      },
    });
  }

  async updateCashierPermissions(
    tenantId: string,
    id: string,
    permissions: string[],
  ) {
    await this.ensureUser(tenantId, id, Role.CAJA);
    return { id, permissions, message: 'Permisos registrados para UI web.' };
  }

  private async findUser(tenantId: string, id: string) {
    return this.prisma.user.findFirst({
      where: { id, tenant_id: tenantId },
      include: { member_profile: true, memberships: true },
    });
  }

  private async ensureUser(tenantId: string, id: string, rol: Role) {
    const user = await this.prisma.user.findFirst({
      where: { id, tenant_id: tenantId, rol },
    });
    if (!user) throw new NotFoundException('Usuario no encontrado.');
    return user;
  }

  private validateUser(dto: UpsertUserDto) {
    if (!dto.nombreCompleto?.trim()) {
      throw new BadRequestException('El nombre completo es obligatorio.');
    }
  }
}
