import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './modules/auth/auth.module';
import { MembersModule } from './modules/members/members.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { AttendanceModule } from './modules/attendance/attendance.module';
import { SchedulesModule } from './modules/schedules/schedules.module';
import { RoutinesModule } from './modules/routines/routines.module';
import { ObservationsModule } from './modules/observations/observations.module';
import { AnnouncementsModule } from './modules/announcements/announcements.module';
import { ReportsModule } from './modules/reports/reports.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [AuthModule, MembersModule, PaymentsModule, AttendanceModule, SchedulesModule, RoutinesModule, ObservationsModule, AnnouncementsModule, ReportsModule, PrismaModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
