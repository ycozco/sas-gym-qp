import { Injectable, BadRequestException } from '@nestjs/common';

@Injectable()
export class FileValidatorService {
  /**
   * Valida un buffer de archivo contra firmas binarias conocidas (magic bytes).
   * @param buffer Buffer de datos del archivo.
   * @param allowedExtensions Extensiones permitidas (por ejemplo, ['jpg', 'jpeg', 'png', 'pdf']).
   * @returns true si el archivo es válido, de lo contrario lanza una excepción BadRequestException.
   */
  validateBuffer(buffer: Buffer, allowedExtensions: string[]): boolean {
    if (!buffer || buffer.length === 0) {
      throw new BadRequestException('El archivo está vacío.');
    }

    // Convertir los primeros 8 bytes a hexadecimal
    const hex = buffer.toString('hex', 0, 8).toUpperCase();

    // JPEG/JPG: FF D8 FF
    const isJpeg = hex.startsWith('FFD8FF');
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    const isPng = hex.startsWith('89504E470D0A1A0A');
    // PDF: 25 50 44 46
    const isPdf = hex.startsWith('25504446');

    const detectedTypes: string[] = [];
    if (isJpeg) detectedTypes.push('jpg', 'jpeg');
    if (isPng) detectedTypes.push('png');
    if (isPdf) detectedTypes.push('pdf');

    if (detectedTypes.length === 0) {
      throw new BadRequestException('Firma binaria de archivo no reconocida u origen potencialmente malicioso.');
    }

    // Verificar si el tipo detectado coincide con los permitidos
    const isAllowed = detectedTypes.some((type) => allowedExtensions.includes(type));
    if (!isAllowed) {
      throw new BadRequestException(
        `Tipo de archivo no permitido. Tipos permitidos: ${allowedExtensions.join(', ')}`,
      );
    }

    return true;
  }
}
