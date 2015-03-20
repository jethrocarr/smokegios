# Introduction
Smokegios is a small Perl5 application that reads a Nagios configuration file and generates Smokeping configuration for all the hosts defined.

Hosts are automatically generated in structures based on the hostgroup definitions in Nagios - note that at least one hostgroup definition is must for this program to work and any hosts not in a host group will be ignored.

The application should be called regularly (eg once an hour), it will check if Nagios's configuration has changed and if so, will generate new Smokeping config and reload the daemon.



# Key Features

This is still a basic application and there are numerous features that would be desirable to add. The current feature list is:

* Automatically generate new Smokeping configuration based on host definitions in Nagios.
* Can easily hook into a hybrid manual/auto generated Smokeping configuration, so that administrators can still do more complex configurations.
* Supports Smokeping 2.4+
* Written in Perl5 
* GNU GPLv3


More features are planned for the future, such as the ability to generate Smokeping configuration for HTTP performance test services.


# Getting Started

To get started with Smokegios, start by reading the https://github.com/jethrocarr/smokegios/wiki/Installation wiki page.

I have packaged for RHEL/CentOS 5 & 6 and there is a .src.rpm you can build for other platforms as desired.


# Support & Contributions

Best way to get support is to open an issue in the tracker, since then others can find any issues they also experience and you can track the fixes against any issues.



# Beer

Beer is welcome. So are patches.

