import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateSaasPlanDto, UpdateSaasPlanDto } from './dto/saas-plan.dto';

@Injectable()
export class SaasPlansService {
  constructor(private readonly prisma: PrismaService) {}

  list(includeInactive = false) {
    return this.prisma.saasPlan.findMany({
      where: includeInactive ? undefined : { activo: true },
      orderBy: [{ precio_mensual: 'asc' }, { nombre: 'asc' }],
    });
  }

  async create(dto: CreateSaasPlanDto) {
    const code = dto.code.trim().toUpperCase();
    const exists = await this.prisma.saasPlan.findUnique({ where: { code } });
    if (exists) {
      throw new ConflictException('Ya existe un plan SaaS con ese codigo.');
    }

    return this.prisma.saasPlan.create({
      data: {
        code,
        nombre: dto.nombre.trim(),
        descripcion: dto.descripcion?.trim() || null,
        precio_mensual: dto.precioMensual,
        limite_usuarios: dto.limiteUsuarios,
        caracteristicas: dto.caracteristicas.trim(),
        activo: dto.activo ?? true,
      },
    });
  }

  async update(code: string, dto: UpdateSaasPlanDto) {
    const current = await this.prisma.saasPlan.findUnique({
      where: { code: code.trim().toUpperCase() },
    });
    if (!current) {
      throw new NotFoundException('Plan SaaS no encontrado.');
    }

    return this.prisma.saasPlan.update({
      where: { code: current.code },
      data: {
        nombre: dto.nombre?.trim(),
        descripcion: dto.descripcion === undefined ? undefined : dto.descripcion.trim() || null,
        precio_mensual: dto.precioMensual,
        limite_usuarios: dto.limiteUsuarios,
        caracteristicas: dto.caracteristicas?.trim(),
        activo: dto.activo,
      },
    });
  }

  async deactivate(code: string) {
    const current = await this.prisma.saasPlan.findUnique({
      where: { code: code.trim().toUpperCase() },
    });
    if (!current) {
      throw new NotFoundException('Plan SaaS no encontrado.');
    }

    return this.prisma.saasPlan.update({
      where: { code: current.code },
      data: { activo: false },
    });
  }
}
