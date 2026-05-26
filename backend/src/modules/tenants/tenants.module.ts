import { Module } from '@nestjs/common';
import { TenantsController } from './tenants.controller';
import { TenantsService } from './tenants.service';
import { SaasGateway } from '../../core/gateways/saas.gateway';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [TenantsController],
  providers: [TenantsService, SaasGateway],
  exports: [TenantsService, SaasGateway],
})
export class TenantsModule {}
