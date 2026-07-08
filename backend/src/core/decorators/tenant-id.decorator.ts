import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { AuthenticatedRequest } from '../types/authenticated-request';

export const TenantId = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest<AuthenticatedRequest>();
    const tenantId = request.tenantId ?? request.headers['x-tenant-id'];
    return typeof tenantId === 'string' ? tenantId : undefined;
  },
);
