import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { SaasPlansController } from './saas-plans.controller';
import { SaasPlansService } from './saas-plans.service';

@Module({
  imports: [PrismaModule],
  controllers: [SaasPlansController],
  providers: [SaasPlansService],
  exports: [SaasPlansService],
})
export class SaasPlansModule {}
