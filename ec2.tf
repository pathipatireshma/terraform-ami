resource "aws_instance" "ami" {
  ami                    = data.aws_ami.ami.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  tags = {
    Name = "${var.COMPONENT}-ami"
  }
}


resource "null_resource" "ansible-apply" {
  provisioner "remote-exec" {
    connection {
      host     = aws_instance.ami.private_ip
      user     = jsondecode(data.aws_secretsmanager_secret_version.latest.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.latest.secret_string)["SSH_PASS"]
    }
    inline = [
      "ansible-pull -U https://github.com/pathipatireshma/ansible roboshop-pull.yml -e COMPONENT=${var.COMPONENT} -e ENV=ENV -e strategy=immutable -e APP_VERSION=${var.APP_VERSION}"
    ]
  }
}

resource "aws_ami_from_instance" "ami" {
  depends_on         = [null_resource.ansible-apply]
  name               = "${var.COMPONENT}-${var.APP_VERSION}"
  source_instance_id = aws_instance.ami.id
}