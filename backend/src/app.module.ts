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
import { TenantsModule } from './modules/tenants/tenants.module';
import { MembershipPlansModule } from './modules/membership-plans/membership-plans.module';
import { ProductsModule } from './modules/products/products.module';
import { AdminModule } from './modules/admin/admin.module';
import { PointsModule } from './modules/points/points.module';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

import { APP_INTERCEPTOR } from '@nestjs/core';
import { APP_GUARD } from '@nestjs/core';
import { AuditInterceptor } from './core/interceptors/audit.interceptor';

@Module({
  imports: [
    AuthModule,
    MembersModule,
    PaymentsModule,
    AttendanceModule,
    SchedulesModule,
    RoutinesModule,
    ObservationsModule,
    AnnouncementsModule,
    ReportsModule,
    PrismaModule,
    TenantsModule,
    MembershipPlansModule,
    ProductsModule,
    AdminModule,
    PointsModule,
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
    {
      provide: APP_INTERCEPTOR,
      useClass: AuditInterceptor,
    },
  ],
})
export class AppModule {}
