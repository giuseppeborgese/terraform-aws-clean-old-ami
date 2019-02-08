This Lamdba function deletes all golden images older than number of days specified in the variable, default is 60. 

# Schema
![schema](https://raw.githubusercontent.com/giuseppeborgese/terraform-aws-clean-old-ami/master/Clean_old_ami.png)

# How it works

* Select all the images with the TAG_Filter variable
* For each image check if it is older than the days in the DELETE_OLDER_THAN_DAYS variable
* If the image doesn't have the tag in the EXCLUSION_TAG variable or the value isn't True it will be deregister

![schema](https://raw.githubusercontent.com/giuseppeborgese/terraform-aws-clean-old-ami/master/lambda-variables.tf.png)

You can change this lambda environment variables passing different values at terraform module level.

# Usage Example
``` hcl
module "clean_old_ami" {
  source  = "giuseppeborgese/clean-old-ami/aws"
  prefix  = "MyAccountName"
}
```

# When it runs
Every first day of each month. 
![whenitruns](https://raw.githubusercontent.com/giuseppeborgese/terraform-aws-clean-old-ami/master/cronexpression.png)
