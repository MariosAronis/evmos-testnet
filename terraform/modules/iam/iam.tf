# Following section creates the policies and roles needed for github runners
# to assume temporary permissions (with short-lived-credentials) against aws cloud
# resources:

# - an openID connect provider
# - an assume role policy document that uses openID provider to allocate
#   permissions to GH Actions based on source repo owner/name
# - an iam policy with proper allow rules
# - an iam role to attach the policy to
# - an iam policy attachment rule

resource "aws_iam_role" "evmosnode" {
  name = "evmosnode"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            }
        }
    ]
}
EOF
  tags = {
    Name = "evmosnode_role"
  }
}

resource "aws_iam_instance_profile" "evmosnode-profile" {
  name = "evmosnode-profile"
  role = aws_iam_role.evmosnode.name
}

# Configures the preinstalled SSM agent running on the ec2 host to
# accept SSM signaling from AWS Systems Manager
resource "aws_iam_policy_attachment" "EvmosNodeSSMManagedInstance" {
  name       = "ssm-evmos-policy-att"
  roles      = [aws_iam_role.flashnode.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create the OIDC provider [REFERENCE: https://github.com/philips-labs/terraform-aws-github-oidc/tree/main/modules/provider]
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.thumbprint_list
  tags = {
    Name = "GithubUser"
  }
}

output "openid_connect_provider" {
  depends_on  = [aws_iam_openid_connect_provider.github_actions]
  description = "AWS OpenID Connected identity provider."
  value       = aws_iam_openid_connect_provider.github_actions
}

data "aws_iam_openid_connect_provider" "github_actions" {
  depends_on = [aws_iam_openid_connect_provider.github_actions]
  arn        = aws_iam_openid_connect_provider.github_actions.arn
}

#Create Assume Role policy Document for GH workflows/runners
data "aws_iam_policy_document" "evmos-testnet-deployments-assume_role-slc" {
  depends_on = [aws_iam_openid_connect_provider.github_actions]
  statement {
    effect = "Allow"

    principals {
      type = "Federated"
      # identifiers = [data.aws_iam_openid_connect_provider.github_actions.arn]
      identifiers = [data.aws_iam_openid_connect_provider.github_actions.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:MariosAronis/evmos-WIP:*"]
    }
  }
}

# Create policy for evmos-testnet deployments
# Allows a set of controls against specific:
# - security-group(s) [region and account id wildcarded but wer can further tighten the policy if needed]
# - subnet(s) [region and account id wildcarded but wer can further tighten the policy if needed]
# - ec2 keyPair
# - instance types
# - aws artifactory
resource "aws_iam_policy" "evmos-testnet-deployments-deploy" {
  name = "EvmosTestnetDeployments"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"ec2:Describe*",
				"ec2:GetConsole*"
			],
			"Resource": "*"
		},
		{
			"Sid": "VisualEditor1",
			"Effect": "Allow",
			"Action": [
				"ec2:RebootInstances",
				"ec2:TerminateInstances",
				"ec2:DeleteTags",
				"ec2:StartInstances",
				"ec2:CreateTags",
				"ec2:RunInstances",
				"ec2:StopInstances",
        "ec2:CreateVolume",
        "ec2:AttachVolume",
        "ec2:DetachVolume" ,
        "iam:GetInstanceProfile",
        "iam:PassRole"
			],
			"Resource": [
				"arn:aws:ec2:*::image/ami-*",
				"arn:aws:ec2:*:*:instance/*",
				"arn:aws:ec2:*:*:key-pair/*",
				"arn:aws:ec2:*:*:volume/*",
				"arn:aws:ec2:*:*:security-group/sg-06d9f0fd0b749c6ee",
				"arn:aws:ec2:*:*:subnet/subnet-0160d2ef49ea42ecc",
				"arn:aws:ec2:*:*:network-interface/*",
        "arn:aws:iam::044425962075:instance-profile/flashnode_profile",
        "arn:aws:iam::044425962075:role/flashnode"
			],
			"Condition": {
				"ForAllValues:StringEquals": {
					"ec2:KeyPairName": [
						"mariosee"
					]
				},
				"ForAllValues:StringLike": {
					"ec2:InstanceType": [
						"t3.*",
						"t3a.*"
					]
				}
			}
		}
	]
}
EOF
}

# Create iam role for evmos-testnet deployments' GH runners/actions
resource "aws_iam_role" "evmos-testnet-deploy-slc" {
  name               = "evmos-testnet-deploy-slc"
  assume_role_policy = data.aws_iam_policy_document.evmos-testnet-deployments-assume_role-slc.json

  tags = {
    Name = "evmos-testnet-deployments-assume_role-slc"
  }
}

resource "aws_iam_role_policy_attachment" "EvmosTestnetDeploymentRoleSLC" {
  role       = aws_iam_role.evmos-testnet-deploy-slc.name
  policy_arn = aws_iam_policy.evmos-testnet-deployments-deploy.arn
  depends_on = [ aws_iam_policy.evmos-testnet-deployments-deploy ]
}


# This attaches AmazonSSMFullAccess policy to our IAM role that is 
# allocated to the git hub runners via slc. Allows GH runners to
# control EC2s via AWS Systems Manager run-command (allows execution
# of shell commands/scripts, ansible playbooks etc)

# ATTENTION: This does not set permission boundaries. Permissions' set 
# can/should be tightened to allow only required ones
resource "aws_iam_role_policy_attachment" "EvmosNodesSSMFullAccess" {
  role       = aws_iam_role.evmos-testnet-deploy-slc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}