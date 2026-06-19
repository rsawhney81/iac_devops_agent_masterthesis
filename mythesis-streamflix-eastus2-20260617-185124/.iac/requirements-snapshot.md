# requirements-canon.md - machine-checkable requirements

| id  | requirement                                                          | enforcement stage          | check type    |
|-----|----------------------------------------------------------------------|----------------------------|---------------|
| R01 | Backend + azurerm provider auth validated before plan                | Preflight                  | deterministic |
| R02 | VM size confirmed available AND within quota in region               | Preflight / Discoverer     | deterministic |
| R03 | CI/CD pipeline (deploy.yml) must be generated, not skipped           | post CI/CD Generator       | deterministic |
| R04 | SSH restricted to operator /32 only (never 0.0.0.0/0)                | post Assembler / Validator | deterministic |
| R05 | cloud-init wait/retry loop runs BEFORE HTTP check                    | post-apply validation      | deterministic |
| R06 | Per-phase + end-to-end timestamps captured during run                | Orchestrator (step 0)      | deterministic |
| R07 | Resource naming convention consistent + documented                   | Assembler                  | judgment      |
| R08 | Documentary Agent emits only ACTUAL measured values                  | Documentary                | judgment      |
| R09 | AVM module names must be EXACT registry IDs; verify before init      | Module Discoverer          | deterministic |
| R10 | Pin exact AVM module source + version; do NOT discover by trial      | Module Discoverer          | deterministic |
| R11 | PlantUML PNG must be RENDERED and verified to exist (separate from .puml) | post Architecture Mapper | deterministic |
| R12 | Terraform binary/version resolved at preflight (no mid-run switch)   | Preflight                  | deterministic |
| R13 | All metric timestamps written in UTC (single timezone)              | metrics protocol           | deterministic |
| R14 | Lessons written to canon INCREMENTALLY as gaps occur, not only at step 10 | every stage           | deterministic |
| R20 | Cloud-init YAML must be explicitly marked with content-type header in custom_data; base64 encoding alone is insufficient. Verify cloud-init logs on VM after provisioning: ssh into VM and check 'sudo cloud-init status' and 'sudo tail -n 50 /var/log/cloud-init-output.log' before considering deployment complete. | pre-apply             | judgment      |
| R21_AVM_CAUTION | Before using any Azure Verified Module, consult the module's registry documentation for input parameter names and types. AVM input names frequently differ from raw azurerm resource names (e.g., AVM.virtual_network_name vs azurerm.name). Build a parameter mapping document during module discovery phase. | module discovery      | judgment      |
| R22_VERSION_PINNING_EXACT | All Terraform and provider versions MUST use exact pinning (= X.Y.Z syntax) not ranges (~> or >=). No exceptions. Rationale: Reproducibility across team members and time requires bit-for-bit identical provider behavior. Add deterministic grep check: block terraform init if ~> or >/< ranges found in versions.tf or providers.tf. | pre-init              | deterministic |

# narrative lessons (context, not gates)
- 2026-05-25 Poland Central: client_id in context.json failed provider auth -> fell back to Azure CLI. (R01)
- 2026-05-25 Poland Central: several SKUs rejected on capacity/quota despite being listed. (R02)
- 2026-05-25 Poland Central: first public HTTP check failed - Nginx not active yet after cloud-init. (R05)
- 2026-06-12 eastus2 run: AVM public IP module name was wrong - registry name is avm-res-network-publicipaddress, NOT avm-res-network-publicip. Wrong names caused module-discovery thrash. (R09)
- 2026-06-12 eastus2 run: agent burned the entire credit budget doing AVM registry trial-and-error discovery and schema matching during validation/init. Pin exact module coordinates up front. (R10)
- 2026-06-12 eastus2 run: architecture.puml was generated but architecture.png was never rendered - the PNG render is a separate java -jar plantuml.jar step that did not fire. (R11)
- 2026-06-12 eastus2 run: lost time mid-run switching to the unzipped Terraform 1.15.5 binary; version/path must be settled at preflight. (R12)
- 2026-06-12 eastus2 run: phase_timings.csv mixed local (+02:00) and UTC (Z) timestamps - standardize on UTC. (R13)
- 2026-06-12 eastus2 run: run exhausted Copilot credits during validation, before step 10, so NO learning was written to canon. Lessons must append incrementally as each gap is hit. (R14)
- 2026-06-12 eastus2 run: positive result - R09/R10 incremental capture (phase_timings.csv, events.csv, execution.log) worked and survived the crash; only the end-of-run metrics.json/validation.json were lost. Incremental capture is the right pattern.
- 2026-06-17 StreamFlix eastus2: AVM module approach abandoned after schema mismatches (avm-res-network-publicipaddress expected virtual_network_name + admin_ssh_keys array vs azurerm resource names); switched to raw azurerm_* blocks. Cloud-init YAML in custom_data treated as shell script despite base64 encoding; manual NGINX deployment verified infrastructure; requires explicit content-type header validation. Provider versions changed from loose ranges (~> 4.0) to exact pins (azurerm = 4.14.0) for reproducibility. VM zone variable corrected from string "1" to number 1. Total corrections: 4 unplanned (AVM mismatch, cloud-init, version ranges, zone type). Lessons captured: R20 (cloud-init custom-data best practices), R21_AVM_CAUTION (AVM documentation discipline), R22_VERSION_PINNING_EXACT (tighter enforcement).
