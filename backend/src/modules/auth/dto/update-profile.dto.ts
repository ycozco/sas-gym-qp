import { IsNumber, IsOptional, IsString, IsObject } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  nombreCompleto?: string;

  @IsOptional()
  @IsString()
  celular?: string;

  @IsOptional()
  @IsString()
  nickname?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  pesoKg?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  alturaCm?: number;

  @IsOptional()
  @IsString()
  objetivo?: string;

  @IsOptional()
  @IsString()
  lesiones?: string;

  @IsOptional()
  @IsObject()
  medidasJson?: Record<string, number>;
}
