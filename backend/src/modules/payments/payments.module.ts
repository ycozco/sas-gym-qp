import { Module } from '@nestjs/common';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { CashierSessionService } from './cashier-session.service';
import { MembershipBillingService } from './membership-billing.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { MembershipPlansModule } from '../membership-plans/membership-plans.module';

@Module({
  imports: [PrismaModule, MembershipPlansModule],
  controllers: [PaymentsController],
  providers: [PaymentsService, CashierSessionService, MembershipBillingService],
  exports: [PaymentsService, CashierSessionService, MembershipBillingService],
})
export class PaymentsModule {}
