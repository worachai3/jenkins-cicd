# Integrate Jenkins with Valut

1. **Apply terraform**
    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

2. **Configure Vault**
    - Start vault server
        ```bash
        vault server -config=config.hcl
        ```
    - Initialize vault
        ```bash
        vault operator init
        ```
    - Unseal vault
        ```bash
        vault operator unseal
        ```
    - Login
        ```bash
        vault login
        ```
    - Enable approle auth method
        ```bash
        vault auth enable approle
        ```
    - Create role
        ```bash
        vault write auth/approle/role/jenkins-role token_num_uses=0 secret_id_num_uses=0 policies="jenkins"
        vault read auth/approle/role/jenkins-role/role-id
        vault write -f auth/approle/role/jenkins-role/secret-id
        ```
    - Enable kv secret engine
        ```bash
        vault secrets enable -path=secret kv
        ```
    - Add secret
        ```bash
        vault kv put secret/jenkins username="admin" password="admin"
        ```
    - Create policy
        ```bash
        vault policy write jenkins jenkins-policy.hcl
        ```
        - jenkins-policy.hcl
            ```hcl
            path "secret/jenkins" {
                capabilities = ["read", "list"]
            }
            ```
3. **Configure Jenkins**
    - Install plugins
        - [HashiCorp Vault Plugin](https://plugins.jenkins.io/hashicorp-vault-plugin/)
        - [Credentials Binding Plugin](https://plugins.jenkins.io/credentials-binding/)
    - Configure Vault
        - Manage Jenkins > Configure System > HashiCorp Vault
        - Vault URL: http://vault:8200
        - Vault Credential ID: vault
        - Test connection
    - Create credentials
        - Credentials > System > Global credentials (unrestricted) > Add Credentials
        - Kind: Vault AppRole Credential
        - Scope: Global
        - ID: vault-jenkins-role
        - Role ID: <role_id>
        - Secret ID: <secret_id>
    - Create pipeline
        - New Item > Pipeline
        - Pipeline > Pipeline script from SCM
        - SCM: Git
        - Repository URL: https://github.com/worachai3/jenkins-cicd.git
        - Script Path: pipeline/Jenkinsfile

** Troubleshooting **
- Connection timeout to vault server
    - Check vault server is running
    - Check vault host is correct (use private ip for aws ec2 in jenkins configuration)
    - Check vault security group allow port 8200


https://amitsharma13318.medium.com/launching-aws-infrastructure-using-terraform-and-utilizing-hashicorp-vault-to-store-credentials-a15d0d0bcb26