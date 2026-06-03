import {
  Controller,
  Post,
  Body,
  Get,
  Req,
  Headers,
  UseGuards,
  HttpCode,
  HttpStatus,
  BadRequestException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { Public } from '../../core/decorators/public.decorator';
import { AuthGuard } from '../../core/guards/auth.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';

@Controller('auth')
@UseGuards(AuthGuard, TenantGuard)
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @HttpCode(HttpStatus.OK)
  @Post('login')
  async login(@Body() loginDto: LoginDto) {
    const user = await this.authService.validateUser(
      loginDto.emailOrDni,
      loginDto.password,
    );
    return this.authService.login(user);
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
}
