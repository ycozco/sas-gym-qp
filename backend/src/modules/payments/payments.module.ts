import { Module } from '@nestjs/common';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { CashierSessionService } from './cashier-session.service';
import { MembershipBillingService } from './membership-billing.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [PaymentsController],
  providers: [PaymentsService, CashierSessionService, MembershipBillingService],
  exports: [PaymentsService, CashierSessionService, MembershipBillingService],
})
export class PaymentsModule {}

