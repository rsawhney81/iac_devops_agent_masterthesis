# GitHub Actions Configuration Guide for Master's Thesis POC

This guide details the essential GitHub Actions configurations required to support your multi-agent IaC orchestration Proof-of-Concept (POC). Proper setup of these elements ensures secure authentication with Azure, enables automated CI/CD workflows, and facilitates human-in-the-loop approvals.

## 1. OpenID Connect (OIDC) for Secure Azure Authentication

OpenID Connect (OIDC) is the recommended method for authenticating GitHub Actions with Azure. It eliminates the need to store long-lived Azure credentials (like client secrets) directly in GitHub Secrets, significantly enhancing security.

### 1.1. Configure Azure AD Application (Service Principal)

Ensure your Azure AD Application (Service Principal) has federated credentials configured to trust your GitHub repository.

1.  **Navigate to your Service Principal:** In the Azure Portal, go to **Microsoft Entra ID** > **App registrations**, and select the Service Principal you created for your Terraform deployments.
2.  **Add Federated Credentials:**
    *   Under **Manage**, select **Certificates & secrets** > **Federated credentials**.
    *   Click **Add credential**.
    *   **Federated credential scenario:** Select `GitHub actions deploying Azure resources`.
    *   **Organization:** Enter your GitHub organization name (e.g., `rsawhney81`).
    *   **Repository:** Enter your GitHub repository name (e.g., `thesis-iac-agent`).
    *   **Entity type:** Select `Environment` (if you plan to use GitHub Environments for approvals) or `Branch` (e.g., `main`). For your thesis, using `Environment` is recommended for explicit approval gates.
    *   **Name:** Provide a descriptive name (e.g., `github-oidc-main-branch`).
    *   Click **Add**.

### 1.2. Grant Permissions to the Service Principal

Ensure your Service Principal has the necessary permissions to deploy resources in your Azure subscription.

1.  **Navigate to your Subscription or Resource Group:** In the Azure Portal, go to **Subscriptions** or the specific **Resource Group** where your resources will be deployed.
2.  **Add Role Assignment:**
    *   Select **Access control (IAM)** > **Add** > **Add role assignment**.
    *   **Role:** Assign the `Contributor` role (or a more granular custom role if preferred for production scenarios) to your Service Principal.
    *   **Members:** Select your Service Principal by name.
    *   Click **Review + assign**.

## 2. GitHub Secrets

While OIDC reduces the need for many secrets, some might still be necessary, or you might choose to store your `azure_client_secret` here if OIDC setup proves challenging (though OIDC is highly recommended).

### 2.1. Repository Secrets

1.  In your GitHub repository, navigate to **Settings** > **Secrets and variables** > **Actions**.
2.  Click **New repository secret**.
3.  **Recommended Secrets (if not using OIDC for all auth):**
    *   `AZURE_CLIENT_SECRET`: The client secret for your Service Principal (if OIDC is not fully configured for all authentication). **Note: OIDC is preferred.**
    *   `TF_VAR_resource_naming_prefix`: Your resource naming prefix (e.g., `mythesis-`).
    *   `TF_VAR_ssh_public_key`: Your SSH public key.

### 2.2. Environment Secrets (for specific environments)

If you use GitHub Environments for approvals (see Section 3), you can define secrets that are only available to workflows targeting that environment.

1.  In your GitHub repository, navigate to **Settings** > **Environments**.
2.  Select or create an environment (e.g., `production`).
3.  Under **Environment secrets**, click **Add secret**.

## 3. GitHub Environments for Human-in-the-Loop Approval

GitHub Environments provide a robust mechanism for implementing human-in-the-loop approvals, especially for critical deployment stages (e.g., `terraform apply`).

1.  In your GitHub repository, navigate to **Settings** > **Environments**.
2.  Click **New environment** (e.g., `production`).
3.  **Configure Environment Protection Rules:**
    *   **Required reviewers:** Check this box and select yourself or a team as reviewers. This will pause the workflow until the specified reviewers approve the deployment.
    *   **Wait timer:** Optionally, add a wait timer before deployment starts.
    *   **Deployment branches:** Specify which branches are allowed to deploy to this environment (e.g., `main`).
