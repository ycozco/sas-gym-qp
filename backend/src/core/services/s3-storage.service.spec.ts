import { Test, TestingModule } from '@nestjs/testing';
import { S3StorageService } from './s3-storage.service';
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

// Mockear el presigner
jest.mock('@aws-sdk/s3-request-presigner', () => ({
  getSignedUrl: jest
    .fn()
    .mockResolvedValue('https://mocked-signed-url.com/file'),
}));

// Mockear el cliente S3
jest.mock('@aws-sdk/client-s3', () => {
  const original = jest.requireActual('@aws-sdk/client-s3');
  return {
    ...original,
    S3Client: jest.fn().mockImplementation(() => ({
      send: jest.fn().mockResolvedValue({}),
    })),
  };
});

describe('S3StorageService', () => {
  let service: S3StorageService;
  let mockS3ClientInstance: any;

  beforeEach(async () => {
    // Resetear mocks antes de cada prueba
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [S3StorageService],
    }).compile();

    service = module.get<S3StorageService>(S3StorageService);
    service.onModuleInit(); // Inicializa el cliente s3

    // Obtener la instancia mockeada del cliente
    mockS3ClientInstance = (S3Client as any).mock.results[0].value;
  });

  it('debe subir un archivo usando PutObjectCommand', async () => {
    const buffer = Buffer.from('test binary content');
    const key = 'uploads/member-123/profile.png';
    const mimeType = 'image/png';

    const result = await service.uploadFile(key, buffer, mimeType);

    expect(result).toBe(key);
    expect(mockS3ClientInstance.send).toHaveBeenCalledTimes(1);
    expect(mockS3ClientInstance.send.mock.calls[0][0]).toBeInstanceOf(
      PutObjectCommand,
    );
    expect(mockS3ClientInstance.send.mock.calls[0][0].input).toEqual({
      Bucket: 'sasgym-uploads',
      Key: key,
      Body: buffer,
      ContentType: mimeType,
    });
  });

  it('debe generar una URL pre-firmada usando GetObjectCommand', async () => {
    const key = 'uploads/receipt.pdf';
    const result = await service.getPresignedUrl(key, 600);

    expect(result).toBe('https://mocked-signed-url.com/file');
    expect(getSignedUrl).toHaveBeenCalledTimes(1);

    // El primer argumento es el cliente S3 mockeado
    expect(getSignedUrl).toHaveBeenCalledWith(
      mockS3ClientInstance,
      expect.any(GetObjectCommand),
      { expiresIn: 600 },
    );
  });
});
