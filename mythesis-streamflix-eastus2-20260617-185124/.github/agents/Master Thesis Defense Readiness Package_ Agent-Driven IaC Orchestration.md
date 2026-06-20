# Master Thesis Defense Readiness Package: Agent-Driven IaC Orchestration

## 1. Introduction and Research Alignment

This document serves as the definitive narrative for the Proof-of-Concept (POC) implementation developed for the Master's thesis. The research investigates the efficacy of moving beyond raw Large Language Model (LLM) code generation toward a structured, **specification-driven AI orchestration** approach for Infrastructure-as-Code (IaC).

The POC is framed as a **Design Science Research (DSR) artifact**. It demonstrates a reproducible, governed, and highly structured method for deploying Azure infrastructure. By integrating advanced AI capabilities with established DevOps practices (GitOps, CI/CD, Human-in-the-Loop), the artifact directly addresses the research questions regarding the reliability, security, and operational viability of AI in cloud provisioning.

## 2. The "7+1+1" Agentic Framework

To overcome the limitations of monolithic prompt engineering (which often leads to hallucinations and inconsistent outputs), the POC employs a modular "7+1+1" agentic framework within VS Code Copilot. This separation of concerns ensures that each agent is highly specialized and context-aware.

### The Orchestrator (1)
*   **IaC Workflow Orchestrator:** The central manager. It maintains the environment context (memory via `context.json`), sequences the execution of subagents, and enforces supervisory monitoring to ensure no critical data is missed between phases.

### The Specialized Agents (7)
1.  **Requirement Normalizer:** Translates ambiguous natural language into a precise, structured JSON specification. It employs a "Clarification Loop" to explicitly ask the user for missing details (e.g., VM size, region).
2.  **Architecture Mapper:** Consumes the JSON specification to generate a visual representation (PlantUML) of the proposed Azure architecture, providing an early visual validation step.
3.  **Module Discoverer:** Identifies the appropriate Terraform modules required for the deployment. Crucially, it strictly prioritizes **Azure Verified Modules (AVM)**.
4.  **Module Parameterizer:** Maps the structured JSON requirements and environment context to the specific input variables required by the discovered modules.
5.  **Terraform Assembler:** Generates the final `.tf` files (`main.tf`, `variables.tf`, etc.), assembling the parameterized modules into a cohesive configuration.
6.  **CI/CD Generator:** Creates the GitHub Actions workflow (`deploy.yml`). It configures secure **OpenID Connect (OIDC)** authentication and establishes a Pull Request (PR) based deployment strategy.
7.  **Validator & Governor:** The critical quality gate. It performs syntax validation, security checks, and generates the `terraform plan`. It utilizes advanced AI logic (akin to Codex 5.2) for automated corrections and facilitates the final chat-based human approval before PR creation.

### The Documentation Agent (1)
*   **POC Documentary Agent:** The final step in the lifecycle. It automatically compiles a formal, academic-quality case study document detailing the deployment metrics, challenges encountered, and lessons learned, directly supporting the DSR evaluation phase.

## 3. Workflow Architecture

The following diagram illustrates the end-to-end orchestration process, highlighting the sequential data flow and the integration of human approval gates.

