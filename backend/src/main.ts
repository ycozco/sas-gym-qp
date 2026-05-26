import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import * as express from 'express';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Servir archivos estáticos localmente desde la carpeta uploads
  app.use('/uploads', express.static(join(process.cwd(), 'uploads')));

  // Prefijo global para la API móvil y web
  app.setGlobalPrefix('api/v1');

  // Habilitar CORS para permitir consumo desde Flutter (Web, Windows, Android)
  app.enableCors();

  // Validaciones globales usando class-validator
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,        // Elimina propiedades que no estén en el DTO
      transform: true,        // Transforma payloads a instancias de sus DTOs correspondientes
      forbidNonWhitelisted: true, // Lanza error si se envían propiedades no permitidas
    }),
  );

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`Servidor de GymSmart ejecutándose en: http://localhost:${port}/api/v1`);
}
bootstrap();
