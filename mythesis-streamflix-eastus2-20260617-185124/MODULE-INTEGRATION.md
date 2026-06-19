# AVM Input Mapping (R21_AVM_CAUTION)

This run intentionally uses raw `azurerm_*` resources to avoid AVM input mismatch risk.

- Candidate AVM modules were considered for VNet/NSG/PIP/VM.
- Mismatch risk: AVM object inputs differ from raw resource argument names and nesting.
- Decision: use raw resources with exact provider pinning for deterministic assembly.
