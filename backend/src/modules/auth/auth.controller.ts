import {
  Controller,
  Post,
  Patch,
  Body,
  Get,
  Req,
  Res,
  UseGuards,
  HttpCode,
  HttpStatus,
  BadRequestException,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';
import { Public } from '../../core/decorators/public.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { getRefreshTokenDays, isProduction } from '../../core/config/env';

@Controller('auth')
@UseGuards(AuthGuard, TenantGuard)
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @HttpCode(HttpStatus.OK)
  @Post('login')
  async login(
    @Body() loginDto: LoginDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const user = await this.authService.validateUser(
      loginDto.emailOrDni,
      loginDto.password,
    );
    const result = await this.authService.login(user, this.requestMeta(req));
    this.setRefreshCookie(res, result.refreshToken);
    const { refreshToken, ...publicResult } = result;
    return publicResult;
  }

  @Public()
  @HttpCode(HttpStatus.OK)
  @Post('refresh')
  async refresh(
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const refreshToken = this.readRefreshCookie(req);
    const result = await this.authService.refresh(
      refreshToken,
      this.requestMeta(req),
    );
    this.setRefreshCookie(res, result.refreshToken);
    const { refreshToken: _refreshToken, ...publicResult } = result;
    return publicResult;
  }

  @Public()
  @HttpCode(HttpStatus.OK)
  @Post('logout')
  async logout(@Req() req: Request, @Res({ passthrough: true }) res: Response) {
    const refreshToken = this.readRefreshCookie(req);
    await this.authService.revokeRefreshToken(refreshToken);
    this.clearRefreshCookie(res);
    return { message: 'Sesion cerrada.' };
  }

  @Public()
  @HttpCode(HttpStatus.OK)
  @Post('forgot-password')
  async forgotPassword(@Body('email') email: string) {
    if (!email) {
      throw new BadRequestException('El correo electrónico es requerido.');
    }
    return {
      message: 'Enlace de recuperación enviado al correo registrado.',
    };
  }

  @Get('me')
  async getProfile(@Req() req: any) {
    const userId = req.user.sub;
    return this.authService.getUserProfile(userId);
  }

  @Patch('me/preferences')
  async updatePreferences(
    @Req() req: any,
    @Body() preferencesDto: UpdatePreferencesDto,
  ) {
    const userId = req.user.sub;
    return this.authService.updatePreferences(userId, preferencesDto);
  }

  private requestMeta(req: Request) {
    return {
      ip: this.clientIp(req),
      userAgent: req.headers['user-agent'],
    };
  }

  private setRefreshCookie(res: Response, refreshToken: string) {
    res.cookie('sasgym_refresh', refreshToken, {
      httpOnly: true,
      secure: isProduction(),
      sameSite: 'strict',
      path: '/api/v1/auth',
      maxAge: getRefreshTokenDays() * 24 * 60 * 60 * 1000,
    });
  }

  private clearRefreshCookie(res: Response) {
    res.clearCookie('sasgym_refresh', {
      httpOnly: true,
      secure: isProduction(),
      sameSite: 'strict',
      path: '/api/v1/auth',
    });
  }

  private readRefreshCookie(req: Request): string {
    const cookieHeader = req.headers.cookie || '';
    const cookies = cookieHeader.split(';').map((cookie) => cookie.trim());
    const match = cookies.find((cookie) =>
      cookie.startsWith('sasgym_refresh='),
    );
    return match ? decodeURIComponent(match.split('=').slice(1).join('=')) : '';
  }

  private clientIp(req: Request): string {
    const forwarded = req.headers['x-forwarded-for'];
    if (typeof forwarded === 'string') return forwarded.split(',')[0].trim();
    return req.ip || req.socket.remoteAddress || '';
  }
}
