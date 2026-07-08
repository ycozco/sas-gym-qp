import { Global, Module } from '@nestjs/common';
import { RedisService } from './redis.service';
import { FileValidatorService } from './file-validator.service';
import { S3StorageService } from './s3-storage.service';

@Global()
@Module({
  providers: [RedisService, FileValidatorService, S3StorageService],
  exports: [RedisService, FileValidatorService, S3StorageService],
})
export class CoreServicesModule {}
