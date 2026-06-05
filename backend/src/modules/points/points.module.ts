import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { PointsController } from './points.controller';
import { PointsService } from './points.service';

@Module({
  imports: [PrismaModule],
  controllers: [PointsController],
  providers: [PointsService],
})
export class PointsModule {}
