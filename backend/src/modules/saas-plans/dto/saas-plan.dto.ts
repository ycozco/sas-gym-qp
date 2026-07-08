import {
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreateSaasPlanDto {
  @IsString()
  code: string;

  @IsString()
  nombre: string;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsNumber()
  @Min(0)
  precioMensual: number;

  @IsInt()
  @Min(1)
  limiteUsuarios: number;

  @IsString()
  caracteristicas: string;

  @IsOptional()
  @IsBoolean()
  activo?: boolean;
}

export class UpdateSaasPlanDto {
  @IsOptional()
  @IsString()
  nombre?: string;

  @IsOptional()
  @IsString()
  descripcion?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  precioMensual?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  limiteUsuarios?: number;

  @IsOptional()
  @IsString()
  caracteristicas?: string;

  @IsOptional()
  @IsBoolean()
  activo?: boolean;
}
