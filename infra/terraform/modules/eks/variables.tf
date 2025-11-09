variable "cluster_name" { 
    type = string
}

variable "cluster_version" { 
    type = string
    default = "1.30"
}

variable "vpc_id" { 
    type = string 
}

variable "cluster_iam_role_name" {
    type = string
    default = "AmazonEKSAutoClusterRole"
}

variable "node_iam_role_name" {
    type = string
    default = ""
}

variable "private_subnet_ids" { 
    type = list(string) 
}

variable "environment" { 
    type = string
    default = "dev" 
}

variable "tags" { 
    type = map(string) 
    default = {} 
}
