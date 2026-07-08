import type { AuthenticatedRequest } from '../../core/types/authenticated-request';
import {
  Controller,
  Post,
  Get,
  Req,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { existsSync, mkdirSync } from 'fs';
import { ObservationsService } from './observations.service';
import { AuthGuard } from '../../core/guards/auth.guard';
import { TenantGuard } from '../../core/guards/tenant.guard';
import { RolesGuard } from '../../core/guards/roles.guard';
import { Roles } from '../../core/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('observations')
@UseGuards(AuthGuard, TenantGuard, RolesGuard)
export class ObservationsController {
  constructor(private readonly observationsService: ObservationsService) {}

  @Post('upload')
  @Roles(Role.MEMBER, Role.TRAINER)
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
      fileFilter: (
        _req: unknown,
        file: Express.Multer.File,
        cb: (error: Error | null, acceptFile: boolean) => void,
      ) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png|webp)$/)) {
          return cb(
            new BadRequestException(
              'Solo se permiten imágenes (JPG, JPEG, PNG, WEBP).',
            ),
            false,
          );
        }
        cb(null, true);
      },
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          const uploadPath = './uploads/observations';
          if (!existsSync(uploadPath)) {
            mkdirSync(uploadPath, { recursive: true });
          }
          cb(null, uploadPath);
        },
        filename: (_req, file, cb) => {
          const uniqueSuffix =
            Date.now() + '-' + Math.round(Math.random() * 1e9);
          const extension = file.originalname.split('.').pop();
          cb(null, `${uniqueSuffix}.${extension}`);
        },
      }),
    }),
  )
  async uploadObservation(
    @Req() req: AuthenticatedRequest,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body('category') category: string,
    @Body('description') description: string,
  ) {
    if (!description || !category) {
      throw new BadRequestException(
        'La categoría y descripción son obligatorias.',
      );
    }

    const userId = req.user.sub;
    const tenantId = req.user.tenantId;
    const role = req.user.rol;

    const texto = `[${category}] ${description}`;

    return this.observationsService.createObservation(
      userId,
      tenantId,
      role,
      texto,
      file?.filename,
    );
  }

  @Get()
  @Roles(Role.ADMIN, Role.SUPER_ADMIN)
  async getObservations(@Req() req: AuthenticatedRequest) {
    const tenantId = req.user.tenantId;
    return this.observationsService.getObservations(tenantId);
  }
}
