import { IsBoolean, IsIn, IsOptional, IsString } from 'class-validator';

export class UpdatePreferencesDto {
  @IsOptional()
  @IsString({ message: 'El modo de tema debe ser una cadena de texto.' })
  @IsIn(['system', 'light', 'dark'], {
    message: 'El modo de tema debe ser system, light o dark.',
  })
  themeMode?: 'system' | 'light' | 'dark';

  @IsOptional()
  @IsBoolean({
    message: 'La visibilidad de entrenamiento debe ser verdadero o falso.',
  })
  trainingVisible?: boolean;
}
