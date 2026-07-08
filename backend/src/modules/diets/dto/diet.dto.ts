import { Type } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';

class DietMealDto {
  @IsString()
  @IsNotEmpty()
  hora: string;

  @IsString()
  @IsNotEmpty()
  nombre: string;

  @IsString()
  @IsNotEmpty()
  alimentos: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  calorias?: number;
}

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
  @ValidateNested({ each: true })
  @Type(() => DietMealDto)
  comidas: DietMealDto[];

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
  @ValidateNested({ each: true })
  @Type(() => DietMealDto)
  comidas?: DietMealDto[];

  @IsOptional()
  @IsString()
  sugerencias?: string;
}
