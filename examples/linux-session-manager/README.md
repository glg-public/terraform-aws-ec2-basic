# Amazon Linux 2 Example
Here is an Amzon Linux 2 example instance that does not require an SSH key pair name and will instead leverage [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html). Notice the additional IAM role and policies within the example. The `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore` is the special sauce that allows AWS to get in to your instance without any security group modifications or SSH key pairs.

You can read more about [AWS Systems Manager Session Manager here.](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)

# Prerequisites:
1. An existing or newly created VPC
2. The VPC be tagged with `is_glg_default = "true"`
3. A subnet that routes to an IGW (use an existing or create a new subnet)