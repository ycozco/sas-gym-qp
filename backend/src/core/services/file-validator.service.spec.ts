import { BadRequestException } from '@nestjs/common';
import { FileValidatorService } from './file-validator.service';

describe('FileValidatorService', () => {
  let service: FileValidatorService;

  beforeEach(() => {
    service = new FileValidatorService();
  });

  it('debe permitir archivos JPG/JPEG con firma binaria correcta', () => {
    const buffer = Buffer.from('ffd8ffe000104a464946', 'hex'); // Cabecera JFIF JPEG
    const result = service.validateBuffer(buffer, ['jpg', 'jpeg', 'png']);
    expect(result).toBe(true);
  });

  it('debe permitir archivos PNG con firma binaria correcta', () => {
    const buffer = Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex'); // Cabecera PNG estándar
    const result = service.validateBuffer(buffer, ['png']);
    expect(result).toBe(true);
  });

  it('debe permitir archivos PDF con firma binaria correcta', () => {
    const buffer = Buffer.from('255044462d312e340a', 'hex'); // %PDF-1.4
    const result = service.validateBuffer(buffer, ['pdf']);
    expect(result).toBe(true);
  });

  it('debe lanzar BadRequestException si el buffer está vacío', () => {
    const buffer = Buffer.alloc(0);
    expect(() => service.validateBuffer(buffer, ['png'])).toThrow(BadRequestException);
    expect(() => service.validateBuffer(buffer, ['png'])).toThrow('El archivo está vacío.');
  });

  it('debe lanzar BadRequestException si la firma no es reconocida (ej. malware)', () => {
    const buffer = Buffer.from('4d5a900003000000', 'hex'); // Cabecera ejecutable MZ PE (Windows .exe)
    expect(() => service.validateBuffer(buffer, ['png', 'jpg'])).toThrow(BadRequestException);
    expect(() => service.validateBuffer(buffer, ['png', 'jpg'])).toThrow(
      'Firma binaria de archivo no reconocida u origen potencialmente malicioso.',
    );
  });

  it('debe lanzar BadRequestException si el tipo detectado no está en la lista permitida', () => {
    const buffer = Buffer.from('255044462d312e340a', 'hex'); // PDF
    // Intentamos subir PDF cuando sólo se permiten imágenes
    expect(() => service.validateBuffer(buffer, ['png', 'jpeg'])).toThrow(BadRequestException);
    expect(() => service.validateBuffer(buffer, ['png', 'jpeg'])).toThrow(
      'Tipo de archivo no permitido. Tipos permitidos: png, jpeg',
    );
  });
});
