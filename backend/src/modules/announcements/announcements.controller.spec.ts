import { Test, TestingModule } from '@nestjs/testing';
import { AnnouncementsController } from './announcements.controller';
import { AnnouncementsService } from './announcements.service';
import { Role } from '@prisma/client';
import { ROLES_KEY } from '../../core/decorators/roles.decorator';
import { JwtService } from '@nestjs/jwt';

describe('AnnouncementsController Security', () => {
  let controller: AnnouncementsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AnnouncementsController],
      providers: [
        {
          provide: AnnouncementsService,
          useValue: {
            findActive: jest.fn(),
            findAll: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
            toggle: jest.fn(),
          },
        },
        {
          provide: JwtService,
          useValue: {
            verifyAsync: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<AnnouncementsController>(AnnouncementsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('Route Guard & Role Rules', () => {
    it('getActiveBanners should allow MEMBER role', () => {
      const roles: Role[] = Reflect.getMetadata(ROLES_KEY, controller.getActiveBanners);
      expect(roles).toBeDefined();
      expect(roles).toContain(Role.MEMBER);
    });

    it('createBanner should restrict to ADMIN and NOT allow MEMBER', () => {
      const roles: Role[] = Reflect.getMetadata(ROLES_KEY, controller.createBanner);
      expect(roles).toBeDefined();
      expect(roles).toContain(Role.ADMIN);
      expect(roles).not.toContain(Role.MEMBER);
    });

    it('updateBanner should restrict to ADMIN and NOT allow MEMBER', () => {
      const roles: Role[] = Reflect.getMetadata(ROLES_KEY, controller.updateBanner);
      expect(roles).toBeDefined();
      expect(roles).toContain(Role.ADMIN);
      expect(roles).not.toContain(Role.MEMBER);
    });

    it('toggleActive should restrict to ADMIN and NOT allow MEMBER', () => {
      const roles: Role[] = Reflect.getMetadata(ROLES_KEY, controller.toggleActive);
      expect(roles).toBeDefined();
      expect(roles).toContain(Role.ADMIN);
      expect(roles).not.toContain(Role.MEMBER);
    });
  });
});