![IaC Orchestration Workflow](https://private-us-east-1.manuscdn.com/sessionFile/6r1wsbmpmSvBLUr21W3Il5/sandbox/cDUpnR3FcuhYz3qVGY1qCj-images_1778347416498_na1fn_L2hvbWUvdWJ1bnR1L3dvcmtmbG93X2RpYWdyYW0.png?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9wcml2YXRlLXVzLWVhc3QtMS5tYW51c2Nkbi5jb20vc2Vzc2lvbkZpbGUvNnIxd3NibXBtU3ZCTFVyMjFXM0lsNS9zYW5kYm94L2NEVXBuUjNGY3VoWXozcVZHWTFxQ2otaW1hZ2VzXzE3NzgzNDc0MTY0OThfbmExZm5fTDJodmJXVXZkV0oxYm5SMUwzZHZjbXRtYkc5M1gyUnBZV2R5WVcwLnBuZyIsIkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTc5ODc2MTYwMH19fV19&Key-Pair-Id=K2HSFNDJXOU9YS&Signature=IXGgX7sj0thJT~KKwGGTU81iWcam9OF9twyDTA3g-Zyiciv-m7~LQvN7n~UYt2vTP9zck7hi2IObhzbtiTls~QRtQ6jtA3xm62NDC4BG6~AkIQ2YP0Oo-yEeULbQb2TyHAZOLe~druzU4CFAG5isYHVefAlrXvJfhLBvQ1bKBjbN4Q5wp4b99q8uk~ltxz59Qlhm-TAc~Tgi2eubPtdzygUUaVaHcVZPpnpKnSS1ZHYlxhwekje297DVJ4Hn5m5IcKp~pgeTzFd46~9y5THCj6s338AfBF0SgdQ4H4nznGb59MioIJvZqcCanXmVwjtOzX8KJZJu3hfsgVvwlIV1LA__)

## 4. Technical Rationale: Specification-Driven Orchestration

A core innovation of this POC is the **Specification-Driven** approach. Instead of asking an LLM to "write Terraform code for a VM," the system first translates the request into a **Structured JSON Specification**.

**Why this matters:**
*   **Reduces Hallucinations:** By forcing the AI to populate a strict JSON schema first, we eliminate the creative liberties that lead to syntactically incorrect or insecure code.
*   **Deterministic Validation:** A JSON object can be programmatically validated against a schema before any code is generated. If a required field (like `region`) is missing, the workflow halts and prompts the user, rather than guessing.
*   **Stateful Handoffs:** The JSON acts as the "source of truth" passed between agents. The `Module Parameterizer` doesn't need to read the user's original chat prompt; it only reads the precise JSON, ensuring consistency across the pipeline.

## 5. Error Prevention via Azure Verified Modules (AVM)

A defining characteristic of this implementation is the strategic decision to **avoid generating raw Terraform resource blocks from scratch**. Instead, the `Module Discoverer` and `Terraform Assembler` agents are strictly instructed to utilize **Azure Verified Modules (AVM)** [1].

**The Rationale for AVM:**
*   **Security by Default:** AVMs are developed and maintained by Microsoft, ensuring they adhere to the Azure Well-Architected Framework and incorporate best-practice security configurations out-of-the-box.
*   **Error Reduction:** Generating raw HCL (HashiCorp Configuration Language) is prone to syntax errors and API version mismatches. By orchestrating pre-validated modules, the AI's task shifts from *writing code* to *parameterizing known-good code*, drastically reducing the error surface area.
*   **Enterprise Viability:** This approach mirrors how mature enterprise DevOps teams operate, making the POC highly relevant to real-world industry scenarios.

## 6. Governance and Human-in-the-Loop (HITL)

The POC integrates governance directly into the workflow, aligning with modern GitOps principles [2].

*   **OIDC Authentication:** The `CI/CD Generator` configures GitHub Actions to use OpenID Connect, eliminating the need for long-lived, hardcoded Azure credentials (secrets) in the repository.
*   **PR-Based Approval Strategy:** The deployment is not fully autonomous. The `Validator & Governor` agent prepares the code and the `terraform plan`, but the actual `terraform apply` is gated behind a GitHub Pull Request. This ensures that a human operator retains final authority over infrastructure changes, satisfying compliance and security requirements.

## 7. Conclusion

This POC demonstrates that AI can be effectively harnessed for cloud infrastructure provisioning when constrained by a structured, multi-agent architecture. By combining specification-driven logic, the reuse of validated modules (AVM), and strict GitOps governance, the artifact provides a robust foundation for the Master's thesis evaluation and defense.

---
### References

[1] Microsoft. "Azure Verified Modules." Available: https://azure.github.io/Azure-Verified-Modules/. Accessed: May 2026.
[2] GitHub. "GitOps with GitHub Actions." Available: https://docs.github.com/en/actions/use-cases-and-examples/deploying/deploying-with-github-actions. Accessed: May 2026.
