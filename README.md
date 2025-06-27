# Ops Template for Ubuntu

## Softwares

- GIS
- nodejs
- Nginx
- sdkman
- docker

## Server Configuration

1. SSH Configuration

> vi /etc/ssh/sshd_config

```shell
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
```

## 

| Directory      | Description                                                                                |
| -------------- | ------------------------------------------------------------------------------------------ |
| assets         | Static resource files, installation packages, etc.                                         |
| bin            | Startup scripts                                                                            |
| infrastructure | Infrastructure configuration related                                                       |
| scripts        | Server operation related scripts                                                           |
| nginx-config   | Nginx related configuration                                                                |
| temp           | Temporary directory for pulling third-party project source code (GitHub/Gitee) for testing |
| projects       | Self-developed project source code, stored on coding platform                              |
| dist           | Compiled and packaged artifact storage path                                                |
