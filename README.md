Factorio provisioning tool
==========================

I'm creating this repo to help my brother and me quickly spin up/down an 
amazon ec2 server for us to play factorio on. 

Setup instructions
==================

This has been tested on an Ubuntu box. You will need the `terraform` tool 
installed on the system. Some instructions can be found here,
https://askubuntu.com/a/983352

(You might need to close and re-open your shell window to get `terraform` to
get detected)

* Clone this repo to your filesystem. 

* Copy over the `terraform.tfvars` backup file and fill in the AWS secrets.

```
$ cp terraform.tfvars.backup terraform.tfvars
$ vim terraform.tfvars
```

* Copy over the `server-settings.json` backup file and edit as needed.

```
$ cp files/settings/server-settings.json.backup files/settings/server-settings.json
$ vim files/settings/server-settings.json
```

* Overwrite the `server-save.zip` file inside `files/saves/` with your game save.

That should be enough. 


First time instructions
=======================

Make sure that terraform works by running,

```
$ terraform version
```

Setup the project by running,

```
$ terraform init
```

The above command will tell terraform to scan the repo and download needed
provisioning files (they get downloaded to a local `.terraform` folder)


Running instructions
====================

To START the server run,

```
$ terraform apply -auto-approve
```

To STOP the server run,

```
$ terraform destroy -auto-approve
```

The destroy command will download the saves from the server to the local 
filesystem (inside `files/saves/`). Thus when run the START command next time,
that save will get uploaded. 

The factorio service will register with the official factorio servers and we 
should see our new server listed under the multiplayer section. 

Expect the server to take about 2 - 4 minutes to come online/offline. 


In-game instructions
====================

When you are done playing the game, press the tilde key `~` to open the 
console and enter,

```
/server-save
```

It will instruct the server to create a new save file immediately. 


SSH notes
=========

The following command was used to create the SSH key-pairs;

```
$ ssh-keygen -t rsa -N "" -C "factorio_key" -f ./factorio_key
```

to login to the machine;

```
$ chmod 400 factorio_key.pub
$ ssh-add factorio_key
$ ssh ubuntu@PUBLIC_IP
```

(fill in the public-ip from output)