4.  **Integrate into GitHub Actions Workflow (`deploy.yml`):**
    Your `CI/CD Generator` agent will produce a `deploy.yml` that includes an `environment` key in the deployment job, linking it to this configured environment.

    ```yaml
    jobs:
      deploy:
        runs-on: ubuntu-latest
        environment: production # Links to your GitHub Environment
        steps:
          # ... terraform apply steps ...
    ```

## 4. GitHub Actions Workflow (`deploy.yml`) Structure

Your `CI/CD Generator` agent will create this file, but understanding its structure is key.

### 4.1. Triggering the Workflow

For a PR-based workflow, it typically triggers on `pull_request` and `push` events.

```yaml
on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main
```

### 4.2. Permissions for OIDC

Crucial for OIDC authentication. The `id-token: write` permission allows the workflow to fetch an OIDC token.

```yaml
permissions:
  id-token: write # Required for OIDC authentication
  contents: read # Required to checkout code
```

### 4.3. Terraform Plan on Pull Request

This job runs `terraform plan` when a pull request is opened or updated, posting the plan output as a comment.

```yaml
jobs:
  terraform_plan:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login (OIDC)
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }} # Use AZURE_CLIENT_ID from context.json
          tenant-id: ${{ secrets.AZURE_TENANT_ID }} # Use AZURE_TENANT_ID from context.json
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }} # Use AZURE_SUBSCRIPTION_ID from context.json

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.x

      - name: Terraform Init
        run: terraform init -backend-config="storage_account_name=${{ secrets.TF_BACKEND_STORAGE_ACCOUNT_NAME }}" -backend-config="container_name=${{ secrets.TF_BACKEND_CONTAINER_NAME }}" -backend-config="resource_group_name=${{ secrets.TF_BACKEND_RESOURCE_GROUP_NAME }}"
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }} # Only if not using OIDC for backend

      - name: Terraform Plan
        id: plan
        run: terraform plan -no-color -var="resource_naming_prefix=${{ secrets.TF_VAR_resource_naming_prefix }}" -var="ssh_public_key=${{ secrets.TF_VAR_ssh_public_key }}"
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }} # Only if not using OIDC for backend

      - name: Add Terraform Plan to PR Comment
        uses: actions/github-script@v6
        if: github.event_name == 'pull_request'
        with:
          script: |
            const output = `#### Terraform Plan 📖\n\n<details><summary>Show Plan</summary>\n\n```terraform\n${process.env.TF_PLAN}\n```\n\n</details>\n\n`;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })
        env:
          TF_PLAN: ${{ steps.plan.outputs.stdout }}
```

### 4.4. Terraform Apply on Push to `main` (with Environment Approval)

This job runs `terraform apply` only after a merge to `main` and, if configured, after a human approval in the GitHub Environment.

```yaml
  terraform_apply:
    runs-on: ubuntu-latest
    needs: terraform_plan # Ensures plan runs first
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    environment: production # Links to your GitHub Environment for approval
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login (OIDC)
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.x

      - name: Terraform Init
        run: terraform init -backend-config="storage_account_name=${{ secrets.TF_BACKEND_STORAGE_ACCOUNT_NAME }}" -backend-config="container_name=${{ secrets.TF_BACKEND_CONTAINER_NAME }}" -backend-config="resource_group_name=${{ secrets.TF_BACKEND_RESOURCE_GROUP_NAME }}"
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }} # Only if not using OIDC for backend

      - name: Terraform Apply
        run: terraform apply -auto-approve -var="resource_naming_prefix=${{ secrets.TF_VAR_resource_naming_prefix }}" -var="ssh_public_key=${{ secrets.TF_VAR_ssh_public_key }}"
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }} # Only if not using OIDC for backend
```

## 5. Important Considerations

*   **`context.json` vs. GitHub Secrets:** For values like `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, it is best practice to define them as GitHub Secrets and reference them in your workflow. Your `CI/CD Generator` agent will be updated to reflect this, but you will need to manually create these secrets in your GitHub repository settings.
*   **Service Principal Permissions:** Ensure the Service Principal used for OIDC has the necessary permissions in Azure (e.g., `Contributor` role on the target resource group).
*   **Branch Protection Rules:** Configure branch protection rules for your `main` branch to require pull request reviews before merging, further enforcing your human-in-the-loop process.

This comprehensive setup will provide a secure, automated, and governed CI/CD pipeline for your Master's thesis POC.
