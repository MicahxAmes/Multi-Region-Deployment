variable "amis" {
  type = map(string)
  default = {
    "us-east-1" = "ami-0464d49b8794eba32" 
    "us-west-2" = "ami-06883a492f195064e" 
  }
}