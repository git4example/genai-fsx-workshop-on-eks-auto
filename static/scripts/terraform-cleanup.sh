#!/bin/bash
terraform --version

terraform destroy --auto-approve

echo "Cleanup completed."