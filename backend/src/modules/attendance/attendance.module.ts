import { Module } from '@nestjs/common';
import { AttendanceController } from './attendance.controller';
import { AttendanceService } from './attendance.service';
import { FingerprintService } from './fingerprint.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [AttendanceController],
  providers: [AttendanceService, FingerprintService],
})
export class AttendanceModule {}
