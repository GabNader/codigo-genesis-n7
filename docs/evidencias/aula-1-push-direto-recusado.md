# Evidência — recusa de push direto na `main` (Aula 1)

**Data:** 27/10/2026
**Repositório:** https://github.com/GabNader/codigo-genesis-n7
**Seções do PGC:** 3.3 (main protegida por PR obrigatório) e 5.2 (1 aprovação de outro integrante)

Depois de aplicar a regra clássica de proteção na `main` (PR obrigatório, 1 aprovação,
*dismiss stale reviews*, histórico linear e *Do not allow bypassing*, valendo também para
administradores), foi feito um commit direto na `main` local e tentado o envio:

```console
$ git commit --allow-empty -m "test: push direto na main (deve ser recusado)"
$ git push origin main
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote:
remote: - Changes must be made through a pull request.
To https://github.com/GabNader/codigo-genesis-n7.git
 ! [remote rejected] main -> main (protected branch hook declined)
error: failed to push some refs to 'https://github.com/GabNader/codigo-genesis-n7.git'
```

O push foi recusado mesmo vindo do dono do repositório (administrador). O commit de teste
foi descartado localmente (`git reset --hard origin/main`).

## Configuração conferida via API

```console
$ gh api repos/GabNader/codigo-genesis-n7/branches/main/protection
pr_obrigatorio: true · aprovacoes: 1 · dismiss_stale: true · linear: true · enforce_admins: true
```
