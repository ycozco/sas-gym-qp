import {
  IsArray,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateDietPlanDto {
  @IsUUID()
  memberId: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @IsPositive()
  pesoObjetivoKg?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  caloriasObjetivo?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  proteinasG?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  carbohidratosG?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  grasasG?: number;

  @IsArray()
  comidas: any[];

  @IsOptional()
  @IsString()
  sugerencias?: string;
}

export class UpdateDietPlanDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @IsPositive()
  pesoObjetivoKg?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  caloriasObjetivo?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  proteinasG?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  carbohidratosG?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  grasasG?: number;

  @IsOptional()
  @IsArray()
  comidas?: any[];

  @IsOptional()
  @IsString()
  sugerencias?: string;
}
