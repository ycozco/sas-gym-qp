CREATE TABLE "SaasPlan" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "descripcion" TEXT,
    "precio_mensual" DOUBLE PRECISION NOT NULL,
    "limite_usuarios" INTEGER NOT NULL,
    "caracteristicas" TEXT NOT NULL,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SaasPlan_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "SaasPlan_code_key" ON "SaasPlan"("code");

ALTER TABLE "Tenant"
ADD CONSTRAINT "Tenant_plan_saas_fkey"
FOREIGN KEY ("plan_saas") REFERENCES "SaasPlan"("code")
ON DELETE RESTRICT ON UPDATE CASCADE;
