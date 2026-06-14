import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { getOptionalEnv } from '../config/env';

@Injectable()
export class S3StorageService implements OnModuleInit {
  private s3Client: S3Client;
  private bucketName: string;
  private readonly logger = new Logger(S3StorageService.name);

  onModuleInit() {
    const accessKeyId = getOptionalEnv('S3_ACCESS_KEY_ID');
    const secretAccessKey = getOptionalEnv('S3_SECRET_ACCESS_KEY');
    const region = getOptionalEnv('S3_REGION', 'us-east-1');
    const endpoint = getOptionalEnv('S3_ENDPOINT'); // Cloudflare R2 / LocalStack / MinIO
    this.bucketName = getOptionalEnv('S3_BUCKET_NAME', 'sasgym-uploads');

    if (!accessKeyId || !secretAccessKey) {
      this.logger.warn(
        'AWS/S3 credentials (S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY) no están definidas. El servicio de almacenamiento S3 operará con cliente simulado o fallará.',
      );
    }

    this.s3Client = new S3Client({
      region,
      credentials: {
        accessKeyId: accessKeyId || 'mock-key',
        secretAccessKey: secretAccessKey || 'mock-secret',
      },
      ...(endpoint ? { endpoint, forcePathStyle: true } : {}),
    });
  }

  /**
   * Sube un archivo al bucket de S3.
   * @param key Ruta o identificador del archivo en el bucket.
   * @param buffer Búfer con los datos binarios del archivo.
   * @param mimeType Tipo MIME del archivo.
   * @returns La clave del archivo subido.
   */
  async uploadFile(key: string, buffer: Buffer, mimeType: string): Promise<string> {
    this.logger.log(`Subiendo archivo a S3: ${key} (MIME: ${mimeType})`);
    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: key,
      Body: buffer,
      ContentType: mimeType,
    });

    await this.s3Client.send(command);
    return key;
  }

  /**
   * Genera una URL pre-firmada para descargar o ver un archivo en S3 de forma segura y temporal.
   * @param key Ruta o identificador del archivo en el bucket.
   * @param expirySeconds Tiempo de expiración de la firma en segundos (por defecto 15 minutos).
   * @returns La URL pre-firmada como string.
   */
  async getPresignedUrl(key: string, expirySeconds = 900): Promise<string> {
    const command = new GetObjectCommand({
      Bucket: this.bucketName,
      Key: key,
    });

    return getSignedUrl(this.s3Client, command, { expiresIn: expirySeconds });
  }
}
