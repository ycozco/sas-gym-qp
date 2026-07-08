import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { PrismaModule } from '../../prisma/prisma.module';
import { getAccessTokenTtl, getJwtSecret } from '../../core/config/env';
import type { SignOptions } from 'jsonwebtoken';

@Module({
  imports: [
    PrismaModule,
    JwtModule.register({
      global: true,
      secret: getJwtSecret(),
      signOptions: {
        expiresIn: getAccessTokenTtl() as SignOptions['expiresIn'],
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService],
  exports: [AuthService],
})
export class AuthModule {}
