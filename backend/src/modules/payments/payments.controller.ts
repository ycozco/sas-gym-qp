import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Param,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Req,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { existsSync, mkdirSync } from 'fs';
import { PaymentsService, ChargePosDto } from './payments.service';
import {
  CashierSessionService,
  OpenCajaDto,
  CloseCajaDto,
  EgressDto,
  AdminEditCajaDto,
  CajeroEditOpeningAmountDto,
} from './cashier-session.service';
import {
  MembershipBillingService,
  RegisterMembershipSaleDto,
} from './membership-billing.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('payments')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class PaymentsController {
  constructor(
    private readonly paymentsService: PaymentsService,
    private readonly cashierSessionService: CashierSessionService,
    private readonly membershipBillingService: MembershipBillingService,
  ) {}

  @Post('upload-receipt')
  @Roles(Role.MEMBER)
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
      fileFilter: (req: any, file: any, cb: any) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png|webp)$/)) {
          return cb(
            new BadRequestException(
              'Solo se permiten imágenes (JPG, JPEG, PNG, WEBP).',
            ),
            false,
          );
        }
        cb(null, true);
      },
      storage: diskStorage({
        destination: (req: any, file: any, cb: any) => {
          const uploadPath = './uploads/receipts';
          if (!existsSync(uploadPath)) {
            mkdirSync(uploadPath, { recursive: true });
          }
          cb(null, uploadPath);
        },
        filename: (req: any, file: any, cb: any) => {
          const uniqueSuffix =
            Date.now() + '-' + Math.round(Math.random() * 1e9);
          const extension = file.originalname.split('.').pop();
          cb(null, `${uniqueSuffix}.${extension}`);
        },
      }),
    }),
  )
  async uploadReceipt(
    @Req() req: any,
    @UploadedFile() file: any,
    @Body('monto') montoStr: string,
    @Body('metodo') metodo: string,
    @Body('planNombre') planNombre: string,
  ) {
    if (!file) {
      throw new BadRequestException('El archivo de comprobante es requerido.');
    }
    if (!montoStr || !metodo || !planNombre) {
      throw new BadRequestException(
        'Los campos monto, metodo y planNombre son obligatorios.',
      );
    }

    const monto = parseFloat(montoStr);
    if (isNaN(monto)) {
      throw new BadRequestException('El monto debe ser un número válido.');
    }

    const userId = req.user.sub;
    const tenantId = req.user.tenantId;

    return this.paymentsService.uploadReceipt(
      userId,
      tenantId,
      monto,
      metodo,
      planNombre,
      file.filename,
    );
  }

  @Get('me')
  @Roles(Role.MEMBER)
  async getMyPayments(@Req() req: any) {
    return this.paymentsService.getMemberPayments(
      req.user.sub,
      req.user.tenantId,
    );
  }

  @Get('pending')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async getPending(@Req() req: any) {
    const tenantId = req.user.tenantId;
    return this.paymentsService.getPendingPayments(tenantId);
  }

  @Post(':id/resolve')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async resolvePayment(
    @Req() req: any,
    @Param('id') paymentId: string,
    @Body('status') status: 'APPROVED' | 'REJECTED',
    @Body('comments') comments?: string,
  ) {
    if (!status || (status !== 'APPROVED' && status !== 'REJECTED')) {
      throw new BadRequestException(
        "El estado debe ser 'APPROVED' o 'REJECTED'.",
      );
    }
    const tenantId = req.user.tenantId;
    return this.paymentsService.resolvePayment(
      paymentId,
      tenantId,
      status,
      comments,
    );
  }

  @Get('check-shift')
  @Roles(Role.CAJA, Role.ADMIN)
  async checkShift(@Req() req: any) {
    const cashierId = req.user.sub;
    const isActive = await this.paymentsService.checkShiftSession(cashierId);
    return { isActive };
  }

  @Post('pos-charge')
  @Roles(Role.CAJA, Role.ADMIN)
  async processPOSCharge(@Req() req: any, @Body() dto: ChargePosDto) {
    const cashierId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.paymentsService.processPOSCharge(cashierId, tenantId, dto);
  }

  // ─── TURNOS Y SESIONES DE CAJA ─────────────────────────────────────

  @Post('caja/open')
  @Roles(Role.CAJA, Role.ADMIN)
  async openCaja(@Req() req: any, @Body() dto: OpenCajaDto) {
    const cashierId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.cashierSessionService.openCaja(cashierId, tenantId, dto);
  }

  @Get('caja/active')
  @Roles(Role.CAJA, Role.ADMIN)
  async getActiveCaja(@Req() req: any) {
    const cashierId = req.user.sub;
    const tenantId = req.user.tenantId;
    const active = await this.cashierSessionService.getActiveCaja(
      cashierId,
      tenantId,
    );
    return active || { message: 'No hay ninguna caja abierta.' };
  }

  @Post('caja/egress')
  @Roles(Role.CAJA, Role.ADMIN)
  async createEgress(@Req() req: any, @Body() dto: EgressDto) {
    const cashierId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.cashierSessionService.createEgress(cashierId, tenantId, dto);
  }

  @Get('caja/details')
  @Roles(Role.CAJA, Role.ADMIN)
  async getCajaDetails(@Req() req: any) {
    const cashierId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.cashierSessionService.getCajaSessionDetails(
      cashierId,
      tenantId,
    );
  }

  @Post('caja/close')
  @Roles(Role.CAJA, Role.ADMIN)
  async closeCaja(@Req() req: any, @Body() dto: CloseCajaDto) {
    const cashierId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.cashierSessionService.closeCaja(cashierId, tenantId, dto);
  }

  @Patch('caja/edit-opening-amount')
  @Roles(Role.CAJA)
  async editOpeningAmount(
    @Req() req: any,
    @Body() dto: CajeroEditOpeningAmountDto,
  ) {
    const cashierId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.cashierSessionService.cajeroEditOpeningAmount(
      cashierId,
      tenantId,
      dto,
    );
  }

  @Patch('caja/:id/admin-edit')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async adminEditCaja(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: AdminEditCajaDto,
  ) {
    const tenantId = req.user.tenantId;
    const actorId = req.user.sub;
    const actorName = req.user.nombre_completo || 'Admin';
    return this.cashierSessionService.adminEditCaja(
      tenantId,
      id,
      dto,
      actorId,
      actorName,
    );
  }

  @Get('caja/sales')
  @Roles(Role.CAJA, Role.ADMIN)
  async getCajaSales(@Req() req: any) {
    return this.paymentsService.getCajaSales(req.user.sub, req.user.tenantId);
  }

  @Post(':id/void-request')
  @Roles(Role.CAJA, Role.ADMIN)
  async requestVoid(@Req() req: any, @Param('id') id: string) {
    return this.paymentsService.requestVoid(
      req.user.sub,
      req.user.tenantId,
      id,
    );
  }

  @Post(':id/void-resolve')
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async resolveVoid(
    @Req() req: any,
    @Param('id') id: string,
    @Body('approved') approved: boolean,
  ) {
    return this.paymentsService.resolveVoid(
      req.user.tenantId,
      id,
      Boolean(approved),
    );
  }

  // ─── VENTAS DE MEMBRESÍAS ──────────────────────────────────────────

  @Post('membership-sale')
  @Roles(Role.CAJA, Role.ADMIN)
  async registerMembershipSale(
    @Req() req: any,
    @Body() dto: RegisterMembershipSaleDto,
  ) {
    const cashierId = req.user.sub;
    const tenantId = req.user.tenantId;
    return this.membershipBillingService.registerMembershipSale(
      cashierId,
      tenantId,
      dto,
    );
  }
}
