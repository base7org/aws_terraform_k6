# Set up k6 operator.

resource "null_resource" "k6_operator" {
  provisioner "local-exec" {
    command = "./scripts/install_k6_operator.sh"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "./scripts/uninstall_k6_operator.sh"
  }
  
  depends_on = [null_resource.update_kubeconfig]
}

# InfluxDB Helm ref: https://github.com/influxdata/helm-charts

resource "helm_release" "k6_influxdb" {
  name = "${var.site_name}-influx-db"
  namespace = "k6_influxdbinfluxdb"
  repository = "https://helm.influxdata.com/"
  chart = "${var.site_name}-influxdb"
  depends_on = [kubernetes_secret.k6_influxdb_info, null_resource.update_kubeconfig]
  values = ["${file("config-files/influxdb_values.yaml")}"]
}

# InfluxDB Secrets

data "aws_secretsmanager_secret_version" "k6_influxdb_secret_read" {
  secret_id = "InfluxCreds"
}

resource "kubernetes_secret" "k6_influxdb_info" {
  metadata {
    name = "k6-influxdb-info"
    namespace = "k6_influxdb"
  }
  data = {
    "INFLUXDB_WRITE_USER_PASSWORD" = jsondecode(data.aws_secretsmanager_secret_version.k6_influxdb_secret_read.secret_string)["k6_write_user_password"]
    "INFLUXDB_READ_USER_PASSWORD" = jsondecode(data.aws_secretsmanager_secret_version.k6_influxdb_secret_read.secret_string)["k6_read_user_password"]
    "INFLUXDB_USER_PASSWORD" = jsondecode(data.aws_secretsmanager_secret_version.k6_influxdb_secret_read.secret_string)["k6_user_password"]
    "INFLUXDB_ADMIN_PASSWORD" = jsondecode(data.aws_secretsmanager_secret_version.k6_influxdb_secret_read.secret_string)["k6_admin_password"]
  }
}

# EFS Persistances

resource "aws_efs_file_system" "k6_influxdb_efs" {
  depends_on = [null_resource.update_kubeconfig]
}

resource "aws_efs_mount_target" "k6_influxdb_efs_mount_target" {
  file_system_id  = aws_efs_file_system.k6_influxdb_efs.id
  count           = length(aws_subnet.site_private_subnet) == 2 ? 2 : 0
  subnet_id       = element(aws_subnet.site_private_subnet.*.id, count.index)
  security_groups = [ module.k6_efs_security_group.security_group_id ]
  depends_on      = [aws_vpc.site_vpc]
}

resource "kubernetes_storage_class" "k6_influxdb_storage_class" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
}

resource "kubernetes_persistent_volume" "k6_influxdb_persistence_volume" {
  metadata {
    name = "influxdb-persistence-volume"
  }

  spec {
    capacity = {
      "storage" = "8Gi"
    }
    volume_mode = "Filesystem"
    access_modes = [ "ReadWriteOnce" ]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = kubernetes_storage_class.k6_influxdb_storage_class.metadata[0].name
    persistent_volume_source {
      csi {
        driver = "efs.csi.aws.com"
        volume_handle = aws_efs_file_system.k6_influxdb_efs.id
      }
    }
  }
}

resource "kubernetes_storage_class" "k6_grafana_storage_class" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
}

resource "kubernetes_persistent_volume" "grafana_persistence_volume" {
  metadata {
    name = "grafana-persistence-volume"
  }
  spec {
    capacity = {
      "storage" = "5Gi"
    }
    volume_mode = "Filesystem"
    access_modes = [ "ReadWriteOnce" ]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = kubernetes_storage_class.k6_grafana_storage_class.metadata[0].name
    persistent_volume_source {
      csi {
        driver = "efs.csi.aws.com"
        volume_handle = aws_efs_file_system.k6_influxdb_efs.id
      }
    }
  }
}

# EFC Security Group

module "k6_efs_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name = "k6_efs_sg"
  description = "The security group for EFS"
  vpc_id = aws_vpc.site_vpc.id
  
  ingress_with_cidr_blocks = [
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      type        = "NFS"
      cidr_blocks = aws_vpc.site_vpc.cidr_block
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0 
      to_port     = 0 
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

# Grafana Ref: https://github.com/grafana/helm-charts

resource "helm_release" "grafana" {
  name = "${var.site_name}-grafana"
  namespace = "k6_grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart = "${var.site_name}-grafana"
  values = ["${file("config-files/grafana_values.yaml")}"]
  depends_on = [kubernetes_secret.k6_grafana_info]
}

# Grafana Secrets

data "aws_secretsmanager_secret_version" "k6_grafana_secret_read" {
  secret_id = "GrafanaCreds"
}

resource "kubernetes_secret" "k6_grafana_info" {
  metadata {
    name = "k6-grafana-info"
    namespace = "k6_grafana"
  }

  data = {
    "k6-admin-user" = "k6_grafana_admin" 
    "k6-admin-password" = jsondecode(data.aws_secretsmanager_secret_version.k6_grafana_secret_read.secret_string)["k6_admin_password"]
  }
}