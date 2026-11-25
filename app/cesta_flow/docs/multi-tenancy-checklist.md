# Multi-tenancy (app) — checklist

Modelo: **1 usuário ↔ 1 `tenant_id`** (RLS no Supabase).

| # | Item | Status |
|---|------|--------|
| 1 | `profiles.tenant_id` no `Profile` + `TenantSession` + sync só com tenant | Feito (`24e83c7`) |
| 1 | Doc `supabase.md` (multi-tenant + RLS) | Feito |
| 2 | `withCurrentTenant` / `_withCurrentTenant` em writes (`customers`, `sales`, `baskets`, `sale_baskets`, `installments`) | Feito (`4d1950c`) |
| 3 | `SyncPreferences.last_tenant_id` + limpar ObjectBox se tenant mudar | Feito |
| — | Migrations SQL versionadas no repo | Pendente (feitas no painel Supabase) |
| — | Teste de integração validando `tenant_id` remoto | Pendente |