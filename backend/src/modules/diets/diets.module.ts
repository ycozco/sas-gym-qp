import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { DietsController } from './diets.controller';
import { DietsService } from './diets.service';

@Module({
  imports: [PrismaModule],
  controllers: [DietsController],
  providers: [DietsService],
  exports: [DietsService],
})
export class DietsModule {}
