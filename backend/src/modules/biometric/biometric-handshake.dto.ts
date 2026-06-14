import { IsString, IsNotEmpty, IsUUID, IsBase64, Length } from 'class-validator';

export class BiometricHandshakeDto {
  @IsString()
  @IsNotEmpty()
  dispositivoId: string;

  @IsString()
  @IsNotEmpty()
  @IsBase64()
  datosHuella: string;

  @IsString()
  @IsNotEmpty()
  @Length(64, 64)
  hashVerificacion: string; // SHA-256 (64 caracteres hexadecimales)

  @IsString()
  @IsNotEmpty()
  @IsUUID()
  tokenRegistro: string;
}
