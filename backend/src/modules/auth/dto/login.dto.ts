import { IsEmail, IsNotEmpty, IsString, IsOptional } from 'class-validator';

export class LoginDto {
  @IsString({ message: 'El correo electrónico o DNI debe ser una cadena de texto.' })
  @IsNotEmpty({ message: 'El correo electrónico o DNI es requerido.' })
  emailOrDni: string;

  @IsString({ message: 'La contraseña debe ser una cadena de texto.' })
  @IsNotEmpty({ message: 'La contraseña es requerida.' })
  password: string;

  @IsString({ message: 'El ID de inquilino (Tenant) debe ser una cadena de texto.' })
  @IsOptional()
  tenantId?: string;
}
