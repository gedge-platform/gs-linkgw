# gs-linkgw
This repository includes open sources of gs-link for connection between other clusters and cooperation works in gedge-platform

The Poc for migration 
---------------------------------------------------------------------------------------------------------------------------------------
This repository include test code for migration from opensource 
https://github.com/qzysw123456/kubernetes-pod-migration


The structure of migration module - PoC 
---------------------------------------------------------------------------------------------------------------------------------------
This figure shows the structure of migration module which is consists of migration agent and migration manger(cmd related with kubectl)

![Structure_migration_small](https://user-images.githubusercontent.com/32071802/145149528-0ea8d741-46cd-49ed-8db3-a83789e0a243.jpg)

Test for kubectl plugin
---------------------------------------------------------------------------------------------------------------------------------------
kubectl migrate [PodName] [DestHost]

![kubeplugin](https://user-images.githubusercontent.com/32071802/145150699-49014919-9221-449b-a434-385920b215cc.jpg)
