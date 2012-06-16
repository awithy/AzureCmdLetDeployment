Azure CmdLet Deployment Sample
==============================

This project provides an example of using the Azure CmdLets to deploy a WebRole.  


To use
------

+ Copy your Azure Certificate to 'lib\AzureCertificate\AzureMgmt.pfx'

+ Modify the default.ps1 psake file with the lines marked with #<--Modify.  This includes your subscription Id, storage account info, and certificate password.


To deploy
---------

> .\build -t Deploy


License
-------

This is provided without any license whatsoever.  You are free to use and distribute.