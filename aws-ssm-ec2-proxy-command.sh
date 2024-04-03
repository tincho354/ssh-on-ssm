#!/usr/bin/env sh
set -eu

ec2_instance_id="$1"
aws_region="us-west-2" # Asegúrate de ajustar esto a tu región AWS
ssh_user="$2"
ssh_port="$3"
ssh_public_key_path="${HOME}/.ssh/id_rsa_aws.pub"

# Asegúrate de que la clave pública SSH se inserta correctamente aquí
ssh_public_key="$(cat "${ssh_public_key_path}")"

# Añade temporalmente la clave pública SSH a la instancia EC2
aws ssm send-command \
  --instance-ids "${ec2_instance_id}" \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[\"cd /home/${ssh_user}/.ssh || exit 1\", \"if ! grep -q -F '${ssh_public_key}' authorized_keys; then echo '${ssh_public_key}' >> authorized_keys; fi\"]" \
  --comment "Grant SSH access" \
  --region "${aws_region}"

# Inicia la sesión SSM SSH
aws ssm start-session \
  --target "${ec2_instance_id}" \
  --document-name "AWS-StartSSHSession" \
  --parameters "portNumber=${ssh_port}" \
  --region "${aws_region}"
