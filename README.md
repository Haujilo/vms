# 虚拟环境快速搭建

## 用途

此项目用于快速生成用于测试环境，自动化建立集群。想法上是想把所有日常学习用到的工具服务的自动化脚本都能整合保留下来集中管理，便于查阅和验证。


机器的主机名命名格式为「分类」-「角色」-「序列号」。

## 机器架构

目前同类型的机器可以分组，可以分组启动，所有机器同属于一个网段中。

## 安装

### macOS

依赖：

- [virtualbox](https://www.virtualbox.org/)
- [vagrant](https://www.vagrantup.com/)
  - [vagrant-vbguest](https://github.com/dotless-de/vagrant-vbguest)
  - [vagrant-group](https://github.com/vagrant-group/vagrant-group)

```shell
# 安装示例

brew cask install virtualbox
brew cask install vagrant

# 安装vagrant使用的插件
vagrant plugin install vagrant-vbguest
vagrant plugin install vagrant-group
```

```
# 第一次使用需要先制作和导出base镜像，并导入成一个本地box
./build_base_box.sh
```

### Windows

依赖：

- [Hyper-V](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/)
- [vagrant](https://www.vagrantup.com/)
  - [vagrant-group](https://github.com/vagrant-group/vagrant-group)

按官方教程开启Hyper-V和安装好vagrant，Hyper-V创建一个名为Vagrant的外部虚拟交换机。

```powershell

# 安装插件
vagrant plugin install vagrant-group

# 第一次使用需要先制作和导出base镜像，并导入成一个本地box
Powershell -File build_base_box.ps1
```

## 使用

```shell
# 查看分类机器
vagrant group hosts 「分类」
# 查看分类角色机器
vagrant group hosts 「分类」-「角色」

# 例：启动kubernetes集群
vagrant group up kubernetes
# 例：只启动kubernetes集群的master节点
vagrant group up kubernetes-master
```

```shell
# 删除机器并清理创建的文件
vagrant destroy -f
rm -rf .vagrant
```
