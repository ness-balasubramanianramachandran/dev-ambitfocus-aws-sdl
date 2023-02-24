locals {
  infrastructure_instance_types = {
    "small" = {
      "application_server" = {
        "instance_type"   = "m6i.4xlarge", // TODO: this was increased for 3.5 mil position test in our "small" environment; need to determine what is actually appropriate
        "instance_count"  = 1,
        "bsmi_components" = ["bsmi_dh"]
      },
      "selfmanaged_db" = {
        "instance_type"     = "m6i.4xlarge",
        "allocated_storage" = 512
      },
      "fileshare" = {
        "storage_capacity"    = 50,
        "throughput_capacity" = 128
      },
      "eks" = {
        ng = {
          cc = {
            "instance_type"   = "t3.xlarge",
            "desired_size"    = 2,
            "max_size"        = 8,
            "min_size"        = 2,
            "ebs_volume_type" = "gp3",
            "ebs_volume_size" = 50
          },
          ce = {
            "instance_type"   = "m6i.4xlarge",
            "desired_size"    = 0,
            "max_size"        = 50,
            "min_size"        = 0,
            "ebs_volume_type" = "gp3",
            "ebs_volume_size" = 50
          }
        }
      }
    },
    "medium" = {
      "application_server" = {
        "instance_type"   = "t3.xlarge",
        "instance_count"  = 2,
        "bsmi_components" = ["bsmi", "dh"]
      },
      "selfmanaged_db" = {
        "instance_type"     = "m6i.4xlarge",
        "allocated_storage" = 512
      },
      "fileshare" = {
        "storage_capacity"    = 50,
        "throughput_capacity" = 128
      },
      "eks" = {
        ng = {
          cc = {
            "instance_type"   = "t3.xlarge",
            "desired_size"    = 2,
            "max_size"        = 8,
            "min_size"        = 2,
            "ebs_volume_type" = "gp3",
            "ebs_volume_size" = 50
          },
          ce = {
            "instance_type"   = "m6i.4xlarge",
            "desired_size"    = 0,
            "max_size"        = 50,
            "min_size"        = 0,
            "ebs_volume_type" = "gp3",
            "ebs_volume_size" = 50
          }
        }
      }
    },
    "large" = {
      "application_server" = {
        "instance_type"   = "t3.xlarge",
        "instance_count"  = 3,
        "bsmi_components" = ["bsmi", "dh", "sat"]
      },
      "selfmanaged_db" = {
        "instance_type"     = "m6i.4xlarge",
        "allocated_storage" = 512
      },
      "fileshare" = {
        "storage_capacity"    = 50,
        "throughput_capacity" = 128
      },
      "eks" = {
        ng = {
          cc = {
            "instance_type"   = "t3.xlarge",
            "desired_size"    = 2,
            "max_size"        = 8,
            "min_size"        = 2,
            "ebs_volume_type" = "gp3",
            "ebs_volume_size" = 50
          },
          ce = {
            "instance_type"   = "m6i.4xlarge",
            "desired_size"    = 0,
            "max_size"        = 50,
            "min_size"        = 0,
            "ebs_volume_type" = "gp3",
            "ebs_volume_size" = 50
          }
        }
      }
    }
  }
}
