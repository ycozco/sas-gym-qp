import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export class UpsertProductDto {
  nombre: string;
  descripcion?: string;
  categoria?: string;
  sku?: string;
  precioCompra?: number;
  precioVenta: number;
  stockActual?: number;
  stockMinimo?: number;
  imagenUrl?: string;
  estado?: string;
  esVisible?: boolean;
}

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  async list(tenantId: string, includeInactive = false) {
    return this.prisma.product.findMany({
      where: {
        tenant_id: tenantId,
        ...(includeInactive ? {} : { es_visible: true, estado: { not: 'inactivo' } }),
      },
      include: { categoria: true },
      orderBy: [{ estado: 'asc' }, { nombre: 'asc' }],
    });
  }

  async create(tenantId: string, dto: UpsertProductDto) {
    this.validate(dto);
    const category = await this.ensureCategory(tenantId, dto.categoria || 'General');
    const sku = dto.sku?.trim() || `SKU-${tenantId.slice(0, 8)}-${Date.now()}`;

    return this.prisma.product.create({
      data: {
        tenant_id: tenantId,
        nombre: dto.nombre.trim(),
        descripcion: dto.descripcion?.trim() || '',
        categoria_id: category.id,
        sku,
        precio_compra: Number(dto.precioCompra ?? 0),
        precio_venta: Number(dto.precioVenta),
        stock_actual: Number(dto.stockActual ?? 0),
        stock_minimo: Number(dto.stockMinimo ?? 5),
        imagen_url: dto.imagenUrl || null,
        estado: dto.estado || 'activo',
        es_visible: dto.esVisible ?? true,
      },
      include: { categoria: true },
    });
  }

  async update(tenantId: string, id: string, dto: Partial<UpsertProductDto>) {
    const current = await this.prisma.product.findFirst({ where: { id, tenant_id: tenantId } });
    if (!current) throw new NotFoundException('Producto no encontrado.');

    const category = dto.categoria
      ? await this.ensureCategory(tenantId, dto.categoria)
      : null;

    return this.prisma.product.update({
      where: { id },
      data: {
        ...(dto.nombre !== undefined ? { nombre: dto.nombre.trim() } : {}),
        ...(dto.descripcion !== undefined ? { descripcion: dto.descripcion?.trim() || '' } : {}),
        ...(category ? { categoria_id: category.id } : {}),
        ...(dto.sku !== undefined ? { sku: dto.sku.trim() } : {}),
        ...(dto.precioCompra !== undefined ? { precio_compra: Number(dto.precioCompra) } : {}),
        ...(dto.precioVenta !== undefined ? { precio_venta: Number(dto.precioVenta) } : {}),
        ...(dto.stockActual !== undefined ? { stock_actual: Number(dto.stockActual) } : {}),
        ...(dto.stockMinimo !== undefined ? { stock_minimo: Number(dto.stockMinimo) } : {}),
        ...(dto.imagenUrl !== undefined ? { imagen_url: dto.imagenUrl || null } : {}),
        ...(dto.estado !== undefined ? { estado: dto.estado } : {}),
        ...(dto.esVisible !== undefined ? { es_visible: Boolean(dto.esVisible) } : {}),
      },
      include: { categoria: true },
    });
  }

  async deactivate(tenantId: string, id: string) {
    const current = await this.prisma.product.findFirst({ where: { id, tenant_id: tenantId } });
    if (!current) throw new NotFoundException('Producto no encontrado.');
    return this.prisma.product.update({
      where: { id },
      data: { estado: 'inactivo', es_visible: false },
      include: { categoria: true },
    });
  }

  private validate(dto: UpsertProductDto) {
    if (!dto.nombre?.trim()) throw new BadRequestException('El nombre del producto es obligatorio.');
    if (Number(dto.precioVenta) < 0) throw new BadRequestException('El precio de venta no puede ser negativo.');
  }

  private async ensureCategory(tenantId: string, rawName: string) {
    const visibleName = rawName.trim() || 'General';
    const existing = await this.prisma.productCategory.findFirst({
      where: { tenant_id: tenantId, nombre: { contains: visibleName, mode: 'insensitive' } },
    });
    if (existing) return existing;

    return this.prisma.productCategory.create({
      data: {
        tenant_id: tenantId,
        nombre: `${tenantId.slice(0, 8)}-${visibleName}`,
        descripcion: visibleName,
      },
    });
  }
}
