
#######################################################################
## Populate initialised variables if using shell env or use az login
#######################################################################
arm_tenant_id       = "wwww-xxxx-yyyy-zzzz"
arm_subscription_id = "wwww-xxxx-yyyy-zzzz"
arm_client_id       = "wwww-xxxx-yyyy-zzzz"

tags = {
  "environment" = "dev-test"
  "purpose"     = "app-gateway-lab"
  "createdby"   = "terraform"
}
