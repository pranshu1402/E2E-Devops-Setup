variable "aws_region" { 
    type = string
    default = "us-west-2"
}

variable "aws_profile" { 
    type = string
    default = "herovired" 
}

variable "tfstate_bucket" { 
    type = string 
}

variable "tfstate_lock_table" { 
    type = string 
}

variable "tags" { 
    type = map(string)
    default = {} 
}
