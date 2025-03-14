@echo off
git config filter.sops.clean ".local/bin/sops-clean.cmd %%f"
git config filter.sops.smudge ".local/bin/sops-smudge.cmd"
git config filter.sops.required true
