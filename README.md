# evmos-testnet
IaC for an evmos validator testnet

## Intro

This projects provides the necessary resources to automate deployment of a complete environment for hosting 
a private evmos testnet with multiple validators hosted on separate ec2 nodes.

## Modules:

1. VPC
  Defines:
    - networking (subnets, routing tables, peering routes, IGWs, NAT GWs)
    - security groups
2. INSTANCES
    Defines:
     - A set of validator nodes
     - An AWS marketplace AMI for openvpn access server
3. IAM
    Defines the necessary infra that enables GH Actions runners to acquire AWS short lived credentials (SLCs).
    SLCs are used within the GH worflows for various actions:
    - upload artifacts (evmosd binary) to AWS artifactory
    - interact with AWS EC2 instances for remote executions (shell commands, bash scripts, ansible playbooks) via
      AWS SSM module.
    IAM instance profile for AWS SSM: Configures the preinstalled SSM agent running on the ec2 host to accept SSM
      signaling from AWS Systems Manager
4. CodeArtifact: TODO 
    Defines AWS managed build artifact storage

## Prerequistes

1. AWS account & API access keys with admin permissions
2. An EC2 key-pair
3. Terraform Cloud account

## Deployment Instructions

### Terraform Cloud
 - Create an organization
 - Create a new workspace pointing to your fork of the evmos-testnet
 - In workspace > variables define the following:
    - a variable set consisting of AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY. **MAKE SURE TO MARK BOTH VARIABLES AS
       SENSITIVE**
    - Environment Variables :
       1. admin-public-ip: . **MAKE SURE TO MARK
          AS SENSITIVE** [See further instructions below] 
       2. az-1: availability zone according to region, for example us-west-2a 
       3. az-2: availability zone according to region, for example us-west-2b
       4. cidr_prefix_testnet: X.X.0.0/16 segnments for the validators subnets (for example 10.30)
       5. cidr_prefix_vpn: X.X.0.0/16 segnments for the openvpnas subnets (for example 10.50)
       6. ec2-count: number fo validator nodes to deploy
       7. private_key: Name of the EC2 kay pair used for ssh access to validator nodes and openvpnas. **MAKE SURE TO MARK
          AS SENSITIVE**
       8. region: AWS region for example us-west-2
       9. storage: Storage of the evmos validator nodes in GB
       10. vpn_instance_type: Instance type for the openvpnas host. Has been tested on t3.micro with up to 2 concurrent 
           connections

We can trigger the TF Cloud workspace run manually, from the Runs section or by pushing to main. Once trigerred the workspace creates a tf execution plan and queues a plan application step that expects manual acknowledgement. Once application is finished, the plan outputs the following:

1. openvpnas public IP
2. evmos validator nodes' Private IPs

Variable **admin-public-ip** is used to configure the vpc security groups to allow ssh access to openvpnas on it's public IP. Should be the IP of a trusted machine. Login to the openvpn server (from the trusted machine) as user openvpnas, on it's public IP using the private key set in variable 7. INstallation procedure will start automatically. Acknowledge all defaults apart from openvpn admin password. Terminal will output the url to admin interface (https://publicip/admin). Login as openvpn user and under VPN settings > routing add the /16 network for evmos validators set in variable cidr_prefix_testnet. 
Save and reload the service.
Now visit https://publicip/ and follow the instructions to configure your local openvpn client and download the client configuration file. Login instructions are also provided. 

