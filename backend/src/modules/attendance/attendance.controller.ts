import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { FingerprintService, RegisterFingerprintDto, VerifyFingerprintDto } from './fingerprint.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { Role } from '@prisma/client';

class VerifyQrDto {
  dni: string;
  otpToken: string;
}

@Controller('attendance')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class AttendanceController {
  constructor(
    private readonly attendanceService: AttendanceService,
    private readonly fingerprintService: FingerprintService,
  ) {}

  @Post('verify')
  @Roles(Role.ADMIN, Role.CAJA)
  async verifyQr(@Req() req: any, @Body() dto: VerifyQrDto) {
    const tenantId = req.user.tenantId;
    return this.attendanceService.verifyQrToken(dto.dni, dto.otpToken, tenantId);
  }

  @Post('fingerprint/register')
  @Roles(Role.ADMIN, Role.CAJA)
  async registerFingerprint(@Body() dto: RegisterFingerprintDto) {
    return this.fingerprintService.registerFingerprint(dto);
  }

  @Post('fingerprint/verify')
  @Roles(Role.ADMIN, Role.CAJA)
  async verifyFingerprint(@Body() dto: VerifyFingerprintDto) {
    return this.fingerprintService.verifyFingerprint(dto);
  }
}

