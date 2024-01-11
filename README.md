# aws_terraform_application

This is not the first nor will it be the last of its kind which uses Terraform to create and manage AWS resources and assets.

## Prerequisites
- [You must have aws-cli and its own prerequisites installed.](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [You must have aws-cli is configured with the appropriate credentials.](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [You must have terraform and its own prerequisites installed.](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

## Notes

1. If you are not using AWS for your domain hosting, at the time of record validation for the certificate, you will need to [add those validation records with your DNS provider](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html).
2. There are five outputs currently available for `terraform output`:
	* hosted_zone: The hosted zone for the site.
	* validation_names: The validation record names for the site.
	* validation_values: The validation record values for the sites.
	* site_private-dns: The private DNS for the available instances.
	* site_private: The private IP for the available instances.
	* site_public-dns: The public DNS for the available instances.
	* site_public: The public IP for the available instances.
	* site_lb: The record used by the load balancer.
3. For the variable `site_ami`, this one may not be available in other regions outside of us-west-1
4. The IAM role is currently set for `AdministratorAccess` as a policy. This should probably be changed!
5. If you are using a new account that has not accessed some of these features being introduced, they may not work at first. AWS has an automated system which may need to be processed before available. After the initial creation, you may need to wait an hour or so before resources will be available. Otherwise, you will find the loadbalancer not forwarding traffic.
6. For DNS provided by other providers outside of AWS, you will need to make a CNAME record to point `site_domain` to the DNS name of the loadbalancer `site_lb`.

## TODO

1. Set up CloudFront for CDN.
2. Add additional cloudwatch logs for application.
3. CI/CD? GithHub actions?
4. Work on automatic deployment of some resources.
5. Incorporate load testing.
6. Other stuff.